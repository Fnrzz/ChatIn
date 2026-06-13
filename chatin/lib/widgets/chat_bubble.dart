import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/auth_provider.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: message.isUser ? _buildUserBubble(context) : _buildAiBubble(),
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
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: const Icon(
                  Icons.filter_vintage,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'ChatIn',
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
          child: GptMarkdown(
            paragraph.trim(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.45,
            ),
            latexBuilder: (context, tex, textStyle, inline) {
              final mathWidget = Math.tex(
                tex,
                textStyle: textStyle.copyWith(color: Colors.white),
                mathStyle: inline ? MathStyle.text : MathStyle.display,
                onErrorFallback: (err) => Text(
                  tex,
                  style: textStyle.copyWith(color: Colors.red),
                ),
              );
              
              if (inline) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: mathWidget,
                );
              }
              
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: mathWidget,
                ),
              );
            },
          ),
        ),
      );
    }).toList();
  }

  Widget _buildUserBubble(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final avatarUrl = user?.userMetadata?['avatar_url'] as String?;

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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF8BBD0),
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 16)
                    : null,
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
