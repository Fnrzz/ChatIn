import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: message.isUser ? _buildUserBubble() : _buildAiBubble(),
    );
  }

  Widget _buildAiBubble() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI label with icon
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.filter_vintage,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ChaTin',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Message bubble(s) — split by double newline for multi-paragraph
        ..._buildAiParagraphs(),
      ],
    );
  }

  List<Widget> _buildAiParagraphs() {
    final paragraphs = message.content.split('\n\n');
    return paragraphs.map((paragraph) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            paragraph.trim(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildUserBubble() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // User label with avatar
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF8BBD0),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Me',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Message bubble
        Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
