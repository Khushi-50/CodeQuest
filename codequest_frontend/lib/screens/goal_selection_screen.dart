import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hackmol7/screens/main_navigation_screen.dart';
import 'package:hackmol7/widgets/cyber_button.dart';
import '../ui/appcolors.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  int _selectedGoalIndex = 1; // Default to 'Regular'

  final List<Map<String, String>> _goals = [
    {'title': 'Casual', 'desc': '5 mins / day', 'xp': '+10 XP'},
    {'title': 'Regular', 'desc': '15 mins / day', 'xp': '+25 XP'},
    {'title': 'Serious', 'desc': '30 mins / day', 'xp': '+50 XP'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      // context,
                      // MaterialPageRoute(
                      //   builder: (context) => LanguageSelectionScreen(),
                      // ),
                    );
                  },
                  icon: Icon(Icons.arrow_back_ios_new_sharp),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 40),
              _buildMascotSection(),
              const SizedBox(height: 40),
              Text(
                'Set Your Daily Goal',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 24,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Don’t worry, you can change this later.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),

              // Goal Options
              Expanded(
                child: ListView.separated(
                  itemCount: _goals.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildGoalCard(index),
                ),
              ),

              // Action Button
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGlow,
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  // child: ElevatedButton(
                  //   onPressed: () {
                  //     // TODO: Save goal to your Node.js backend
                  //     // Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()));
                  //   },
                  //   child: const Text('COMMIT TO GOAL'),
                  // ),
                  child: CyberButton(
                    label: 'COMMIT TO GOAL',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainNavigationScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMascotSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('🦫', style: TextStyle(fontSize: 70)), // Mascot Placeholder
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: const Text(
              "How much time do you want to spend in the Logic Jungle today?",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(int index) {
    bool isSelected = _selectedGoalIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedGoalIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceLight : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceLight,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primaryGlow, blurRadius: 10)]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _goals[index]['title']!,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _goals[index]['desc']!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            Text(
              _goals[index]['xp']!,
              style: TextStyle(
                color: isSelected
                    ? AppColors.secondary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
