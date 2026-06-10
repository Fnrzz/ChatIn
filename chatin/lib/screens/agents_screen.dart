import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../widgets/screen_background.dart';
import '../widgets/agent_card.dart';
import 'chat_screen.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  final ChatService _chatService = ChatService();
  List<Map<String, dynamic>> _agents = [];
  bool _isLoading = true;

  final List<Color> _agentColors = const [
    Color(0xFFF1AED2), // Pink
    Color(0xFF4ADE80), // Green
    Color(0xFF60A5FA), // Blue
    Color(0xFFFBBF24), // Yellow
    Color(0xFFA78BFA), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    try {
      final agents = await _chatService.getAgents();
      if (mounted) {
        setState(() {
          _agents = agents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Failed to load agents: $e');
    }
  }

  String _generateInitialMessage(String agentName) {
    if (agentName.toLowerCase().contains('psikolog')) {
      return 'Halo, saya ingin berkonsultasi tentang kesehatan mental dan perasaan saya.';
    } else if (agentName.toLowerCase().contains('ui/ux')) {
      return 'Halo, tolong bantu saya mereview design system dan alur pengguna aplikasi saya.';
    }
    return 'Halo $agentName, saya butuh bantuan Anda.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  onTap: () => Navigator.pop(context, true), // Return true to trigger session reload
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : const Color(0xFF1E1E1E),
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
                Text(
                  'All Agents',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Agents Grid
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFD500)),
                  )
                : _agents.isEmpty
                    ? const Center(
                        child: Text(
                          'No agents available.',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        itemCount: _agents.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 24),
                        itemBuilder: (context, index) {
                          final agent = _agents[index];
                          final name = agent['name'] as String? ?? 'Agent';
                          final desc = agent['description'] as String? ?? 'Assistant';
                          final baseColor = _agentColors[index % _agentColors.length];
                          final bgColor = isDark ? Color.lerp(baseColor, Colors.black, 0.4)! : baseColor;

                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    initialAgent: name,
                                    initialMessage: _generateInitialMessage(name),
                                    conversationTitle: 'Chat with\n$name',
                                  ),
                                ),
                              );
                            },
                            child: Center(
                              child: AgentCard(
                                title: name,
                                category: desc,
                                backgroundColor: bgColor,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
