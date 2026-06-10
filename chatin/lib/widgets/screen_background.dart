import 'package:flutter/material.dart';

class ScreenBackground extends StatelessWidget {
  final Widget child;

  const ScreenBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // Smooth Image Transition
          Positioned.fill(
            child: Image.asset(
              'assets/images/background-app.avif',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: isDark ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Image.asset(
                'assets/images/background-app-dark.avif',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Smooth Gradient Transition
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                    ? [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(1),
                      ]
                    : [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.8),
                        Colors.white.withOpacity(1),
                      ],
              ),
            ),
            child: SafeArea(child: child),
          ),
        ],
      ),
    );
  }
}
