import 'package:flutter/material.dart';
import '../ui/appcolors.dart';

class FillInBlanksWidget extends StatelessWidget {
  final String codeTemplate; // e.g., "FOR i FROM 1 TO 10 ___ PRINT(i) ___"
  final List<String> userInputs;
  final bool isAnswerChecked;
  final Function(int, String) onInputChanged;

  const FillInBlanksWidget({
    super.key,
    required this.codeTemplate,
    required this.userInputs,
    required this.isAnswerChecked,
    required this.onInputChanged,
  });

  @override
  Widget build(BuildContext context) {
    List<String> parts = codeTemplate.split("___");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117), // GitHub Dark style
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _buildContent(parts),
      ),
    );
  }

  List<Widget> _buildContent(List<String> parts) {
    List<Widget> widgets = [];
    for (int i = 0; i < parts.length; i++) {
      // Add the static code text
      widgets.add(
        Text(
          parts[i],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'monospace',
          ),
        ),
      );

      // Add the text field if there's a blank following this part
      if (i < parts.length - 1) {
        widgets.add(
          SizedBox(
            width: 80,
            child: TextField(
              enabled: !isAnswerChecked,
              onChanged: (value) => onInputChanged(i, value),
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.secondary),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}
