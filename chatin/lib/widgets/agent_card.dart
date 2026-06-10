import 'package:flutter/material.dart';

class AgentCard extends StatelessWidget {
  final String title;
  final String category;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const AgentCard({
    super.key,
    required this.title,
    required this.category,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 300, // Card lebih memanjang ke bawah
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26, // Ukuran font judul sedikit lebih besar
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 18, // Ukuran font deskripsi lebih besar lagi
                  fontWeight: FontWeight.w600, // Semibold
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Chat with agent',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
