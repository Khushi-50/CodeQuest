// quest_provider.dart
// Fixes:
//   1. Progress (completed subtopics) persisted to SharedPreferences — survives hot restart
//   2. Multi-language support — user can enroll in and switch between languages
//   3. Demo chapters cover all 6 question types for every language
//   4. Per-language completed-set stored and restored correctly

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/quest_models.dart';
import '../models/user_model.dart';
import '../screens/quiz_screen.dart';

// ── SharedPrefs keys ──────────────────────────────────────────────────────────
const _kXp = 'local_xp';
const _kStreak = 'local_streak';
const _kHearts = 'local_hearts';
const _kLastActiveDate = 'last_active_date';
const _kQuestionsAnsweredToday = 'questions_answered_today';
const _kCurrentLanguage = 'current_language';
const _kEnrolledLanguages = 'enrolled_languages';
String _kCompleted(String lang) => 'completed_$lang';

// ── Language catalogue ────────────────────────────────────────────────────────
class LanguageInfo {
  final String id;
  final String name;
  final String emoji;
  final String tagline;
  const LanguageInfo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tagline,
  });
}

const kAvailableLanguages = [
  LanguageInfo(
    id: 'c-programming',
    name: 'C',
    emoji: '⚙️',
    tagline: 'The Machine-Master',
  ),
  LanguageInfo(
    id: 'python',
    name: 'Python',
    emoji: '🐍',
    tagline: 'The Easy-Talker',
  ),
  LanguageInfo(
    id: 'javascript',
    name: 'JavaScript',
    emoji: '🌐',
    tagline: 'The Web-Wizard',
  ),
  LanguageInfo(id: 'cpp', name: 'C++', emoji: '⚡', tagline: 'The Speed-Demon'),
];

// ─────────────────────────────────────────────────────────────────────────────

