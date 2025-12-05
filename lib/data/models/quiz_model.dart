import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quiz_model.g.dart';

// ============= QUIZ MODEL =============

@JsonSerializable()
class QuizModel extends Equatable {
  final String id;
  final String courseId;
  final String? moduleId;
  final String? lessonId;
  final String title;
  final String? description;
  final QuizType type;
  final int timeLimit; // en minutos, 0 = sin límite
  final int passingScore; // porcentaje mínimo para aprobar
  final int maxAttempts; // 0 = intentos ilimitados
  final bool shuffleQuestions;
  final bool shuffleAnswers;
  final bool showCorrectAnswers;
  final bool allowReview;
  final List<QuizQuestion> questions;
  final Map<String, dynamic>? metadata;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final int totalPoints;

  const QuizModel({
    required this.id,
    required this.courseId,
    this.moduleId,
    this.lessonId,
    required this.title,
    this.description,
    required this.type,
    this.timeLimit = 0,
    this.passingScore = 70,
    this.maxAttempts = 3,
    this.shuffleQuestions = false,
    this.shuffleAnswers = true,
    this.showCorrectAnswers = true,
    this.allowReview = true,
    required this.questions,
    this.metadata,
    this.availableFrom,
    this.availableUntil,
    required this.totalPoints,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) =>
      _$QuizModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuizModelToJson(this);

  /// Verifica si el quiz está disponible
  bool get isAvailable {
    final now = DateTime.now();
    if (availableFrom != null && now.isBefore(availableFrom!)) {
      return false;
    }
    if (availableUntil != null && now.isAfter(availableUntil!)) {
      return false;
    }
    return true;
  }

  /// Obtiene el mensaje de disponibilidad
  String get availabilityMessage {
    final now = DateTime.now();
    if (availableFrom != null && now.isBefore(availableFrom!)) {
      return 'Disponible a partir del ${_formatDate(availableFrom!)}';
    }
    if (availableUntil != null && now.isAfter(availableUntil!)) {
      return 'Este quiz ha expirado';
    }
    return 'Disponible ahora';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Obtiene el tiempo límite formateado
  String get formattedTimeLimit {
    if (timeLimit == 0) return 'Sin límite';
    if (timeLimit < 60) return '$timeLimit minutos';
    final hours = timeLimit ~/ 60;
    final minutes = timeLimit % 60;
    if (minutes == 0) return '$hours hora${hours > 1 ? 's' : ''}';
    return '$hours hora${hours > 1 ? 's' : ''} $minutes minutos';
  }

  /// Calcula el puntaje máximo posible
  int get maxScore => questions.fold(0, (sum, q) => sum + q.points);

  @override
  List<Object?> get props => [
        id,
        courseId,
        moduleId,
        lessonId,
        title,
        description,
        type,
        timeLimit,
        passingScore,
        maxAttempts,
        shuffleQuestions,
        shuffleAnswers,
        showCorrectAnswers,
        allowReview,
        questions,
        metadata,
        availableFrom,
        availableUntil,
        totalPoints,
      ];
}

// ============= QUIZ TYPE ENUM =============

enum QuizType {
  @JsonValue('practice')
  practice, // Práctica sin calificación
  @JsonValue('graded')
  graded, // Evaluación calificada
  @JsonValue('diagnostic')
  diagnostic, // Diagnóstico inicial
  @JsonValue('final')
  final, // Examen final
  @JsonValue('certification')
  certification, // Para certificación
}

// ============= QUIZ QUESTION MODEL =============

@JsonSerializable()
class QuizQuestion extends Equatable {
  final String id;
  final String question;
  final String? explanation;
  final QuestionType type;
  final List<QuizAnswer> answers;
  final int points;
  final String? imageUrl;
  final String? audioUrl;
  final String? videoUrl;
  final String? bibleReference;
  final Map<String, dynamic>? hints;
  final int? timeLimit; // Límite de tiempo por pregunta (segundos)

  const QuizQuestion({
    required this.id,
    required this.question,
    this.explanation,
    required this.type,
    required this.answers,
    this.points = 1,
    this.imageUrl,
    this.audioUrl,
    this.videoUrl,
    this.bibleReference,
    this.hints,
    this.timeLimit,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$QuizQuestionToJson(this);

  /// Obtiene las respuestas correctas
  List<QuizAnswer> get correctAnswers =>
      answers.where((a) => a.isCorrect).toList();

  /// Verifica si la respuesta es correcta
  bool isAnswerCorrect(List<String> selectedAnswerIds) {
    final correctIds = correctAnswers.map((a) => a.id).toSet();
    final selectedIds = selectedAnswerIds.toSet();

    switch (type) {
      case QuestionType.singleChoice:
        return selectedIds.length == 1 && correctIds.contains(selectedIds.first);
      case QuestionType.multipleChoice:
        return selectedIds.length == correctIds.length &&
            selectedIds.containsAll(correctIds);
      case QuestionType.trueFalse:
        return selectedIds.length == 1 && correctIds.contains(selectedIds.first);
      case QuestionType.ordering:
        // Para preguntas de ordenamiento, verificar el orden
        if (selectedIds.length != answers.length) return false;
        for (int i = 0; i < selectedAnswerIds.length; i++) {
          if (selectedAnswerIds[i] != answers[i].id) return false;
        }
        return true;
      case QuestionType.matching:
        // Lógica específica para emparejamiento
        return selectedIds.length == correctIds.length &&
            selectedIds.containsAll(correctIds);
      case QuestionType.fillInTheBlank:
        // Para completar espacios, verificar texto exacto
        return selectedIds.length == correctIds.length &&
            selectedIds.containsAll(correctIds);
    }
  }

  /// Calcula el puntaje obtenido
  double calculateScore(List<String> selectedAnswerIds) {
    if (isAnswerCorrect(selectedAnswerIds)) {
      return points.toDouble();
    }

    // Para respuestas parciales en múltiple opción
    if (type == QuestionType.multipleChoice) {
      final correctIds = correctAnswers.map((a) => a.id).toSet();
      final selectedIds = selectedAnswerIds.toSet();
      final correctSelected = selectedIds.intersection(correctIds).length;
      final incorrectSelected = selectedIds.difference(correctIds).length;

      if (correctSelected > 0 && incorrectSelected == 0) {
        return (correctSelected / correctIds.length) * points;
      }
    }

    return 0;
  }

  @override
  List<Object?> get props => [
        id,
        question,
        explanation,
        type,
        answers,
        points,
        imageUrl,
        audioUrl,
        videoUrl,
        bibleReference,
        hints,
        timeLimit,
      ];
}

// ============= QUESTION TYPE ENUM =============

enum QuestionType {
  @JsonValue('single_choice')
  singleChoice,
  @JsonValue('multiple_choice')
  multipleChoice,
  @JsonValue('true_false')
  trueFalse,
  @JsonValue('ordering')
  ordering,
  @JsonValue('matching')
  matching,
  @JsonValue('fill_in_the_blank')
  fillInTheBlank,
}

// ============= QUIZ ANSWER MODEL =============

@JsonSerializable()
class QuizAnswer extends Equatable {
  final String id;
  final String text;
  final bool isCorrect;
  final String? imageUrl;
  final int? order; // Para preguntas de ordenamiento
  final String? matchId; // Para preguntas de emparejamiento

  const QuizAnswer({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.imageUrl,
    this.order,
    this.matchId,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) =>
      _$QuizAnswerFromJson(json);

  Map<String, dynamic> toJson() => _$QuizAnswerToJson(this);

  @override
  List<Object?> get props => [id, text, isCorrect, imageUrl, order, matchId];
}

// ============= QUIZ ATTEMPT MODEL =============

@JsonSerializable()
class QuizAttempt extends Equatable {
  final String id;
  final String quizId;
  final String userId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, List<String>> answers; // questionId -> answerIds
  final double score;
  final double percentage;
  final bool passed;
  final int attemptNumber;
  final Duration? timeTaken;
  final QuizAttemptStatus status;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.startedAt,
    this.completedAt,
    required this.answers,
    required this.score,
    required this.percentage,
    required this.passed,
    required this.attemptNumber,
    this.timeTaken,
    required this.status,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) =>
      _$QuizAttemptFromJson(json);

  Map<String, dynamic> toJson() => _$QuizAttemptToJson(this);

  /// Obtiene el tiempo formateado
  String get formattedTimeTaken {
    if (timeTaken == null) return 'N/A';
    final minutes = timeTaken!.inMinutes;
    final seconds = timeTaken!.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Obtiene la fecha formateada
  String get formattedDate {
    final date = completedAt ?? startedAt;
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  QuizAttempt copyWith({
    String? id,
    String? quizId,
    String? userId,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, List<String>>? answers,
    double? score,
    double? percentage,
    bool? passed,
    int? attemptNumber,
    Duration? timeTaken,
    QuizAttemptStatus? status,
  }) {
    return QuizAttempt(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      answers: answers ?? this.answers,
      score: score ?? this.score,
      percentage: percentage ?? this.percentage,
      passed: passed ?? this.passed,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      timeTaken: timeTaken ?? this.timeTaken,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        quizId,
        userId,
        startedAt,
        completedAt,
        answers,
        score,
        percentage,
        passed,
        attemptNumber,
        timeTaken,
        status,
      ];
}

// ============= QUIZ ATTEMPT STATUS ENUM =============

enum QuizAttemptStatus {
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('abandoned')
  abandoned,
  @JsonValue('timeout')
  timeout,
}

// ============= QUIZ STATISTICS MODEL =============

@JsonSerializable()
class QuizStatistics extends Equatable {
  final String quizId;
  final int totalAttempts;
  final double averageScore;
  final double averagePercentage;
  final double passRate;
  final Duration averageTimeTaken;
  final QuizAttempt? bestAttempt;
  final QuizAttempt? lastAttempt;
  final Map<String, QuestionStatistics> questionStats;

  const QuizStatistics({
    required this.quizId,
    required this.totalAttempts,
    required this.averageScore,
    required this.averagePercentage,
    required this.passRate,
    required this.averageTimeTaken,
    this.bestAttempt,
    this.lastAttempt,
    required this.questionStats,
  });

  factory QuizStatistics.fromJson(Map<String, dynamic> json) =>
      _$QuizStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$QuizStatisticsToJson(this);

  @override
  List<Object?> get props => [
        quizId,
        totalAttempts,
        averageScore,
        averagePercentage,
        passRate,
        averageTimeTaken,
        bestAttempt,
        lastAttempt,
        questionStats,
      ];
}

// ============= QUESTION STATISTICS MODEL =============

@JsonSerializable()
class QuestionStatistics extends Equatable {
  final String questionId;
  final int timesAnswered;
  final int timesCorrect;
  final double correctPercentage;
  final Map<String, int> answerDistribution;

  const QuestionStatistics({
    required this.questionId,
    required this.timesAnswered,
    required this.timesCorrect,
    required this.correctPercentage,
    required this.answerDistribution,
  });

  factory QuestionStatistics.fromJson(Map<String, dynamic> json) =>
      _$QuestionStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$QuestionStatisticsToJson(this);

  @override
  List<Object?> get props => [
        questionId,
        timesAnswered,
        timesCorrect,
        correctPercentage,
        answerDistribution,
      ];
}