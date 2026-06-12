import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'chat_screen.dart';
import 'history_screen.dart';
import 'agents_screen.dart';
import '../widgets/screen_background.dart';
import '../widgets/history_chip.dart';
import '../widgets/agent_card.dart';
import '../widgets/section_header.dart';
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
      final sessions = await _chatService.getSessions(userId);
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

  String _generateInitialMessage(String agentName) {
    return 'Halo $agentName, saya butuh bantuan Anda.';
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final activeColor = const Color(0xFFFFD500);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentMode = themeProvider.themeMode;
            
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 48,
                      color: activeColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pilih Tema',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sesuaikan tampilan aplikasi dengan gaya Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildThemeOption(
                      title: 'Sistem (Default)',
                      icon: Icons.settings_system_daydream_outlined,
                      mode: ThemeMode.system,
                      currentMode: currentMode,
                      textColor: textColor,
                      activeColor: activeColor,
                      onTap: (mode) {
                        themeProvider.setThemeMode(mode);
                        Navigator.pop(context);
                      },
                    ),
                    _buildThemeOption(
                      title: 'Terang (Light)',
                      icon: Icons.light_mode_outlined,
                      mode: ThemeMode.light,
                      currentMode: currentMode,
                      textColor: textColor,
                      activeColor: activeColor,
                      onTap: (mode) {
                        themeProvider.setThemeMode(mode);
                        Navigator.pop(context);
                      },
                    ),
                    _buildThemeOption(
                      title: 'Gelap (Dark)',
                      icon: Icons.dark_mode_outlined,
                      mode: ThemeMode.dark,
                      currentMode: currentMode,
                      textColor: textColor,
                      activeColor: activeColor,
                      onTap: (mode) {
                        themeProvider.setThemeMode(mode);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required Color textColor,
    required Color activeColor,
    required Function(ThemeMode) onTap,
  }) {
    final isSelected = mode == currentMode;
    return GestureDetector(
      onTap: () => onTap(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? activeColor : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? textColor : Colors.grey.shade600,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: activeColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final activeColor = const Color(0xFFFFD500);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final currentLocale = context.locale;
            
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.language_outlined,
                      size: 48,
                      color: activeColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'language'.tr(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildLanguageOption(
                      title: 'english'.tr(),
                      icon: Icons.language,
                      locale: const Locale('en'),
                      currentLocale: currentLocale,
                      textColor: textColor,
                      activeColor: activeColor,
                      onTap: (locale) {
                        context.setLocale(locale);
                        Navigator.pop(context);
                      },
                    ),
                    _buildLanguageOption(
                      title: 'indonesian'.tr(),
                      icon: Icons.language,
                      locale: const Locale('id'),
                      currentLocale: currentLocale,
                      textColor: textColor,
                      activeColor: activeColor,
                      onTap: (locale) {
                        context.setLocale(locale);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Tutup',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required IconData icon,
    required Locale locale,
    required Locale currentLocale,
    required Color textColor,
    required Color activeColor,
    required Function(Locale) onTap,
  }) {
    final isSelected = locale == currentLocale;
    return GestureDetector(
      onTap: () => onTap(locale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? activeColor : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? textColor : Colors.grey.shade600,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: activeColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Material(
          color: bgColor,
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
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'settings'.tr(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingsTile(
                context,
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
                context,
                icon: Icons.color_lens_outlined,
                title: 'Tampilan (Theme)',
                onTap: () {
                  Navigator.pop(context);
                  _showThemeDialog(context);
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.language_outlined,
                title: 'language'.tr(),
                onTap: () {
                  Navigator.pop(context);
                  _showLanguageDialog(context);
                },
              ),
              _buildSettingsTile(
                context,
                icon: Icons.info_outline_rounded,
                title: 'Tentang Aplikasi',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: bgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      title: Text('Tentang ChatIn', style: TextStyle(color: textColor)),
                      content: Text('ChatIn v1.0.0\nDibangun menggunakan Flutter dan Supabase.', style: TextStyle(color: textColor)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Tutup', style: TextStyle(color: textColor)),
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

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final iconBgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconBgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: textColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryYellow = const Color(0xFFFFD500);
    final textColor = isDark ? Colors.white : Colors.black;

    return ScreenBackground(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Column(
              key: ValueKey(context.locale.toString()),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header (Logo & Logout)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _logoTurns += 1.0; 
                      });
                      _showSettingsBottomSheet(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : const Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.transparent),
                      ),
                      child: AnimatedRotation(
                        turns: _logoTurns,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutBack, 
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
                            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            title: Text(
                              'logout'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 24,
                                letterSpacing: -0.5,
                              ),
                            ),
                            content: Text(
                              'logout_confirm_desc'.tr(),
                              style: const TextStyle(
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
                                child: Text(
                                  'cancel'.tr(),
                                  style: const TextStyle(
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
                                child: Text(
                                  'logout'.tr(),
                                  style: const TextStyle(
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
                'ready_to_start'.tr(),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: textColor,
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
                        Padding(
                          padding: const EdgeInsets.only(left: 24.0),
                          child: Text(
                            'new_chat'.tr(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade900 : const Color(0xFF1E1E1E),
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
                title: 'chat_history'.tr(),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'no_chat_history'.tr(),
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
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
                title: 'popular_agent'.tr(),
                onSeeAll: () async {
                  final shouldReload = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgentsScreen(),
                    ),
                  );
                  if (shouldReload == true) {
                    _loadSessions();
                  }
                },
              ),
              const SizedBox(height: 16),

              // Popular Agent Cards
              if (_isLoadingAgents)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: CircularProgressIndicator(color: primaryYellow),
                  ),
                )
              else if (_agents.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'no_agents'.tr(),
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
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
                      final desc = agent['description'] as String? ?? 'Assistant';
                      final baseColor = _agentColors[index % _agentColors.length];
                      final bgColor = isDark ? Color.lerp(baseColor, Colors.black, 0.4)! : baseColor;

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
      ),
    );
  }
}
