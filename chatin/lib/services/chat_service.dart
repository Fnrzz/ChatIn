import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import '../utils/encryption_helper.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Supabase hanya digunakan untuk mengambil data agent
  Future<List<Map<String, dynamic>>> getAgents() async {
    final data = await _supabase
        .from('agents')
        .select('id, name, type, description')
        .eq('status', 'active');
    return List<Map<String, dynamic>>.from(data);
  }

  // Membuat sesi baru di SQLite dan Supabase
  Future<String> createNewSession(String agentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    final sessionId = const Uuid().v4();
    final createdAt = DateTime.now().millisecondsSinceEpoch;

    // 1. Simpan ke SQLite lokal
    await DatabaseHelper().createSession(
      sessionId,
      agentId,
      'New Chat',
      userId,
    );

    // 2. Sinkronisasi ke Supabase (Latar belakang, tidak perlu await penuh jika ingin cepat, tapi kita await untuk pastikan)
    try {
      await _supabase.from('chat_sessions').insert({
        'id': sessionId,
        'agent_id': agentId,
        'title': 'New Chat',
        'user_id': userId,
        'created_at': createdAt,
        'summary': null,
      });
    } catch (e) {
      print('Failed to sync new session to Supabase: $e');
    }

    return sessionId;
  }

  // Mengirim pesan dan menyimpan ke SQLite & Supabase
  Stream<String> sendMessage(
    String message,
    String sessionId,
    String agentId,
  ) async* {
    final client = http.Client();
    try {
      final userCreatedAt = DateTime.now().millisecondsSinceEpoch;
      // a. Simpan pesan user ke SQLite
      await DatabaseHelper().insertMessage(sessionId, 'user', message);

      // Sinkronisasi pesan user ke Supabase
      try {
        await _supabase.from('chat_messages').insert({
          'session_id': sessionId,
          'role': 'user',
          'content': EncryptionHelper.encryptText(message), // ENKRIPSI
          'is_summarized': 0,
          'created_at': userCreatedAt,
        });
      } catch (e) {
        print('Failed to sync user message to Supabase: $e');
      }

      // b. Tarik Data & Cek Batas (Threshold) untuk Rolling Summary
      String? oldSummary = await DatabaseHelper().getSessionSummary(sessionId);
      List<Map<String, dynamic>> unsummarizedMessages = await DatabaseHelper()
          .getUnsummarizedMessages(sessionId);

      final apiUrl = dotenv.env['NEXT_API_URL'];
      if (apiUrl == null) throw Exception('NEXT_API_URL is not set in .env');

      final apiKey = dotenv.env['API_SECRET_KEY'];
      if (apiKey == null) throw Exception('API_SECRET_KEY is not set in .env');

      // c. Logika Auto-Summarize (Setiap 10 Pesan)
      if (unsummarizedMessages.length >= 10) {
        // Ganti ujung url /chat menjadi /chat/summarize
        final summarizeUrl = apiUrl.replaceAll(
          RegExp(r'/chat$'),
          '/chat/summarize',
        );

        final summarizeBody = jsonEncode({
          'oldSummary': oldSummary ?? '',
          'newMessages': unsummarizedMessages
              .map((m) => {'role': m['role'], 'content': m['content']})
              .toList(),
        });

        final sumResponse = await client.post(
          Uri.parse(summarizeUrl),
          headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
          body: summarizeBody,
        );

        if (sumResponse.statusCode == 200) {
          final sumData = jsonDecode(sumResponse.body);
          final newSummary = sumData['summary'];

          if (newSummary != null && newSummary.toString().isNotEmpty) {
            // Update summary di SQLite
            await DatabaseHelper().updateSessionSummary(sessionId, newSummary);

            // Update summary di Supabase
            try {
              await _supabase
                  .from('chat_sessions')
                  .update({'summary': newSummary})
                  .eq('id', sessionId);
            } catch (e) {
              print('Failed to sync session summary to Supabase: $e');
            }

            // Tandai pesan-pesan sebagai sudah dirangkum di SQLite
            final messageIds = unsummarizedMessages
                .map((m) => m['id'] as int)
                .toList();
            await DatabaseHelper().markMessagesAsSummarized(
              sessionId,
              messageIds,
            );

            // Tandai pesan-pesan sebagai sudah dirangkum di Supabase
            try {
              await _supabase
                  .from('chat_messages')
                  .update({'is_summarized': 1})
                  .eq('session_id', sessionId)
                  .eq('is_summarized', 0);
            } catch (e) {
              print('Failed to sync is_summarized to Supabase: $e');
            }

            // Update state lokal
            oldSummary = newSummary;
            unsummarizedMessages = []; // Kosongkan karena semua sudah dirangkum
          }
        }
      }

      // d. Lakukan HTTP POST ke Next.js (Chat Utama)
      final history = unsummarizedMessages
          .map((m) => {'role': m['role'], 'content': m['content']})
          .toList();

      final requestBody = jsonEncode({
        'message': message,
        'agentId': agentId,
        'history': history,
        'sessionId': sessionId,
        'summary': oldSummary,
      });

      var response = await client.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
        body: requestBody,
      );

      // Jika server redirect (307/308), ikuti redirect secara manual
      if (response.statusCode == 307 || response.statusCode == 308) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final resolvedUrl = Uri.parse(apiUrl).resolve(redirectUrl);
          response = await client.post(
            resolvedUrl,
            headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
            body: requestBody,
          );
        }
      }

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      // e. Simpan jawaban AI (aiResponse) ke SQLite
      String aiResponse = '';
      try {
        final jsonResponse = jsonDecode(response.body);
        aiResponse =
            jsonResponse['response'] ??
            jsonResponse['message'] ??
            response.body;
      } catch (e) {
        // Fallback jika respons berupa teks biasa
        aiResponse = response.body;
      }

      if (aiResponse.isEmpty) throw Exception('Empty response from server');

      final aiCreatedAt = DateTime.now().millisecondsSinceEpoch;

      // Insert AI response to SQLite (default is_summarized = 0)
      await DatabaseHelper().insertMessage(sessionId, 'assistant', aiResponse);

      // Insert AI response to Supabase
      try {
        await _supabase.from('chat_messages').insert({
          'session_id': sessionId,
          'role': 'assistant',
          'content': EncryptionHelper.encryptText(aiResponse), // ENKRIPSI
          'is_summarized': 0,
          'created_at': aiCreatedAt,
        });
      } catch (e) {
        print('Failed to sync AI message to Supabase: $e');
      }

      // Simulasi streaming ke UI
      final words = aiResponse.split(' ');
      for (int i = 0; i < words.length; i++) {
        await Future.delayed(const Duration(milliseconds: 30));
        yield '${words[i]}${i < words.length - 1 ? ' ' : ''}';
      }
    } catch (e) {
      print('ChatService Error: $e');
      yield "Sorry, an error occurred: $e";
    } finally {
      client.close();
    }
  }

  // Membuat judul sesi cerdas menggunakan AI
  Future<String?> generateSessionTitle(String sessionId, String userMessage, String aiMessage) async {
    final apiUrl = dotenv.env['NEXT_API_URL'];
    final apiKey = dotenv.env['API_SECRET_KEY'];
    
    if (apiUrl == null || apiKey == null) return null;

    final titleUrl = apiUrl.replaceAll(RegExp(r'/chat$'), '/chat/generate-title');
    final client = http.Client();

    try {
      final requestBody = jsonEncode({
        'userMessage': userMessage,
        'aiMessage': aiMessage,
      });

      final response = await client.post(
        Uri.parse(titleUrl),
        headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newTitle = data['title'] as String?;

        if (newTitle != null && newTitle.isNotEmpty) {
          // Update di SQLite
          await DatabaseHelper().updateSessionTitle(sessionId, newTitle);
          // Update di Supabase
          try {
            await _supabase.from('chat_sessions').update({
              'title': newTitle
            }).eq('id', sessionId);
          } catch (e) {
            print('Failed to sync generated title to Supabase: $e');
          }
          return newTitle;
        }
      }
    } catch (e) {
      print('Failed to generate session title: $e');
    } finally {
      client.close();
    }
    return null;
  }

  // Tarik data dari Supabase dan simpan ke SQLite lokal
  Future<void> syncFromCloud(String userId) async {
    try {
      // 1. Ambil semua sesi dari Supabase
      final sessions = await _supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', userId);

      for (var session in sessions) {
        // Coba insert/replace ke SQLite
        await DatabaseHelper().createSession(
          session['id'],
          session['agent_id'],
          session['title'],
          session['user_id'],
        );

        // Update waktu dan summary agar sesuai dengan cloud
        if (session['summary'] != null) {
          await DatabaseHelper().updateSessionSummary(
            session['id'],
            session['summary'],
          );
        }
      }

      // 2. Ambil semua pesan dari Supabase
      // Untuk menghemat bandwidth, kita idealnya hanya mengambil pesan yang belum ada di SQLite
      // Tapi untuk kemudahan sinkronisasi dasar, kita ambil pesan untuk sesi yang kita miliki
      if (sessions.isNotEmpty) {
        final sessionIds = sessions.map((s) => s['id']).toList();

        // Ambil dalam batch jika sangat banyak, atau ambil semua
        final messages = await _supabase
            .from('chat_messages')
            .select()
            .inFilter('session_id', sessionIds)
            .order('created_at', ascending: true);

        final db = await DatabaseHelper().database;

        // Kita perlu membersihkan tabel lokal dan menggantinya dengan cloud?
        // Tidak, jika kita online kita bisa jadikan Cloud sebagai source of truth
        // Karena ada AUTOINCREMENT di SQLite, replace bisa merusak ID, tapi kita tidak rely pada ID integer SQLite untuk relasi kecuali is_summarized
        // Jadi kita bisa menggunakan transaction untuk insert pesan yang belum ada

        // Pendekatan paling aman: jika ada pesan di cloud, pastikan masuk SQLite.
        // Agar tidak duplikat, kita bisa bersihkan chat_messages dan isi ulang (bisa lambat)
        // ATAU kita bisa check count

        for (var msg in messages) {
          final decryptedContent = EncryptionHelper.decryptText(msg['content'] ?? ''); // DEKRIPSI
          
          // Cari apakah pesan sudah ada berdasarkan session_id, role, content, dan created_at
          final existing = await db.query(
            'chat_messages',
            where:
                'session_id = ? AND role = ? AND content = ? AND created_at = ?',
            whereArgs: [
              msg['session_id'],
              msg['role'],
              decryptedContent,
              msg['created_at'],
            ],
          );

          if (existing.isEmpty) {
            await db.insert('chat_messages', {
              'session_id': msg['session_id'],
              'role': msg['role'],
              'content': decryptedContent,
              'is_summarized': msg['is_summarized'] ?? 0,
              'created_at': msg['created_at'],
            });
          }
        }
      }
    } catch (e) {
      print('Failed to sync from cloud: $e');
    }
  }
}
