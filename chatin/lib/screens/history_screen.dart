import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_helper.dart';
import '../services/chat_service.dart';
import '../widgets/screen_background.dart';
import '../widgets/history_chip.dart';
import 'chat_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      // 1. Tampilkan data lokal secepatnya
      var sessions = await DatabaseHelper().getSessions(userId);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
      
      // 2. Sinkronkan dari Cloud, lalu refresh jika ada perubahan
      await ChatService().syncFromCloud(userId);
      sessions = await DatabaseHelper().getSessions(userId);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _sessions = [];
          _isLoading = false;
        });
      }
    }
  }

  String _truncateTitle(String? title) {
    if (title == null || title.trim().isEmpty) return 'New Chat';
    List<String> words = title.trim().split(RegExp(r'\s+'));
    if (words.length > 4) {
      return '${words.take(4).join(' ')}...';
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'All Chat History',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // History List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFD500)),
                  )
                : _sessions.isEmpty
                    ? const Center(
                        child: Text(
                          'No chat history yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 12.0,
                          children: _sessions.map((session) {
                            return HistoryChip(
                              label: _truncateTitle(session['title']),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      sessionId: session['id'],
                                      conversationTitle: session['title'],
                                      initialAgentId: session['agent_id'],
                                    ),
                                  ),
                                );
                                _loadSessions(); // Reload when returning
                              },
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
