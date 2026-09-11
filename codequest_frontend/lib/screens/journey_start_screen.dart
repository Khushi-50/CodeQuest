import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../ui/appcolors.dart';
import '../widgets/cyber_button.dart';

class JourneyStartScreen extends StatelessWidget {
  final String level;
  final String learnerType;
  final double overallAccuracy;

  const JourneyStartScreen({
    super.key,
    required this.level,
    required this.learnerType,
    required this.overallAccuracy,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "ANALYSIS COMPLETE",
                style: TextStyle(
                  color: AppColors.secondary,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // THE ROCKET LOTTIE
              Lottie.asset(
                'assets/animations/Rocket Launch.json',
                height: 320,
                repeat: true,
              ),

              Text(
                "RANK: $level",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You are a $learnerType",
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),

              const SizedBox(height: 30),

              // Accuracy display
              Text(
                "Overall Logic Score: ${(overallAccuracy * 100).toInt()}%",
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 60),

              const Text(
                "Now, let's begin your journey.",
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
              const SizedBox(height: 20),

              CyberButton(
                label: "INITIALIZE MAP",
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
