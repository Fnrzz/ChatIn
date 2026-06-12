import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import '../utils/encryption_helper.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mengambil data agent
  Future<List<Map<String, dynamic>>> getAgents() async {
    final data = await _supabase
        .from('agents')
        .select('id, name, type, description')
        .eq('status', 'active');
    return List<Map<String, dynamic>>.from(data);
  }

  // Mengambil semua sesi untuk user tertentu dari Supabase
  Future<List<Map<String, dynamic>>> getSessions(String userId) async {
    final data = await _supabase
        .from('chat_sessions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // Mengambil pesan untuk sesi tertentu dari Supabase dan mendekripsinya
  Future<List<Map<String, dynamic>>> getSessionMessages(String sessionId) async {
    final data = await _supabase
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);
        
    final List<Map<String, dynamic>> messages = [];
    for (var msg in data) {
      final decryptedContent = EncryptionHelper.decryptText(msg['content'] ?? '');
      messages.add({
        ...msg,
        'content': decryptedContent,
      });
    }
    return messages;
  }

  // Menghapus sesi
  Future<void> deleteSession(String sessionId) async {
    // Jika Supabase tidak mengatur ON DELETE CASCADE, kita juga bisa menghapus pesan secara eksplisit
    await _supabase.from('chat_messages').delete().eq('session_id', sessionId);
    await _supabase.from('chat_sessions').delete().eq('id', sessionId);
  }

  // Membuat sesi baru di Supabase
  Future<String> createNewSession(String agentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    final sessionId = const Uuid().v4();
    final createdAt = DateTime.now().millisecondsSinceEpoch;

    await _supabase.from('chat_sessions').insert({
      'id': sessionId,
      'agent_id': agentId,
      'title': 'New Chat',
      'user_id': userId,
      'created_at': createdAt,
      'summary': null,
    });

    return sessionId;
  }

  // Mengirim pesan dan menyimpan hanya ke Supabase
  Stream<String> sendMessage(
    String message,
    String sessionId,
    String agentId,
  ) async* {
    final client = http.Client();
    try {
      final userCreatedAt = DateTime.now().millisecondsSinceEpoch;

      // a. Sinkronisasi pesan user ke Supabase (ENKRIPSI)
      await _supabase.from('chat_messages').insert({
        'session_id': sessionId,
        'role': 'user',
        'content': EncryptionHelper.encryptText(message),
        'is_summarized': 0,
        'created_at': userCreatedAt,
      });

      // b. Tarik Data Sesi dan Pesan yang Belum Dirangkum dari Supabase
      final sessionData = await _supabase
          .from('chat_sessions')
          .select('summary')
          .eq('id', sessionId)
          .maybeSingle();
      
      String? oldSummary = sessionData != null ? sessionData['summary'] as String? : null;

      final unsummarizedData = await _supabase
          .from('chat_messages')
          .select()
          .eq('session_id', sessionId)
          .eq('is_summarized', 0)
          .order('created_at', ascending: true);

      List<Map<String, dynamic>> unsummarizedMessages = [];
      for (var msg in unsummarizedData) {
        unsummarizedMessages.add({
          ...msg,
          'content': EncryptionHelper.decryptText(msg['content'] ?? ''),
        });
      }

      final apiUrl = dotenv.env['NEXT_API_URL'];
      if (apiUrl == null) throw Exception('NEXT_API_URL is not set in .env');

      final apiKey = dotenv.env['API_SECRET_KEY'];
      if (apiKey == null) throw Exception('API_SECRET_KEY is not set in .env');

      // c. Logika Auto-Summarize (Setiap 10 Pesan)
      if (unsummarizedMessages.length >= 10) {
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
            // Update summary di Supabase
            await _supabase
                .from('chat_sessions')
                .update({'summary': newSummary})
                .eq('id', sessionId);

            // Tandai pesan-pesan sebagai sudah dirangkum di Supabase
            final messageIds = unsummarizedMessages.map((m) => m['id']).toList();
            if (messageIds.isNotEmpty) {
              await _supabase
                  .from('chat_messages')
                  .update({'is_summarized': 1})
                  .inFilter('id', messageIds);
            }

            // Update state lokal untuk dikirim ke chat utama
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

      // e. Simpan jawaban AI (aiResponse) ke Supabase
      String aiResponse = '';
      try {
        final jsonResponse = jsonDecode(response.body);
        aiResponse =
            jsonResponse['response'] ??
            jsonResponse['message'] ??
            response.body;
      } catch (e) {
        aiResponse = response.body;
      }

      if (aiResponse.isEmpty) throw Exception('Empty response from server');

      final aiCreatedAt = DateTime.now().millisecondsSinceEpoch;

      // Insert AI response to Supabase (ENKRIPSI)
      await _supabase.from('chat_messages').insert({
        'session_id': sessionId,
        'role': 'assistant',
        'content': EncryptionHelper.encryptText(aiResponse),
        'is_summarized': 0,
        'created_at': aiCreatedAt,
      });

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
          // Update di Supabase saja
          await _supabase.from('chat_sessions').update({
            'title': newTitle
          }).eq('id', sessionId);
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
}
