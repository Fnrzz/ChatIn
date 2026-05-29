import 'package:flutter/material.dart';

class AgentSelector extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final displayName = currentAgent?['name'] ?? 'Select Agent';

    return GestureDetector(
      onTap: agents.isNotEmpty ? () => _showAgentPicker(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.black26,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

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

  void _showAgentPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Job Agent',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...agents.map((agent) {
                  final isSelected = currentAgent != null &&
                      agent['id'] == currentAgent!['id'];
                  final icon = _getIconForType(agent['type']);

                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    leading: Icon(
                      icon,
                      color: isSelected
                          ? const Color(0xFFFFD500)
                          : Colors.grey[400],
                      size: 24,
                    ),
                    title: Text(
                      agent['name'] ?? 'Unknown Agent',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: agent['description'] != null
                        ? Text(
                            agent['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: Color(0xFF4ADE80))
                        : null,
                    onTap: () {
                      onAgentChanged?.call(agent);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
