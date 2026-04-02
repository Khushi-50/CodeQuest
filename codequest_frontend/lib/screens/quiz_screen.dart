import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../ui/appcolors.dart';
import '../widgets/cyber_button.dart';
import '../providers/quest_provider.dart';
import '../models/quest_models.dart';
import '../services/notification_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'package:flutter_dotenv/flutter_dotenv.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  QUIZ SCREEN — Duolingo-style with 6 question types
// ══════════════════════════════════════════════════════════════════════════════

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String title;
  final String subtopicId;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.title,
    required this.subtopicId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int _currentPage = 0;
  int _correctCount = 0;
  int _totalXpEarned = 0;
  bool _isAnswerChecked = false;
  bool _isCorrect = false;
  int? _selectedIndex; // for MCQ / T-F
  String? _userAnswer; // for fill-blank & tap-correct

  // Drag-drop state
  List<String> _placedTokens = []; // slots filled by user
  List<String> _availableTokens = []; // remaining draggable pool

  // Reorder state
  List<String> _reorderedLines = [];

  final PageController _pageController = PageController();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
    _initQuestionState();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initQuestionState() {
    final q = widget.questions[_currentPage];
    _selectedIndex = null;
    _userAnswer = null;
    _isAnswerChecked = false;
    _isCorrect = false;

    // Drag-drop init
    if (q.questionType == QuestionType.dragDrop) {
      final blanks = '___'.allMatches(q.codeTemplate ?? '').length;
      _placedTokens = List.filled(blanks, '');
      final pool = q.dragTokens ?? q.options;
      _availableTokens = [...pool]..shuffle(Random());
    }

    // Reorder init
    if (q.questionType == QuestionType.reorderCode) {
      _reorderedLines = [...(q.codeLines ?? [])]..shuffle(Random());
    }
  }

  // ── ANSWER CHECKING ────────────────────────────────────────────────────────
  bool _canCheck() {
    final q = widget.questions[_currentPage];
    switch (q.questionType) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return _selectedIndex != null;
      case QuestionType.fillBlank:
        return (_userAnswer ?? '').trim().isNotEmpty;
      case QuestionType.tapCorrect:
        return _userAnswer != null;
      case QuestionType.dragDrop:
        return _placedTokens.every((t) => t.isNotEmpty);
      case QuestionType.reorderCode:
        return true; // always checkable once shuffled
    }
  }

  String _getUserAnswerString() {
    final q = widget.questions[_currentPage];
    switch (q.questionType) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return _selectedIndex != null ? q.options[_selectedIndex!] : '';
      case QuestionType.fillBlank:
        return (_userAnswer ?? '').trim();
      case QuestionType.tapCorrect:
        return _userAnswer ?? '';
      case QuestionType.dragDrop:
        return _placedTokens.join(' ');
      case QuestionType.reorderCode:
        return _reorderedLines.join('\n');
    }
  }

  void _handleCheck() {
    if (!_canCheck()) return;
    final q = widget.questions[_currentPage];
    final userAns = _getUserAnswerString().toLowerCase().trim();
    final correctAns = q.answer.toLowerCase().trim();
    _isCorrect = userAns == correctAns;

    if (_isCorrect) {
      _correctCount++;
      _totalXpEarned += q.xp;
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
    }
    setState(() => _isAnswerChecked = true);
  }

  void _handleContinue() {
    if (_currentPage < widget.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
        _initQuestionState();
      });
    } else {
      _handleFinish();
    }
  }

  Future<void> _handleFinish() async {
    final provider = Provider.of<QuestProvider>(context, listen: false);
    final passed = _correctCount >= (widget.questions.length * 0.6).ceil();
    await provider.completeSubtopic(widget.subtopicId, passed, _totalXpEarned);
    if (passed) {
      await NotificationService().showQuizWin(
        topicName: widget.title,
        xpEarned: _totalXpEarned,
      );
    }
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ResultDialog(
          correctCount: _correctCount,
          totalCount: widget.questions.length,
          xpEarned: _totalXpEarned,
          passed: passed,
          onContinue: () => Navigator.pop(context),
        ),
      );
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _askAI(QuizQuestion q) async {
    final userAnswer = _getUserAnswerString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AskAISheet(
        question: q.question,
        correctAnswer: q.answer,
        userAnswer: userAnswer,
        codeContext: q.codeTemplate,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_currentPage == 0 && !_isAnswerChecked) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Leave the quiz?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Your progress in this quiz will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'STAY',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'LEAVE',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = (_currentPage + 1) / widget.questions.length;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(progress),
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.questions.length,
                itemBuilder: (_, i) => _buildQuestion(widget.questions[i]),
              ),
            ),
            _buildFeedbackBanner(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(double progress) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white54),
        onPressed: () async {
          if (await _onWillPop()) Navigator.pop(context);
        },
      ),
      title: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white10,
          color: AppColors.primary,
          minHeight: 8,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              '${_currentPage + 1}/${widget.questions.length}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(QuizQuestion q) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (_, child) {
        final dx = _isAnswerChecked && !_isCorrect
            ? sin(_shakeAnimation.value * pi * 6) * 8
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionHeader(q),
            const SizedBox(height: 24),
            _buildQuestionBody(q),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionHeader(QuizQuestion q) {
    final typeLabel = _questionTypeLabel(q.questionType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _typeColor(q.questionType).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _typeColor(q.questionType).withOpacity(0.4),
                ),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  color: _typeColor(q.questionType),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${q.xp} XP',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          q.question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionBody(QuizQuestion q) {
    switch (q.questionType) {
      case QuestionType.multipleChoice:
        return _buildMCQ(q);
      case QuestionType.trueFalse:
        return _buildTrueFalse(q);
      case QuestionType.fillBlank:
        return _buildFillBlank(q);
      case QuestionType.tapCorrect:
        return _buildTapCorrect(q);
      case QuestionType.dragDrop:
        return _buildDragDrop(q);
      case QuestionType.reorderCode:
        return _buildReorderCode(q);
    }
  }

  // ── 1. MULTIPLE CHOICE ─────────────────────────────────────────────────────
  Widget _buildMCQ(QuizQuestion q) {
    return Column(
      children: List.generate(q.options.length, (i) {
        final isSelected = _selectedIndex == i;
        final isCorrectOpt = q.options[i] == q.answer;
        Color border = Colors.white10;
        Color bg = AppColors.surface;
        if (isSelected && !_isAnswerChecked) border = AppColors.primary;
        if (_isAnswerChecked) {
          if (isCorrectOpt) {
            border = Colors.greenAccent;
            bg = Colors.greenAccent.withOpacity(0.07);
          } else if (isSelected) {
            border = Colors.redAccent;
            bg = Colors.redAccent.withOpacity(0.07);
          }
        }
        return GestureDetector(
          onTap: _isAnswerChecked
              ? null
              : () => setState(() => _selectedIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: border, width: 2),
            ),
            child: Row(
              children: [
                _optionBubble(i, isSelected),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    q.options[i],
                    style: TextStyle(
                      color: _isAnswerChecked && isCorrectOpt
                          ? Colors.greenAccent
                          : Colors.white,
                      fontSize: 15,
                      fontWeight: _isAnswerChecked && isCorrectOpt
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (_isAnswerChecked && isCorrectOpt)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                if (_isAnswerChecked && isSelected && !isCorrectOpt)
                  const Icon(
                    Icons.cancel_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _optionBubble(int i, bool isSelected) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSelected && !_isAnswerChecked
            ? AppColors.primary.withOpacity(0.15)
            : Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          String.fromCharCode(65 + i),
          style: TextStyle(
            color: isSelected && !_isAnswerChecked
                ? AppColors.primary
                : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── 2. TRUE / FALSE ────────────────────────────────────────────────────────
  Widget _buildTrueFalse(QuizQuestion q) {
    final opts = ['True', 'False'];
    return Row(
      children: List.generate(2, (i) {
        final isSelected = _selectedIndex == i;
        final isCorrectOpt = opts[i] == q.answer;
        Color border = Colors.white10;
        Color bg = AppColors.surface;
        IconData icon = i == 0 ? Icons.check : Icons.close;

        if (isSelected && !_isAnswerChecked) border = AppColors.primary;
        if (_isAnswerChecked) {
          if (isCorrectOpt) {
            border = Colors.greenAccent;
            bg = Colors.greenAccent.withOpacity(0.07);
          } else if (isSelected) {
            border = Colors.redAccent;
            bg = Colors.redAccent.withOpacity(0.07);
          }
        }
        return Expanded(
          child: GestureDetector(
            onTap: _isAnswerChecked
                ? null
                : () => setState(() => _selectedIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(
                right: i == 0 ? 8 : 0,
                left: i == 1 ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: border, width: 2),
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: _isAnswerChecked
                        ? (isCorrectOpt
                              ? Colors.greenAccent
                              : (isSelected
                                    ? Colors.redAccent
                                    : Colors.white24))
                        : (isSelected ? AppColors.primary : Colors.white38),
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    opts[i],
                    style: TextStyle(
                      color: isSelected && !_isAnswerChecked
                          ? AppColors.primary
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── 3. FILL IN THE BLANK ───────────────────────────────────────────────────
  Widget _buildFillBlank(QuizQuestion q) {
    final template = q.codeTemplate ?? '___';
    final parts = template.split('___');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Code template with blank box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (int i = 0; i < parts.length; i++) ...[
                Text(
                  parts[i],
                  style: const TextStyle(
                    color: Color(0xFF79C0FF),
                    fontFamily: 'monospace',
                    fontSize: 15,
                  ),
                ),
                if (i < parts.length - 1)
                  _BlankBox(
                    value: _isAnswerChecked ? _userAnswer ?? '' : null,
                    isCorrect: _isAnswerChecked ? _isCorrect : null,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!_isAnswerChecked)
          TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Type your answer...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (v) => setState(() => _userAnswer = v),
            onSubmitted: (_) => _canCheck() ? _handleCheck() : null,
          ),
        if (_isAnswerChecked) ...[
          const SizedBox(height: 10),
          if (!_isCorrect)
            RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'Correct answer: ',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  TextSpan(
                    text: q.answer,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  // ── 4. TAP THE CORRECT WORD (inline token tap) ────────────────────────────
  Widget _buildTapCorrect(QuizQuestion q) {
    // question is a sentence, options are the candidate words highlighted inline
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tap the correct option:',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: q.options.map((opt) {
            final isSelected = _userAnswer == opt;
            final isCorrectOpt = opt == q.answer;
            Color border = Colors.white70;
            Color bg = AppColors.surface;
            Color text = Colors.white;

            if (isSelected && !_isAnswerChecked) {
              border = AppColors.primary;
              bg = AppColors.primary.withOpacity(0.1);
              text = AppColors.primary;
            }
            if (_isAnswerChecked) {
              if (isCorrectOpt) {
                border = Colors.greenAccent;
                bg = Colors.greenAccent.withOpacity(0.08);
                text = Colors.greenAccent;
              } else if (isSelected) {
                border = Colors.redAccent;
                bg = Colors.redAccent.withOpacity(0.08);
                text = Colors.redAccent;
              }
            }
            return GestureDetector(
              onTap: _isAnswerChecked
                  ? null
                  : () => setState(() => _userAnswer = opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border, width: 2),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_isAnswerChecked && !_isCorrect) ...[
          const SizedBox(height: 12),
          Text(
            'Correct: ${q.answer}',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }

  // ── 5. DRAG & DROP TOKENS ──────────────────────────────────────────────────
  Widget _buildDragDrop(QuizQuestion q) {
    final template = q.codeTemplate ?? '___';
    final parts = template.split('___');
    final blankCount = parts.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Code area with droppable blanks
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              for (int i = 0; i < parts.length; i++) ...[
                if (parts[i].isNotEmpty)
                  Text(
                    parts[i],
                    style: const TextStyle(
                      color: Color(0xFF79C0FF),
                      fontFamily: 'monospace',
                      fontSize: 14,
                      height: 1.8,
                    ),
                  ),
                if (i < blankCount)
                  DragTarget<String>(
                    onWillAccept: (_) =>
                        !_isAnswerChecked && _placedTokens[i].isEmpty,
                    onAccept: (token) {
                      setState(() {
                        _placedTokens[i] = token;
                        _availableTokens.remove(token);
                      });
                    },
                    builder: (_, candidates, __) {
                      final filled = _placedTokens[i].isNotEmpty;
                      final hovering = candidates.isNotEmpty;
                      return GestureDetector(
                        onTap: filled && !_isAnswerChecked
                            ? () {
                                setState(() {
                                  _availableTokens.add(_placedTokens[i]);
                                  _placedTokens[i] = '';
                                });
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          constraints: const BoxConstraints(minWidth: 60),
                          decoration: BoxDecoration(
                            color: hovering
                                ? AppColors.primary.withOpacity(0.15)
                                : (filled
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.05)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isAnswerChecked
                                  ? (_isCorrect
                                        ? Colors.greenAccent
                                        : Colors.redAccent)
                                  : (hovering
                                        ? AppColors.primary
                                        : (filled
                                              ? AppColors.primary.withOpacity(
                                                  0.5,
                                                )
                                              : Colors.white24)),
                              width: 1.5,
                            ),
                          ),
                          child: filled
                              ? Text(
                                  _placedTokens[i],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  '  drop here  ',
                                  style: TextStyle(
                                    color: Colors.white24,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          'Drag the tokens:',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 10),

        // Token bank
        if (!_isAnswerChecked)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableTokens.map((tok) {
              return Draggable<String>(
                data: tok,
                feedback: Material(
                  color: Colors.transparent,
                  child: _TokenChip(label: tok, isDragging: true),
                ),
                childWhenDragging: _TokenChip(label: tok, faded: true),
                child: _TokenChip(label: tok),
              );
            }).toList(),
          ),

        if (_isAnswerChecked && !_isCorrect) ...[
          const SizedBox(height: 12),
          Text(
            'Correct answer: ${q.answer}',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }

  // ── 6. REORDER CODE LINES ──────────────────────────────────────────────────
  Widget _buildReorderCode(QuizQuestion q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Drag lines into the correct order:',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: _isAnswerChecked
              ? _buildStaticCodeBlock(q)
              : ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _reorderedLines.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _reorderedLines.removeAt(oldIndex);
                      _reorderedLines.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (_, i) {
                    return _CodeLineRow(
                      key: ValueKey(_reorderedLines[i]),
                      index: i,
                      line: _reorderedLines[i],
                    );
                  },
                ),
        ),
        if (_isAnswerChecked && !_isCorrect) ...[
          const SizedBox(height: 12),
          const Text(
            'Correct order:',
            style: TextStyle(color: Colors.greenAccent, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            ),
            child: Text(
              q.answer,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStaticCodeBlock(QuizQuestion q) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _reorderedLines.asMap().entries.map((e) {
          final correctLines = q.answer.split('\n');
          final isLineCorrect =
              e.key < correctLines.length &&
              e.value.trim() == correctLines[e.key].trim();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  isLineCorrect ? Icons.check : Icons.close,
                  size: 14,
                  color: isLineCorrect ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  e.value,
                  style: TextStyle(
                    color: isLineCorrect
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── FEEDBACK BANNER ────────────────────────────────────────────────────────
  Widget _buildFeedbackBanner() {
    if (!_isAnswerChecked) return const SizedBox.shrink();
    final q = widget.questions[_currentPage];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: _isCorrect
            ? Colors.greenAccent.withOpacity(0.12)
            : Colors.redAccent.withOpacity(0.12),
        border: Border(
          top: BorderSide(
            color: _isCorrect
                ? Colors.greenAccent.withOpacity(0.4)
                : Colors.redAccent.withOpacity(0.4),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.cancel,
                color: _isCorrect ? Colors.greenAccent : Colors.redAccent,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCorrect ? 'Correct! +${q.xp} XP' : 'Incorrect',
                      style: TextStyle(
                        color: _isCorrect
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (_isCorrect && _totalXpEarned > 0)
                      Text(
                        '$_totalXpEarned XP earned so far',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // ← NEW: AI explanation button shown only on wrong answers
          if (!_isCorrect) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _askAI(q),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.cyanAccent,
                      size: 15,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Why is this wrong? Ask AI',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── BOTTOM BAR ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isLast = _currentPage == widget.questions.length - 1;
    String label;
    if (!_isAnswerChecked)
      label = 'CHECK';
    else if (!isLast)
      label = 'CONTINUE';
    else
      label = 'FINISH';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: CyberButton(
        label: label,
        onPressed: _isAnswerChecked || _canCheck() ? _handleCheck2 : () {},
      ),
    );
  }

  void _handleCheck2() {
    if (!_isAnswerChecked) {
      _handleCheck();
    } else {
      _handleContinue();
    }
  }

  // ── UTILS ──────────────────────────────────────────────────────────────────
  String _questionTypeLabel(QuestionType t) {
    switch (t) {
      case QuestionType.multipleChoice:
        return 'PICK ONE';
      case QuestionType.trueFalse:
        return 'TRUE OR FALSE';
      case QuestionType.fillBlank:
        return 'FILL THE BLANK';
      case QuestionType.tapCorrect:
        return 'TAP CORRECT';
      case QuestionType.dragDrop:
        return 'DRAG & DROP';
      case QuestionType.reorderCode:
        return 'REORDER CODE';
    }
  }

  Color _typeColor(QuestionType t) {
    switch (t) {
      case QuestionType.multipleChoice:
        return AppColors.primary;
      case QuestionType.trueFalse:
        return Colors.purpleAccent;
      case QuestionType.fillBlank:
        return Colors.orangeAccent;
      case QuestionType.tapCorrect:
        return Colors.cyanAccent;
      case QuestionType.dragDrop:
        return Colors.pinkAccent;
      case QuestionType.reorderCode:
        return Colors.amberAccent;
    }
  }
}

// ── HELPER WIDGETS ─────────────────────────────────────────────────────────

class _BlankBox extends StatelessWidget {
  final String? value;
  final bool? isCorrect;
  const _BlankBox({this.value, this.isCorrect});

  @override
  Widget build(BuildContext context) {
    Color border = AppColors.primary.withOpacity(0.5);
    Color text = Colors.white;
    if (isCorrect == true) border = Colors.greenAccent;
    if (isCorrect == false) border = Colors.redAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      constraints: const BoxConstraints(minWidth: 70),
      decoration: BoxDecoration(
        color: border.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 2),
      ),
      child: Text(
        value ?? '     ',
        style: TextStyle(
          color: isCorrect == true
              ? Colors.greenAccent
              : (isCorrect == false ? Colors.redAccent : text),
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  final String label;
  final bool isDragging;
  final bool faded;
  const _TokenChip({
    required this.label,
    this.isDragging = false,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: faded ? 0.3 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDragging
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDragging ? AppColors.primary : Colors.white70,
            width: 2,
          ),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _CodeLineRow extends StatelessWidget {
  final int index;
  final String line;
  const _CodeLineRow({super.key, required this.index, required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, color: Colors.white24, size: 18),
          const SizedBox(width: 10),
          Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white24,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              line,
              style: const TextStyle(
                color: Color(0xFF79C0FF),
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── RESULT DIALOG ──────────────────────────────────────────────────────────────
class _ResultDialog extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final int xpEarned;
  final bool passed;
  final VoidCallback onContinue;

  const _ResultDialog({
    required this.correctCount,
    required this.totalCount,
    required this.xpEarned,
    required this.passed,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (correctCount / totalCount * 100).round();
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(passed ? '🎉' : '😅', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              passed ? 'Quest Complete!' : 'Keep Practising!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$correctCount / $totalCount correct  ($pct%)',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💎', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '+$xpEarned XP',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('earned!', style: TextStyle(color: Colors.amber)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: passed
                      ? AppColors.primary
                      : AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  passed ? 'Back to Map' : 'Try Again',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AskAISheet extends StatefulWidget {
  final String question;
  final String correctAnswer;
  final String userAnswer;
  final String? codeContext;

  const _AskAISheet({
    required this.question,
    required this.correctAnswer,
    required this.userAnswer,
    this.codeContext,
  });

  @override
  State<_AskAISheet> createState() => _AskAISheetState();
}

class _AskAISheetState extends State<_AskAISheet> {
  String _explanation = '';
  bool _isLoading = true;
  bool _hasError = false;

  // Anthropic API key — in production, move this to a secure backend endpoint
  // so it is never shipped inside the app binary.
  final String _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  final http.Client _client = http.Client();

  @override
  void initState() {
    super.initState();
    _fetchExplanation();
  }

  String _buildPrompt() {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are a friendly coding tutor inside a mobile app called CodeQuest.',
    );
    buffer.writeln(
      'A student just got a quiz question wrong. Explain why their answer is incorrect and why the correct answer is right.',
    );
    buffer.writeln(
      'Be concise (3–5 sentences max), encouraging, and use simple language. No markdown headers or bullet points — just plain conversational text.',
    );
    buffer.writeln();
    buffer.writeln('Question: ${widget.question}');
    if (widget.codeContext != null && widget.codeContext!.isNotEmpty) {
      buffer.writeln('Code context: ${widget.codeContext}');
    }
    buffer.writeln('Student answered: "${widget.userAnswer}"');
    buffer.writeln('Correct answer: "${widget.correctAnswer}"');
    return buffer.toString();
  }

  Future<void> _fetchExplanation() async {
    try {
      final response = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: json.encode({
              'model':
                  'claude-haiku-4-5-20251001', // fast + cheap, perfect for this
              'max_tokens': 256,
              'messages': [
                {'role': 'user', 'content': _buildPrompt()},
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = (data['content'] as List)
            .whereType<Map>()
            .where((b) => b['type'] == 'text')
            .map((b) => b['text'] as String)
            .join();
        setState(() {
          _explanation = text.trim();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Sheet takes up to 60% of screen height, scrolls if needed
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.60,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF13171F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.cyanAccent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Tutor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Divider
          const Divider(color: Colors.white10, height: 1),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2),
            SizedBox(height: 16),
            Text(
              'Thinking...',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.wifi_off, color: Colors.white24, size: 40),
            SizedBox(height: 12),
            Text(
              'Couldn\'t reach AI tutor.\nCheck your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // What the student answered vs correct
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _answerRow('Your answer', widget.userAnswer, Colors.redAccent),
              const SizedBox(height: 8),
              _answerRow(
                'Correct answer',
                widget.correctAnswer,
                Colors.greenAccent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // AI explanation
        Text(
          _explanation,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.65,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _answerRow(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '(no answer)' : value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
