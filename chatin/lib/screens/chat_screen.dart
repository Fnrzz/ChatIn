import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/agent_selector.dart';
import '../services/database_helper.dart';

class ChatScreen extends StatefulWidget {
  final String? sessionId;
  final String? initialMessage;
  final String? conversationTitle;
  final String? initialAgent;
  final String? initialAgentId;

  const ChatScreen({
    super.key,
    this.sessionId,
    this.initialMessage,
    this.conversationTitle,
    this.initialAgent,
    this.initialAgentId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  bool _isGenerating = false;
  String _conversationTitle = 'New Chat';
  StreamSubscription<String>? _chatSubscription;
  String? _sessionId;
  bool _isInitializingSession = true;

  // Dynamic agent state
  List<Map<String, dynamic>> _agents = [];
  Map<String, dynamic>? _selectedAgent;
  bool _isLoadingAgents = true;
  RealtimeChannel? _agentsChannel;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionId;
    if (widget.conversationTitle != null) {
      _conversationTitle = widget.conversationTitle!;
    }
    _loadAgents();
    _subscribeToAgents();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    if (_agentsChannel != null) {
      Supabase.instance.client.removeChannel(_agentsChannel!);
    }
    super.dispose();
  }

  void _subscribeToAgents() {
    _agentsChannel = Supabase.instance.client
        .channel('public:agents:chat')
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

  Future<void> _loadAgents() async {
    try {
      final agents = await _chatService.getAgents();
      if (!mounted) return;

      if (agents.isEmpty) {
        setState(() {
          _agents = [];
          _selectedAgent = null;
          _isLoadingAgents = false;
          _isInitializingSession = false;
        });
        return;
      }

      if (_selectedAgent == null) {
        // Initial load logic
        Map<String, dynamic>? selected;
        if (widget.initialAgentId != null) {
          selected = agents.firstWhere(
            (a) => a['id'].toString() == widget.initialAgentId,
            orElse: () => agents.first,
          );
        } else if (widget.initialAgent != null) {
          selected = agents.firstWhere(
            (a) =>
                (a['name'] as String?)?.toLowerCase() ==
                widget.initialAgent!.toLowerCase(),
            orElse: () => agents.first,
          );
        } else {
          selected = agents.first;
        }

        setState(() {
          _agents = agents;
          _selectedAgent = selected;
          _isLoadingAgents = false;
        });

        _initSession();
      } else {
        // Mid-session real-time update logic
        final agentStillExists = agents.any((a) => a['id'] == _selectedAgent!['id']);

        if (agentStillExists) {
          // Agent is still active, just update the list quietly
          setState(() {
            _agents = agents;
            // Optionally update the selected agent's details if they changed
            _selectedAgent = agents.firstWhere((a) => a['id'] == _selectedAgent!['id']);
            _isLoadingAgents = false;
          });
        } else {
          // Agent was deactivated/drafted by admin mid-session!
          // Switch to the first available agent and reset session
          setState(() {
            _agents = agents;
            _selectedAgent = agents.first;
            _isLoadingAgents = false;
            
            // Reset chat state
            _chatSubscription?.cancel();
            _messages.clear();
            _conversationTitle = 'New Chat';
            _isGenerating = false;
            _sessionId = null;
          });
          
          _initSession();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The current agent is no longer available. Switched to another agent.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAgents = false;
        _isInitializingSession = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load agents: $e')),
      );
    }
  }

  Future<void> _initSession() async {
    if (_selectedAgent == null) return;

    setState(() {
      _isInitializingSession = true;
    });

    try {
      if (_sessionId != null) {
        await _loadLocalHistory();
      }

      setState(() {
        _isInitializingSession = false;
      });

      // Send initial message if provided (only if no existing messages)
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty && _messages.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sendMessage(widget.initialMessage!);
        });
      } else if (_messages.isNotEmpty) {
        // Scroll to bottom if we loaded history
        _scrollToBottom();
      }
    } catch (e) {
      print('Failed to init session: $e');
      setState(() {
        _isInitializingSession = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing session: $e')),
        );
      }
    }
  }