class QuestProvider extends ChangeNotifier with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();

  QuestProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached)
      _syncToDatabase();
  }

  // ── STATE ─────────────────────────────────────────────────────────────────
  UserModel? _user;
  int _xp = 0, _streak = 0, _hearts = 5, _questionsAnsweredToday = 0;
  bool _didActivityToday = false, _isLoading = false;
  String _currentLanguage = 'c-programming';
  List<String> _enrolledLanguages = ['c-programming'];
  List<FullChapterModel> _courseMap = [];
  List<QuizQuestion> _currentQuestions = [];

  /// Completed subtopics, keyed by language slug
  final Map<String, Set<String>> _completedByLang = {};

  // ── GETTERS ───────────────────────────────────────────────────────────────
  UserModel? get user => _user;
  int get xp => _xp;
  int get streak => _streak;
  int get hearts => _hearts;
  int get questionsAnsweredToday => _questionsAnsweredToday;
  bool get didActivityToday => _didActivityToday;
  bool get isLoading => _isLoading;
  String get currentLanguage => _currentLanguage;
  List<String> get enrolledLanguages => List.unmodifiable(_enrolledLanguages);
  List<FullChapterModel> get courseMap => _courseMap;
  List<QuizQuestion> get currentQuestions => _currentQuestions;

  LanguageInfo get currentLanguageInfo => kAvailableLanguages.firstWhere(
    (l) => l.id == _currentLanguage,
    orElse: () => kAvailableLanguages.first,
  );

  Set<String> get _localCompleted => _completedByLang[_currentLanguage] ?? {};

  List<String> get _allSubtopicIds =>
      _courseMap.expand((c) => c.subtopics).map((s) => s.subtopicId).toList();

  // ── LOAD ──────────────────────────────────────────────────────────────────
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners();
    await _loadFromPrefs();
    try {
      final u = await _apiService.getProfile();
      if (u != null) {
        _user = u;
        if (u.xp >= _xp) _xp = u.xp;
      }
    } catch (_) {}
    await _loadCourseMap(_currentLanguage);
    _updateStreakFromDate();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCourseMap(String lang) async {
    List<FullChapterModel> map = [];
    try {
      for (int i = 1; i <= 10; i++) {
        final ch = await _apiService.getChapter(lang, i);
        if (ch != null) map.add(ch);
      }
    } catch (_) {}
    _courseMap = map.isEmpty ? [_localChapter(lang)] : map;
  }

  // ── LANGUAGE MANAGEMENT ───────────────────────────────────────────────────
  Future<void> enrollLanguage(String langId) async {
    if (!_enrolledLanguages.contains(langId)) {
      _enrolledLanguages.add(langId);
      _completedByLang[langId] ??= {};
      await _saveToPrefs();
    }
    await switchLanguage(langId);
  }

  Future<void> switchLanguage(String langId) async {
    if (_currentLanguage == langId && _courseMap.isNotEmpty) return;
    _currentLanguage = langId;
    if (!_enrolledLanguages.contains(langId))
      _enrolledLanguages.insert(0, langId);
    _isLoading = true;
    notifyListeners();
    await _loadCourseMap(langId);
    await _saveToPrefs();
    _isLoading = false;
    notifyListeners();
  }

  // ── PREFS ─────────────────────────────────────────────────────────────────
  Future<void> _loadFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    _xp = p.getInt(_kXp) ?? 0;
    _streak = p.getInt(_kStreak) ?? 0;
    _hearts = p.getInt(_kHearts) ?? 5;
    _questionsAnsweredToday = p.getInt(_kQuestionsAnsweredToday) ?? 0;
    _currentLanguage = p.getString(_kCurrentLanguage) ?? 'c-programming';
    _enrolledLanguages =
        p.getStringList(_kEnrolledLanguages) ?? ['c-programming'];

    final lastActive = p.getString(_kLastActiveDate);
    final today = _todayStr();
    _didActivityToday = lastActive == today && _questionsAnsweredToday > 0;
    if (lastActive != null && lastActive != today) {
      _questionsAnsweredToday = 0;
      await p.setInt(_kQuestionsAnsweredToday, 0);
    }

    // Restore per-language completed sets
    for (final lang in _enrolledLanguages) {
      final raw = p.getString(_kCompleted(lang));
      _completedByLang[lang] = raw != null
          ? Set<String>.from(List<String>.from(json.decode(raw)))
          : {};
    }
  }

  Future<void> _saveToPrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kXp, _xp);
    await p.setInt(_kStreak, _streak);
    await p.setInt(_kHearts, _hearts);
    await p.setInt(_kQuestionsAnsweredToday, _questionsAnsweredToday);
    await p.setString(_kLastActiveDate, _todayStr());
    await p.setString(_kCurrentLanguage, _currentLanguage);
    await p.setStringList(_kEnrolledLanguages, _enrolledLanguages);
    // Persist every language's completed set
    for (final e in _completedByLang.entries) {
      await p.setString(_kCompleted(e.key), json.encode(e.value.toList()));
    }
  }

  Future<void> _syncToDatabase() async {
    try {
      await _apiService.syncStats(_xp, _streak);
    } catch (_) {}
  }

  void _updateStreakFromDate() async {
    final p = await SharedPreferences.getInstance();
    final last = p.getString(_kLastActiveDate);
    if (last != null && last != _todayStr() && last != _yesterdayStr()) {
      _streak = 0;
      await _saveToPrefs();
      notifyListeners();
    }
  }

  // ── UNLOCK LOGIC ──────────────────────────────────────────────────────────
  String getSubtopicStatus(String id) {
    final all = _allSubtopicIds;
    if (all.isEmpty) return 'locked';
    final idx = all.indexOf(id);
    if (idx == -1) return 'locked';
    if (idx == 0) return _isDone(id) ? 'completed' : 'unlocked';
    if (!_isDone(all[idx - 1])) return 'locked';
    return _isDone(id) ? 'completed' : 'unlocked';
  }

  bool _isDone(String id) {
    if (_localCompleted.contains(id)) return true;
    return _user?.progress.any(
          (p) => p.questionId == id && p.status == 'completed',
        ) ??
        false;
  }

  // ── START QUIZ ────────────────────────────────────────────────────────────
  Future<void> startQuiz(
    BuildContext ctx,
    String subtopicId,
    String name,
    List<QuizQuestion> fallback, {
    int quizLength = 7,
  }) async {
    _isLoading = true;
    notifyListeners();
    List<QuizQuestion> qs = [];
    try {
      final fetched = await _apiService.getSubtopicQuestions(subtopicId);
      qs = fetched.isNotEmpty ? fetched : fallback;
    } catch (_) {
      qs = fallback;
    }
    if (qs.length > quizLength) qs = qs.take(quizLength).toList();
    _currentQuestions = qs;
    _isLoading = false;
    notifyListeners();
    if (_currentQuestions.isNotEmpty && ctx.mounted) {
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            questions: _currentQuestions,
            title: name,
            subtopicId: subtopicId,
          ),
        ),
      );
    }
  }

  // ── COMPLETE SUBTOPIC ─────────────────────────────────────────────────────
  Future<void> completeSubtopic(String id, bool correct, int xpEarned) async {
    if (correct) {
      _completedByLang[_currentLanguage] ??= {};
      _completedByLang[_currentLanguage]!.add(id); // ← the key fix
      _xp += xpEarned;
      if (_streak == 0) _streak = 1;
      _didActivityToday = true;
      _questionsAnsweredToday += 7;
    } else {
      if (_hearts > 0) _hearts--; // ← add this
    }
    notifyListeners();
    await _saveToPrefs(); // persists completed set immgit ediately
    _syncToDatabase();
    _apiService.syncProgress(id, correct).then((_) async {
      try {
        final u = await _apiService.getProfile();
        if (u != null) {
          _user = u;
          if (u.xp > _xp) {
            _xp = u.xp;
            await _saveToPrefs();
          }
        }
      } catch (_) {}
      notifyListeners();
    });
  }

  // ── AUTH ──────────────────────────────────────────────────────────────────
  Future<bool> handleLogin(String email, String pw) async {
    _isLoading = true;
    notifyListeners();
    final tok = await _apiService.login(email, pw);
    if (tok != null) await loadUserData();
    _isLoading = false;
    notifyListeners();
    return tok != null;
  }

  Future<void> logout() async {
    await (const FlutterSecureStorage()).delete(key: 'auth_token');
    (await SharedPreferences.getInstance()).clear();
    _user = null;
    _xp = 0;
    _streak = 0;
    _hearts = 5;
    _questionsAnsweredToday = 0;
    _didActivityToday = false;
    _completedByLang.clear();
    _enrolledLanguages = ['c-programming'];
    _currentLanguage = 'c-programming';
    _courseMap = [];
    notifyListeners();
  }

  // ── DATE HELPERS ──────────────────────────────────────────────────────────
  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayStr() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOCAL DEMO DATA — all 6 question types, per language
  // ══════════════════════════════════════════════════════════════════════════
  FullChapterModel _localChapter(String lang) {
    switch (lang) {
      case 'python':
        return _pyChapter();
      case 'javascript':
        return _jsChapter();
      case 'cpp':
        return _cppChapter();
      default:
        return _cChapter();
    }
  }

  // ── C ─────────────────────────────────────────────────────────────────────
  FullChapterModel _cChapter() => FullChapterModel(
    course: 'C Programming',
    chapter: 1,
    chapterName: 'The Skeleton',
    subtopics: [
      _sub('c-1', 'The Entry Point', [
        _mcq(
          1,
          'Every C program starts from:',
          ['start()', 'main()', 'run()', 'init()'],
          'main()',
          5,
        ),
        _tf(2, 'A C program can have more than one main()', 'False', 5),
        _fill(
          3,
          'Complete the entry-point signature:',
          'main',
          7,
          'int ___(void) {\n    return 0;\n}',
        ),
        _drag(
          4,
          'Build a valid C entry point:',
          'int main return',
          10,
          '___ ___(void) {\n    ___ 0;\n}',
          ['int', 'main', 'return', 'void', 'start', 'char'],
        ),
        _tap(
          5,
          'Which return type does main() use?',
          ['void', 'int', 'char', 'float'],
          'int',
          5,
        ),
        _reorder(
          6,
          'Arrange into a valid Hello World:',
          10,
          '#include <stdio.h>\nint main(void) {\n    printf("Hello");\n    return 0;\n}',
          [
            '    return 0;',
            '#include <stdio.h>',
            '    printf("Hello");',
            'int main(void) {',
            '}',
          ],
        ),
        _mcq(
          7,
          'main() returning 0 means:',
          ['Crash', 'Success', 'Compile error'],
          'Success',
          7,
        ),
      ]),
      _sub('c-2', 'Curly Braces {}', [
        _mcq(
          1,
          'Curly braces {} define a:',
          ['Comment', 'Code block', 'String', 'Array'],
          'Code block',
          5,
        ),
        _tf(2, 'Every opening { must have a matching }', 'True', 5),
        _fill(
          3,
          'Close the function with the missing brace:',
          '}',
          7,
          'int main(void) {\n    return 0;\n___',
        ),
        _tap(
          4,
          'Variables declared inside {} are:',
          ['Global', 'Local to that block', 'Static', 'Volatile'],
          'Local to that block',
          7,
        ),
        _reorder(
          5,
          'Reorder into a valid function:',
          10,
          'void greet() {\n    // code\n}',
          ['    // code', '}', 'void greet() {'],
        ),
        _mcq(
          6,
          'Missing a closing brace causes:',
          ['Runtime crash', 'Compile error', 'Warning'],
          'Compile error',
          5,
        ),
        _drag(
          7,
          'Build a void function shell:',
          'void { }',
          10,
          '___ greet() ___ ___',
          ['void', 'int', '{', '}', 'return', '('],
        ),
      ]),
      _sub('c-3', '#include & Headers', [
        _mcq(
          1,
          'Header needed for printf():',
          ['stdlib.h', 'stdio.h', 'math.h', 'string.h'],
          'stdio.h',
          5,
        ),
        _drag(
          2,
          'Build the correct #include:',
          '#include stdio.h',
          10,
          '___ <___>',
          ['#include', 'stdio.h', 'printf', 'import', 'math.h'],
        ),
        _tf(3, '#include directives appear before main()', 'True', 5),
        _fill(
          4,
          'Complete the include directive:',
          '<stdio.h>',
          7,
          '#include ___',
        ),
        _tap(
          5,
          'Which symbol starts a preprocessor directive?',
          ['@', '#', '&', '*'],
          '#',
          5,
        ),
        _reorder(
          6,
          'Arrange to include stdio and call printf:',
          10,
          '#include <stdio.h>\nint main() {\n    printf("Hi");\n    return 0;\n}',
          [
            '    return 0;',
            '#include <stdio.h>',
            '    printf("Hi");',
            'int main() {',
            '}',
          ],
        ),
        _tf(7, 'You can write your own .h header files', 'True', 7),
      ]),
      SubtopicFolder(
        subtopicId: 'c-4',
        subtopicName: 'Variables & Types',
        quizzes: [],
      ),
    ],
  );

  // ── PYTHON ────────────────────────────────────────────────────────────────
  FullChapterModel _pyChapter() => FullChapterModel(
    course: 'Python',
    chapter: 1,
    chapterName: 'Python Basics',
    subtopics: [
      _sub('py-1', 'Print & Variables', [
        _mcq(
          1,
          'Output function in Python:',
          ['echo()', 'console.log()', 'print()', 'write()'],
          'print()',
          5,
        ),
        _tf(2, 'Python uses indentation instead of curly braces', 'True', 5),
        _fill(3, 'Complete Hello World:', 'print', 7, '___("Hello, World!")'),
        _drag(
          4,
          'Build a variable assignment:',
          'name = "Quest"',
          10,
          '___ ___ ___',
          ['name', '=', '"Quest"', 'int', 'var', 'let'],
        ),
        _tap(
          5,
          'Valid Python variable name?',
          ['2name', 'my_name', 'my-name', 'class'],
          'my_name',
          5,
        ),
        _reorder(
          6,
          'Reorder to print a variable:',
          10,
          'name = "Aryan"\nprint(name)',
          ['print(name)', 'name = "Aryan"'],
        ),
        _tf(7, 'Python is dynamically typed', 'True', 7),
      ]),
      _sub('py-2', 'If / Else', [
        _mcq(
          1,
          'Python keyword for conditions:',
          ['switch', 'if', 'when', 'case'],
          'if',
          5,
        ),
        _drag(
          2,
          'Build a Python if-else:',
          'if else',
          10,
          '___ x > 0:\n    print("pos")\n___:\n    print("neg")',
          ['if', 'else', 'elif', 'while', 'for', 'then'],
        ),
        _tap(
          3,
          'elif stands for:',
          ['else if', 'end if', 'elif fn', 'error loop'],
          'else if',
          5,
        ),
        _tf(4, 'Python requires a colon after if condition', 'True', 5),
        _fill(
          5,
          'Complete the comparison:',
          '>',
          7,
          'if age ___ 18:\n    print("Adult")',
        ),
        _reorder(
          6,
          'Reorder into a valid if-else:',
          10,
          'x = 10\nif x > 5:\n    print("big")\nelse:\n    print("small")',
          [
            'else:',
            '    print("big")',
            'x = 10',
            'if x > 5:',
            '    print("small")',
          ],
        ),
        _tf(7, 'pass is a placeholder in empty Python blocks', 'True', 5),
      ]),
      SubtopicFolder(subtopicId: 'py-3', subtopicName: 'Loops', quizzes: []),
    ],
  );

  // ── JAVASCRIPT ────────────────────────────────────────────────────────────
  FullChapterModel _jsChapter() => FullChapterModel(
    course: 'JavaScript',
    chapter: 1,
    chapterName: 'JS Fundamentals',
    subtopics: [
      _sub('js-1', 'Variables & Types', [
        _mcq(
          1,
          'Block-scoped variable keyword:',
          ['var', 'let', 'def', 'dim'],
          'let',
          5,
        ),
        _tf(2, 'const variables can be reassigned', 'False', 5),
        _drag(3, 'Declare a constant:', 'const PI 3.14', 10, '___ ___ = ___', [
          'const',
          'PI',
          '3.14',
          'let',
          'var',
          'x',
        ]),
        _fill(
          4,
          'Complete the console output:',
          'console.log',
          7,
          '___("Hello JS!");',
        ),
        _tap(5, 'Loose equality operator:', ['===', '==', '=', '!='], '==', 5),
        _reorder(
          6,
          'Reorder into a valid JS declaration:',
          10,
          'let name = "Quest";\nconsole.log(name);',
          ['console.log(name);', 'let name = "Quest";'],
        ),
        _tf(7, 'typeof null returns "object" in JS', 'True', 7),
      ]),
      SubtopicFolder(
        subtopicId: 'js-2',
        subtopicName: 'Functions',
        quizzes: [],
      ),
    ],
  );

  // ── C++ ───────────────────────────────────────────────────────────────────
  FullChapterModel _cppChapter() => FullChapterModel(
    course: 'C++',
    chapter: 1,
    chapterName: 'C++ Essentials',
    subtopics: [
      _sub('cpp-1', 'Hello C++', [
        _mcq(
          1,
          'C++ output uses:',
          ['printf', 'cout', 'print', 'System.out'],
          'cout',
          5,
        ),
        _tf(2, 'C++ is fully backward-compatible with C', 'False', 5),
        _fill(
          3,
          'Complete the output line:',
          'cout',
          7,
          '___ << "Hello C++" << endl;',
        ),
        _drag(
          4,
          'Write a C++ output statement:',
          'cout "Hi"',
          10,
          '___ << ___',
          ['cout', 'cin', '"Hi"', 'endl', '<<', '>>'],
        ),
        _tap(
          5,
          'Namespace commonly used in C++:',
          ['std', 'sys', 'main', 'io'],
          'std',
          5,
        ),
        _reorder(
          6,
          'Reorder into a valid C++ Hello World:',
          10,
          '#include <iostream>\nusing namespace std;\nint main() {\n    cout << "Hello";\n    return 0;\n}',
          [
            '    return 0;',
            '#include <iostream>',
            '    cout << "Hello";',
            'using namespace std;',
            'int main() {',
            '}',
          ],
        ),
        _tf(7, 'cin is used for standard input in C++', 'True', 7),
      ]),
      SubtopicFolder(
        subtopicId: 'cpp-2',
        subtopicName: 'OOP Basics',
        quizzes: [],
      ),
    ],
  );

  // ── Question factory helpers ───────────────────────────────────────────────
  SubtopicFolder _sub(String id, String name, List<QuizQuestion> qs) =>
      SubtopicFolder(
        subtopicId: id,
        subtopicName: name,
        quizzes: [
          QuizSubtopic(quizId: '$id-q', quizTitle: name, questions: qs),
        ],
      );

  QuizQuestion _mcq(int id, String q, List<String> opts, String ans, int xp) =>
      QuizQuestion(
        id: id,
        question: q,
        options: opts,
        answer: ans,
        xp: xp,
        questionType: QuestionType.multipleChoice,
      );

  QuizQuestion _tf(int id, String q, String ans, int xp) => QuizQuestion(
    id: id,
    question: q,
    options: ['True', 'False'],
    answer: ans,
    xp: xp,
    questionType: QuestionType.trueFalse,
  );

  QuizQuestion _fill(int id, String q, String ans, int xp, String template) =>
      QuizQuestion(
        id: id,
        question: q,
        options: [],
        answer: ans,
        xp: xp,
        questionType: QuestionType.fillBlank,
        codeTemplate: template,
      );

  QuizQuestion _drag(
    int id,
    String q,
    String ans,
    int xp,
    String template,
    List<String> tokens,
  ) => QuizQuestion(
    id: id,
    question: q,
    options: [],
    answer: ans,
    xp: xp,
    questionType: QuestionType.dragDrop,
    codeTemplate: template,
    dragTokens: tokens,
  );

  QuizQuestion _tap(int id, String q, List<String> opts, String ans, int xp) =>
      QuizQuestion(
        id: id,
        question: q,
        options: opts,
        answer: ans,
        xp: xp,
        questionType: QuestionType.tapCorrect,
      );

  QuizQuestion _reorder(
    int id,
    String q,
    int xp,
    String ans,
    List<String> lines,
  ) => QuizQuestion(
    id: id,
    question: q,
    options: [],
    answer: ans,
    xp: xp,
    questionType: QuestionType.reorderCode,
    codeLines: lines,
  );
}
