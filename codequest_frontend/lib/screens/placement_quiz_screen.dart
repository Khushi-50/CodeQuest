import 'package:flutter/material.dart';
import 'package:hackmol7/screens/journey_start_screen.dart';
import '../ui/appcolors.dart';
import '../services/user_service.dart';
import '../widgets/cyber_button.dart';

class PlacementQuizScreen extends StatefulWidget {
  const PlacementQuizScreen({super.key});

  @override
  State<PlacementQuizScreen> createState() => _PlacementQuizScreenState();
}

class _PlacementQuizScreenState extends State<PlacementQuizScreen> {
  final PageController _pageController = PageController();
  final UserService _userService = UserService();
  int _currentIndex = 0;
  bool _isAnalyzing = false;

  final List<Map<String, dynamic>> _userResults = [];
  String? _currentSelectedAnswer;

  final List<Map<String, dynamic>> _questions = [
    {
      "id": 1,
      "question_text": "x ← 5\nx ← x + 3\nPRINT x\nOutput?",
      "category": "Sequential",
      "options": ["5", "8", "3"],
      "correct_answer": "8",
    },
    {
      "id": 2,
      "question_text": "x ← 3\ny ← x + 2\nPRINT y\nOutput?",
      "category": "Sequential",
      "options": ["3", "5", "2"],
      "correct_answer": "5",
    },
    {
      "id": 3,
      "question_text":
          "x ← 5\nIF x > 3 THEN PRINT \"A\" ELSE PRINT \"B\"\nOutput?",
      "category": "Conditional",
      "options": ["A", "B", "None"],
      "correct_answer": "A",
    },
    {
      "id": 4,
      "question_text":
          "n ← 8\nIF n MOD 2 = 0 THEN PRINT \"Even\" ELSE PRINT \"Odd\"\nOutput?",
      "category": "Conditional",
      "options": ["Even", "Odd", "None"],
      "correct_answer": "Even",
    },
    {
      "id": 5,
      "question_text": "FOR i ← 1 TO 3 DO PRINT i END FOR\nOutput?",
      "category": "Loop",
      "options": ["1 2 3", "1 2", "0 1 2"],
      "correct_answer": "1 2 3",
    },
    {
      "id": 6,
      "question_text":
          "sum ← 0\nFOR i ← 1 TO 3 DO sum ← sum + i END FOR\nPRINT sum\nOutput?",
      "category": "Loop",
      "options": ["6", "3", "5"],
      "correct_answer": "6",
    },
    {
      "id": 7,
      "question_text": "i ← 1\nWHILE i ≤ 3 DO PRINT i\nOutput?",
      "category": "Loop",
      "options": ["1 2 3", "1 2", "2 3"],
      "correct_answer": "1 2 3",
    },
  ];

  // ── Handle next / finish ───────────────────────────────────────────────────
  void _handleNext() {
    if (_currentSelectedAnswer == null) return;

    final q = _questions[_currentIndex];
    _userResults.add({
      "category": q['category'],
      "isCorrect": _currentSelectedAnswer == q['correct_answer'],
    });

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _currentSelectedAnswer = null;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _sendToAnalysis();
    }
  }

  Future<void> _sendToAnalysis() async {
    setState(() => _isAnalyzing = true);

    final result = await _userService.evaluatePlacement(_userResults);

    if (!mounted) return;

    if (result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => JourneyStartScreen(
            level: result['level'] as String? ?? 'Beginner',
            learnerType: result['learnerType'] as String? ?? 'Explorer',
            // BUG FIX: cast via num first — handles both int and double from JSON
            overallAccuracy: (result['overallAccuracy'] as num? ?? 0)
                .toDouble(),
          ),
        ),
      );
    } else {
      setState(() => _isAnalyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Signal lost — check your server connection and retry.",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) return _buildAnalysisOverlay();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _questions.length,
        itemBuilder: (_, index) => _buildQuestionPage(_questions[index]),
      ),
    );
  }

  Widget _buildAnalysisOverlay() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.secondary),
            const SizedBox(height: 30),
            const Text(
              "SCANNING LOGIC DNA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Mapping your answers to the algorithm...",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionPage(Map<String, dynamic> q) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 60),
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: Colors.white10,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 30),
          Text(
            (q['category'] as String).toUpperCase(),
            style: const TextStyle(
              color: AppColors.secondary,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            q['question_text'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1.6,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 40),
          Expanded(child: _buildOptions(q)),
          CyberButton(
            label: _currentIndex == _questions.length - 1
                ? "FINISH ANALYSIS"
                : "NEXT QUESTION",
            onPressed: _currentSelectedAnswer == null ? () {} : _handleNext,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptions(Map<String, dynamic> q) {
    return ListView(
      children: (q['options'] as List<dynamic>).map((opt) {
        final String option = opt.toString();
        final bool isSelected = _currentSelectedAnswer == option;
        return GestureDetector(
          onTap: () => setState(() => _currentSelectedAnswer = option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.secondary.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? AppColors.secondary : Colors.white10,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? AppColors.secondary : Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
