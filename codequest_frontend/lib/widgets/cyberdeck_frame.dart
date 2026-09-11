import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../ui/appcolors.dart';

class CyberdeckFrame extends StatelessWidget {
  final Widget child;

  const CyberdeckFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // On mobile or narrow viewports, render full bleed
        if (!kIsWeb || constraints.maxWidth <= 650) {
          return child;
        }

        // On desktop web browsers, render inside a Cyberdeck Terminal Frame
        return Scaffold(
          backgroundColor: const Color(0xFF060913),
          body: Center(
            child: Container(
              width: 480,
              height: 900,
              margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  children: [
                    // Cyberdeck Top Status Bar
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0F1D),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5F56),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFBD2E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF27C93F),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "NETRUNNER // TERMINAL v1.0",
                            style: TextStyle(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.wifi,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    // Main App Canvas
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
