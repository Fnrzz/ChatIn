import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';
import 'history_screen.dart';
import 'agents_screen.dart';
import '../widgets/screen_background.dart';
import '../widgets/history_chip.dart';
import '../widgets/agent_card.dart';
import '../widgets/section_header.dart';
import '../services/database_helper.dart';
import '../services/chat_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _agents = [];
  bool _isLoadingAgents = true;
  double _logoTurns = 0.0;
  final ChatService _chatService = ChatService();

  // Daftar warna preset untuk AgentCard
  final List<Color> _agentColors = const [
    Color(0xFFF1AED2), // Pink
    Color(0xFF4ADE80), // Green
    Color(0xFF60A5FA), // Blue
    Color(0xFFFBBF24), // Yellow
    Color(0xFFA78BFA), // Purple
  ];

  late final StreamSubscription<AuthState> _authStateSubscription;
  RealtimeChannel? _agentsChannel;

  @override
  void initState() {
    super.initState();
    _loadAgents();
    _subscribeToAgents();

    // Reload sessions when user auth state changes (also triggers initially)
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          _loadSessions();
        });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    if (_agentsChannel != null) {
      Supabase.instance.client.removeChannel(_agentsChannel!);
    }
    super.dispose();
  }

  /// Subscribe to realtime changes on the 'agents' table
  void _subscribeToAgents() {
    _agentsChannel = Supabase.instance.client
        .channel('public:agents')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'agents',
          callback: (payload) async {
            await Future.delayed(const Duration(milliseconds: 300));
            _loadAgents();
          },
        )
        .subscribe();
  }

  Future<void> _loadSessions() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      // 1. Tampilkan data lokal secepatnya
      var sessions = await DatabaseHelper().getSessions(userId);
      if (mounted) {
        setState(() {
          _sessions = sessions;
        });
      }
      
      // 2. Sinkronkan dari Cloud, lalu refresh jika ada perubahan
      await _chatService.syncFromCloud(userId);
      sessions = await DatabaseHelper().getSessions(userId);
      if (mounted) {
        setState(() {
          _sessions = sessions;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _sessions = [];
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

  Future<void> _loadAgents() async {
    try {
      final agents = await _chatService.getAgents();
      if (mounted) {
        setState(() {
          _agents = agents;
          _isLoadingAgents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAgents = false;
        });
      }
      print('Failed to load agents: $e');
    }
  }

  // Generate initial message based on agent name
  String _generateInitialMessage(String agentName) {
    return 'Halo $agentName, saya butuh bantuan Anda.';
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Animasi BottomSheet bawaan Flutter sudah sangat smooth,
      // kita gunakan custom transition jika diperlukan, tapi defaultnya sudah bagus.
      builder: (BuildContext context) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              // Drag Handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pengaturan',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1E1E),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Akun / Profil',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menu Profil belum tersedia')),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.color_lens_outlined,
                title: 'Tampilan (Theme)',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menu Tema belum tersedia')),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      title: const Text('Tentang ChatIn'),
                      content: const Text('ChatIn v1.0.0\nDibangun menggunakan Flutter dan Supabase.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1E1E1E), size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E1E1E),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkGrey = Color(0xFF1E1E1E);
    const primaryYellow = Color(0xFFFFD500);

    return ScreenBackground(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (Logo & Logout)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _logoTurns += 1.0; // Berputar 1x putaran penuh (360 derajat)
                      });
                      _showSettingsBottomSheet(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedRotation(
                        turns: _logoTurns,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack, // Memberikan efek memantul di akhir putaran
                        child: const Icon(
                          Icons.filter_vintage,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded),
                    color: Colors.red,
                    iconSize: 28,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            title: const Text(
                              'Logout',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1E1E),
                                fontSize: 24,
                                letterSpacing: -0.5,
                              ),
                            ),
                            content: const Text(
                              'Are you sure you want to log out?',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            actionsPadding: const EdgeInsets.only(
                              right: 20,
                              bottom: 20,
                              left: 20,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<AuthProvider>().logout();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFD500),
                                  foregroundColor: const Color(0xFF1E1E1E),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Main Title
              Text(
                'Ready to start a session?',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 32),

              // New Chat Button
              InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                  _loadSessions();
                },
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    color: primaryYellow,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 24.0),
                          child: Text(
                            'New Chat',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: darkGrey,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Chat History Header
              SectionHeader(
                title: 'Chat history',
                onSeeAll: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                  _loadSessions();
                },
              ),
              const SizedBox(height: 16),

              // Chat History Chips
              if (_sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'No chat history yet.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: _sessions
                            .asMap()
                            .entries
                            .where((e) => e.key % 2 == 0)
                            .map((e) {
                              final session = e.value;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: HistoryChip(
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
                                    _loadSessions();
                                  },
                                ),
                              );
                            })
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: _sessions
                            .asMap()
                            .entries
                            .where((e) => e.key % 2 != 0)
                            .map((e) {
                              final session = e.value;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: HistoryChip(
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
                                    _loadSessions();
                                  },
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),

              // Popular Agent Header
              SectionHeader(
                title: 'Popular Agent',
                onSeeAll: () async {
                  final shouldReload = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgentsScreen(),
                    ),
                  );
                  // Reload sessions if the user started a chat from the Agents screen
                  if (shouldReload == true) {
                    _loadSessions();
                  }
                },
              ),
              const SizedBox(height: 16),

              // Popular Agent Cards (Horizontal Scroll)
              if (_isLoadingAgents)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: CircularProgressIndicator(color: primaryYellow),
                  ),
                )
              else if (_agents.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'No agents available.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: _agents.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final agent = entry.value;

                      final name = agent['name'] as String? ?? 'Agent';
                      final desc =
                          agent['description'] as String? ?? 'Assistant';
                      final bgColor = _agentColors[index % _agentColors.length];

                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: AgentCard(
                          title: name,
                          category: desc,
                          backgroundColor: bgColor,
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
                            _loadSessions();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
