import 'package:flutter/material.dart';

class AgentSelector extends StatefulWidget {
  final List<Map<String, dynamic>> agents;
  final Map<String, dynamic>? currentAgent;
  final ValueChanged<Map<String, dynamic>>? onAgentChanged;

  const AgentSelector({
    super.key,
    required this.agents,
    required this.currentAgent,
    this.onAgentChanged,
  });

  @override
  State<AgentSelector> createState() => _AgentSelectorState();
}

class _AgentSelectorState extends State<AgentSelector> with SingleTickerProviderStateMixin {
  bool _isOpen = false;

  IconData _getIconForType(String? type) {
    switch (type?.toLowerCase()) {
      case 'psikolog':
      case 'mental_health':
        return Icons.favorite_outline;
      case 'ui_ux':
      case 'design':
        return Icons.palette_outlined;
      case 'content_writer':
      case 'writer':
        return Icons.edit_note_outlined;
      case 'english_tutor':
      case 'tutor':
        return Icons.translate_outlined;
      case 'developer':
      case 'programming':
        return Icons.code_outlined;
      default:
        return Icons.smart_toy_outlined;
    }
  }

  void _showAgentPicker(BuildContext context) async {
    if (widget.agents.isEmpty) return;

    setState(() {
      _isOpen = true;
    });

    Map<String, dynamic>? tempSelectedAgent = widget.currentAgent;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag Handle
                      const SizedBox(height: 12),
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      const Text(
                        'Pilih Agen',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Agent List
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          itemCount: widget.agents.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final agent = widget.agents[index];
                            final isSelected = tempSelectedAgent != null &&
                                agent['id'] == tempSelectedAgent!['id'];
                            final icon = _getIconForType(agent['type']);

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  tempSelectedAgent = agent;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFFF9E6)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFFD500)
                                        : Colors.grey.shade200,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: const Color(0xFFFFD500).withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    else
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Icon Container
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFFFD500).withOpacity(0.2)
                                            : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        icon,
                                        color: isSelected
                                            ? const Color(0xFFB39500) // Darker yellow for contrast
                                            : Colors.grey.shade600,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Text details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            agent['name'] ?? 'Unknown Agent',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (agent['description'] != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              agent['description'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isSelected
                                                    ? Colors.black54
                                                    : Colors.grey.shade500,
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Checkmark for selected
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFFFFD500),
                                        size: 24,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Action Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (tempSelectedAgent != null) {
                                widget.onAgentChanged?.call(tempSelectedAgent!);
                              }
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E1E1E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 4,
                              shadowColor: Colors.black.withOpacity(0.3),
                            ),
                            child: const Text(
                              'Chat with Agent',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.currentAgent?['name'] ?? 'Pilih Agen';
    final currentIcon = _getIconForType(widget.currentAgent?['type']);

    return GestureDetector(
      onTap: () => _showAgentPicker(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _isOpen ? const Color(0xFFFFD500) : Colors.black.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentIcon,
              size: 18,
              color: const Color(0xFFB39500),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedRotation(
              turns: _isOpen ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
