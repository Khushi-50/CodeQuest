import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hackmol7/screens/language_selection_screen.dart';
import 'package:lottie/lottie.dart';

import 'package:hackmol7/screens/login_screen.dart';
import 'package:hackmol7/ui/appcolors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    // Fade animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Navigation logic
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));

    print("DEBUG: Splash sequence started");

    String? token = await storage.read(key: 'auth_token');

    print("DEBUG: Token: $token");

    if (!mounted) return;

    if (token != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LanguageSelectionScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          /// CENTER CONTENT
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🔥 LOTTIE ANIMATION (UPDATED)
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondaryGlow,
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Lottie.asset(
                        'assets/animations/space_boy_developer.json',
                        fit: BoxFit.contain,
                        repeat: true,
                        animate: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// APP NAME
                  Text(
                    'CodeQuest',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: AppColors.primary,
                      shadows: [
                        Shadow(color: AppColors.primaryGlow, blurRadius: 15),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  /// TAGLINE
                  const Text(
                    'Level Up Your Logic',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// OPTIONAL FOOTER
          // Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Padding(
          //     padding: const EdgeInsets.only(bottom: 40),
          //     child: Text(
          //       'HACKMOL 7.0',
          //       style: TextStyle(
          //         color: AppColors.textSecondary,
          //         fontSize: 12,
          //         fontWeight: FontWeight.w600,
          //         letterSpacing: 4,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
