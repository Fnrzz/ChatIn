import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Supabase hanya digunakan untuk mengambil data agent
  Future<List<Map<String, dynamic>>> getAgents() async {
    final data = await _supabase
        .from('agents')
        .select('id, name, type, description');
    return List<Map<String, dynamic>>.from(data);
  }

  // Membuat sesi baru di SQLite
  Future<String> createNewSession(String agentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User is not logged in');
    }

    final sessionId = const Uuid().v4();
    await DatabaseHelper().createSession(sessionId, agentId, 'New Chat', userId);
    return sessionId;
  }

  // Mengirim pesan dan menyimpan ke SQLite
  Stream<String> sendMessage(String message, String sessionId, String agentId) async* {
    final client = http.Client();
    try {
      // a. Simpan pesan user ke SQLite
      await DatabaseHelper().insertMessage(sessionId, 'user', message);

      // b. Ambil 10 riwayat pesan terakhir dari SQLite untuk konteks Next.js
      final historyData = await DatabaseHelper().getSessionMessages(sessionId);
      final recentHistory = historyData.length > 10
          ? historyData.sublist(historyData.length - 10)
          : historyData;

      final history = recentHistory.map((m) => {
        'role': m['role'],
        'content': m['content']
      }).toList();

      // c. Lakukan HTTP POST ke Next.js
      final apiUrl = dotenv.env['NEXT_API_URL'];
      if (apiUrl == null) throw Exception('NEXT_API_URL is not set in .env');

      final apiKey = dotenv.env['API_SECRET_KEY'];
      if (apiKey == null) throw Exception('API_SECRET_KEY is not set in .env');

      final requestBody = jsonEncode({
        'message': message,
        'agentId': agentId,
        'history': history,
      });

      var response = await client.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
        body: requestBody,
      );

      // Jika server redirect (307/308), ikuti redirect secara manual
      if (response.statusCode == 307 || response.statusCode == 308) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          final resolvedUrl = Uri.parse(apiUrl).resolve(redirectUrl);
          response = await client.post(
            resolvedUrl,
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
            },
            body: requestBody,
          );
        }
      }

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      // d. Simpan jawaban AI (aiResponse) ke SQLite
      String aiResponse = '';
      try {
        final jsonResponse = jsonDecode(response.body);
        aiResponse = jsonResponse['response'] ?? jsonResponse['message'] ?? response.body;
      } catch (e) {
        // Fallback jika respons berupa teks biasa
        aiResponse = response.body;
      }

      if (aiResponse.isEmpty) throw Exception('Empty response from server');

      await DatabaseHelper().insertMessage(sessionId, 'assistant', aiResponse);

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
}
