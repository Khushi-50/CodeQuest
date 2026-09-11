import 'package:flutter/material.dart';
import 'package:hackmol7/screens/journey_start_screen.dart';
import 'package:hackmol7/services/user_service.dart';
import '../ui/appcolors.dart';
import '../widgets/cyber_button.dart';
import 'placement_quiz_screen.dart';

class TrackSelectionScreen extends StatefulWidget {
  const TrackSelectionScreen({super.key});

  @override
  State<TrackSelectionScreen> createState() => _TrackSelectionScreenState();
}

class _TrackSelectionScreenState extends State<TrackSelectionScreen> {
  String? _selectedManualLevel;
  bool _isSubmitting = false; // single declaration — bug fix
  final UserService _userService = UserService();

  // ── Confirm manual level ───────────────────────────────────────────────────
  Future<void> _confirmManualLevel() async {
    if (_selectedManualLevel == null) return;

    setState(() => _isSubmitting = true);

    final bool success = await _userService.setManualLevel(
      _selectedManualLevel!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => JourneyStartScreen(
            level: _selectedManualLevel!,
            learnerType: 'Determined Explorer',
            overallAccuracy: 1.0, // manual = full confidence
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Session expired or unauthorized. Please log in again.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "IDENTITY SCAN",
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Choose Your Rank",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              _buildLevelCard(
                "Beginner",
                "I'm new to coding logic.",
                Colors.greenAccent,
              ),
              _buildLevelCard(
                "Intermediate",
                "I know basic loops & conditions.",
                Colors.blueAccent,
              ),
              _buildLevelCard(
                "Advanced",
                "I can build complex algorithms.",
                Colors.purpleAccent,
              ),

              const Spacer(),

              _buildDiagnosticCard(),

              const SizedBox(height: 20),

              // Show confirm button only when a level is selected
              if (_selectedManualLevel != null)
                CyberButton(
                  label: "CONFIRM RANK",
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting
                      ? () {}
                      : _confirmManualLevel, // single call
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(String title, String desc, Color color) {
    final bool isSelected = _selectedManualLevel == title;
    return GestureDetector(
      onTap: _isSubmitting
          ? null
          : () => setState(() => _selectedManualLevel = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white10,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.shield, color: color, size: 30),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticCard() {
    return InkWell(
      onTap: _isSubmitting
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlacementQuizScreen()),
            ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF2994A), Color(0xFFF2C94C)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.psychology, size: 45, color: Colors.white),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "I AM NOT SURE",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Let the AI analyze your logic DNA.",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