  // Load history from SQLite, convert to ChatMessage and set to state
  Future<void> _loadLocalHistory() async {
    if (_sessionId == null) return;
    try {
      final historyData = await DatabaseHelper().getSessionMessages(_sessionId!);
      if (mounted) {
        setState(() {
          _messages.clear();
          for (var msg in historyData) {
            _messages.add(ChatMessage(
              content: msg['content'] as String,
              isUser: msg['role'] == 'user',
              timestamp: msg['created_at'] != null 
                  ? DateTime.fromMillisecondsSinceEpoch(msg['created_at'] as int)
                  : null,
            ));
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Failed to load local history: $e');
    }
  }

  void _onAgentChanged(Map<String, dynamic> newAgent) {
    if (_selectedAgent != null && newAgent['id'] == _selectedAgent!['id']) {
      return; // Same agent, do nothing
    }

    _chatSubscription?.cancel();
    setState(() {
      _selectedAgent = newAgent;
      _messages.clear();
      _conversationTitle = 'New Chat';
      _isGenerating = false;
      _sessionId = null;
    });

    _initSession();
  }



  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    if (_sessionId == null) {
      if (_selectedAgent == null) return;
      try {
        _sessionId = await _chatService.createNewSession(_selectedAgent!['id'].toString());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start session: $e')),
          );
        }
        return;
      }
    }
    
    if (!mounted) return;

    setState(() {
      // Add user message
      _messages.add(ChatMessage(content: text.trim(), isUser: true));

      // Hapus otomatisasi judul offline di sini karena kita akan menggunakan AI di onDone
      _isGenerating = true;
    });

    _inputController.clear();
    _scrollToBottom();

    // Start receiving AI response
    _generateAiResponse(text.trim());
  }

  void _generateAiResponse(String userMessage) {
    if (_selectedAgent == null || _sessionId == null) return;

    String aiResponse = '';
    final agentId = _selectedAgent!['id'].toString();

    _chatSubscription =
        _chatService.sendMessage(userMessage, _sessionId!, agentId).listen(
      (chunk) {
        aiResponse += chunk;
        setState(() {
          // Update existing AI message or create a new one
          if (_messages.isNotEmpty && !_messages.last.isUser) {
            _messages.last = ChatMessage(content: aiResponse, isUser: false);
          } else {
            _messages.add(ChatMessage(content: aiResponse, isUser: false));
          }
        });
        _scrollToBottom();
      },
      onDone: () async {
        if (mounted) {
          setState(() {
            _isGenerating = false;
          });
          _scrollToBottom();
          
          // Trigger AI Title Generation jika judul masih berupa default 'New Chat' dan sudah ada balasan
          if (_conversationTitle == 'New Chat' && _sessionId != null && _messages.length >= 2) {
            final userMsg = _messages[0].content;
            final aiMsg = _messages[1].content;
            
            final newTitle = await _chatService.generateSessionTitle(_sessionId!, userMsg, aiMsg);
            if (newTitle != null && mounted) {
              setState(() {
                _conversationTitle = newTitle;
              });
            }
          }
        }
      },
      onError: (error) {
        setState(() {
          _isGenerating = false;
          _messages.add(ChatMessage(
            content: 'Sorry, something went wrong. Please try again.',
            isUser: false,
          ));
        });
      },
    );
  }

  void _stopGenerating() {
    _chatSubscription?.cancel();
    setState(() {
      _isGenerating = false;
    });
  }

  Future<void> _deleteCurrentSession() async {
    if (_sessionId == null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
        content: const Text('Are you sure you want to delete this chat history?', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper().deleteSession(_sessionId!);
      try {
        await Supabase.instance.client.from('chat_sessions').delete().eq('id', _sessionId!);
      } catch (_) {}
      
      if (mounted) {
        Navigator.pop(context); // Go back to previous screen
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isGenerating,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isGenerating) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mohon tunggu AI selesai membalas...'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0E8), // Cream background like design
        body: Column(
          children: [
            // ── Top Section (cream background) ──
            _buildTopBar(),

            // ── Chat Area (dark background) ──
            Expanded(child: _buildChatArea()),

            // ── Stop generate button ──
            if (_isGenerating) _buildStopButton(),

            // ── Input bar ──
            ChatInputBar(
              controller: _inputController,
              isGenerating: _isGenerating || _isInitializingSession || _isLoadingAgents,
              onSend: () => _sendMessage(_inputController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row: Back, Model Selector, Compose
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                GestureDetector(
                  onTap: () {
                    if (!_isGenerating) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mohon tunggu AI selesai membalas...'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
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
                // Right controls: Agent Selector and Compose button
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: AgentSelector(
                          agents: _agents,
                          currentAgent: _selectedAgent,
                          onAgentChanged: _onAgentChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_sessionId != null) ...[
                        GestureDetector(
                          onTap: _deleteCurrentSession,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E1E1E),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Compose button
                      GestureDetector(
                        onTap: () {
                          // New chat action
                          _chatSubscription?.cancel();
                          setState(() {
                            _messages.clear();
                            _conversationTitle = 'New Chat';
                            _isGenerating = false;
                            _sessionId = null;
                          });
                          _initSession();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Conversation title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                _conversationTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: (_isLoadingAgents || _isInitializingSession)
            ? _buildInitializingState()
            : (_messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    itemCount: _messages.length +
                        (_isGenerating &&
                                (_messages.isEmpty || _messages.last.isUser)
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      // Show typing indicator at the end if AI hasn't started responding yet
                      if (index == _messages.length) {
                        return const TypingIndicator();
                      }
                      return ChatBubble(message: _messages[index]);
                    },
                  )),
      ),
    );
  }

  Widget _buildInitializingState() {
    final label = _isLoadingAgents ? 'Loading agents...' : 'Initializing session...';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Color(0xFFFFD500)), // Yellow accent
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_vintage,
            size: 48,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a message below to begin',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopButton() {
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: GestureDetector(
          onTap: _stopGenerating,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD500),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Stop generate',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
