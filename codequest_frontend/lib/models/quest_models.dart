// quest_models.dart
// All IDs are Strings because MongoDB ObjectIds come back as strings from the API.

/// Supported question types — extend freely
enum QuestionType {
  multipleChoice, // classic A/B/C/D tap
  fillBlank, // type the missing word
  dragDrop, // drag code tokens into blanks
  tapCorrect, // tap the ONE correct word from inline options
  reorderCode, // sort shuffled lines into correct order
  trueFalse, // binary choice
}

class QuizQuestion {
  final int id;
  final String question;
  final List<String> options;
  final String answer;
  final int xp;

  // ── NEW FIELDS ──────────────────────────────────────────────────────────────
  /// Which widget style to render. Defaults to multipleChoice so old data works.
  final QuestionType questionType;

  /// For fillBlank / dragDrop: the sentence with '___' where the answer goes.
  /// e.g. "Every C program must have a ___ function."
  final String? codeTemplate;

  /// For dragDrop: the pool of draggable tokens (correct + distractors).
  /// If null, derived from [options].
  final List<String>? dragTokens;

  /// For reorderCode: the shuffled lines to reorder.
  /// [answer] should be the correct joined string (lines joined by '\n').
  final List<String>? codeLines;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.answer,
    required this.xp,
    this.questionType = QuestionType.multipleChoice,
    this.codeTemplate,
    this.dragTokens,
    this.codeLines,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    // Parse question type — gracefully falls back to multipleChoice
    QuestionType type = QuestionType.multipleChoice;
    final rawType = json['question_type'] ?? json['type'];
    if (rawType != null) {
      switch (rawType.toString()) {
        case 'fill_blank':
          type = QuestionType.fillBlank;
          break;
        case 'drag_drop':
          type = QuestionType.dragDrop;
          break;
        case 'tap_correct':
          type = QuestionType.tapCorrect;
          break;
        case 'reorder_code':
          type = QuestionType.reorderCode;
          break;
        case 'true_false':
          type = QuestionType.trueFalse;
          break;
        default:
          type = QuestionType.multipleChoice;
      }
    }

    return QuizQuestion(
      id: json['question_number'] ?? json['id'] ?? 0,
      question: json['question_text'] ?? json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      answer: json['correct_answer'] ?? json['answer'] ?? '',
      xp: json['xp_value'] ?? json['xp'] ?? 0,
      questionType: type,
      codeTemplate: json['code_template'],
      dragTokens: json['drag_tokens'] != null
          ? List<String>.from(json['drag_tokens'])
          : null,
      codeLines: json['code_lines'] != null
          ? List<String>.from(json['code_lines'])
          : null,
    );
  }
}

class QuizSubtopic {
  final String quizId;
  final String quizTitle;
  final List<QuizQuestion> questions;

  QuizSubtopic({
    required this.quizId,
    required this.quizTitle,
    required this.questions,
  });

  factory QuizSubtopic.fromJson(Map<String, dynamic> json) {
    final rawQuestions = (json['questions'] ?? json['quizzes'] ?? []) as List;

    return QuizSubtopic(
      quizId: json['id']?.toString() ?? json['quiz_id']?.toString() ?? '0',
      quizTitle: json['quiz_title'] ?? '',
      questions: rawQuestions
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubtopicFolder {
  final String subtopicId;
  final String subtopicName;
  final List<QuizSubtopic> quizzes;

  SubtopicFolder({
    required this.subtopicId,
    required this.subtopicName,
    required this.quizzes,
  });

  factory SubtopicFolder.fromJson(Map<String, dynamic> json) {
    return SubtopicFolder(
      subtopicId:
          json['id']?.toString() ?? json['subtopic_id']?.toString() ?? '0',
      subtopicName: json['subtopic_name'] ?? '',
      quizzes: (json['quizzes'] as List? ?? [])
          .map((z) => QuizSubtopic.fromJson(z as Map<String, dynamic>))
          .toList(),
    );
  }

  List<QuizQuestion> get allQuestions =>
      quizzes.expand((q) => q.questions).toList();
}

class FullChapterModel {
  final String course;
  final int chapter;
  final String chapterName;
  final List<SubtopicFolder> subtopics;

  FullChapterModel({
    required this.course,
    required this.chapter,
    required this.chapterName,
    required this.subtopics,
  });

  factory FullChapterModel.fromJson(Map<String, dynamic> json) {
    return FullChapterModel(
      course: json['course'] ?? '',
      chapter: json['chapter'] ?? 0,
      chapterName: json['chapter_name'] ?? '',
      subtopics: (json['subtopics'] as List? ?? [])
          .map((s) => SubtopicFolder.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
