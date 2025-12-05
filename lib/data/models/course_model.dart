import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'course_model.g.dart';

// ============= COURSE MODEL =============

@JsonSerializable()
class CourseModel extends Equatable {
  final int id;
  final String title;
  final String description;
  final String instructor;
  final String? thumbnailUrl;
  final CourseDifficulty difficulty;
  final int? durationHours;
  final double price;
  final bool isFree;
  final String? category;
  final List<String>? tags;
  final String? requirements;
  final String? whatYouLearn;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<LessonModel>? lessons;
  final CourseProgress? userProgress;

  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    this.thumbnailUrl,
    this.difficulty = CourseDifficulty.beginner,
    this.durationHours,
    this.price = 0,
    this.isFree = false,
    this.category,
    this.tags,
    this.requirements,
    this.whatYouLearn,
    this.isPublished = false,
    required this.createdAt,
    required this.updatedAt,
    this.lessons,
    this.userProgress,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) =>
      _$CourseModelFromJson(json);

  Map<String, dynamic> toJson() => _$CourseModelToJson(this);

  /// Obtiene el precio formateado
  String get formattedPrice {
    if (isFree) return 'GRATIS';
    return '\$${price.toStringAsFixed(2)}';
  }

  /// Obtiene la duración formateada
  String get formattedDuration {
    if (durationHours == null) return '';
    if (durationHours! < 1) {
      final minutes = (durationHours! * 60).round();
      return '$minutes minutos';
    }
    return '$durationHours ${durationHours == 1 ? 'hora' : 'horas'}';
  }

  /// Obtiene el número total de lecciones
  int get totalLessons => lessons?.length ?? 0;

  /// Verifica si el usuario está inscrito
  bool get isEnrolled => userProgress != null;

  /// Obtiene el progreso del usuario
  double get progressPercentage => userProgress?.progressPercentage ?? 0;

  /// Verifica si el curso está completado
  bool get isCompleted =>
      userProgress?.status == ProgressStatus.completed;

  /// Verifica si el curso está en progreso
  bool get isInProgress =>
      userProgress?.status == ProgressStatus.inProgress;

  /// Obtiene la lista de lo que aprenderás como lista
  List<String> get whatYouLearnList {
    if (whatYouLearn == null || whatYouLearn!.isEmpty) return [];
    return whatYouLearn!.split('\n').where((item) => item.isNotEmpty).toList();
  }

  /// Obtiene los requisitos como lista
  List<String> get requirementsList {
    if (requirements == null || requirements!.isEmpty) return [];
    return requirements!.split('\n').where((item) => item.isNotEmpty).toList();
  }

  CourseModel copyWith({
    int? id,
    String? title,
    String? description,
    String? instructor,
    String? thumbnailUrl,
    CourseDifficulty? difficulty,
    int? durationHours,
    double? price,
    bool? isFree,
    String? category,
    List<String>? tags,
    String? requirements,
    String? whatYouLearn,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LessonModel>? lessons,
    CourseProgress? userProgress,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      instructor: instructor ?? this.instructor,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      difficulty: difficulty ?? this.difficulty,
      durationHours: durationHours ?? this.durationHours,
      price: price ?? this.price,
      isFree: isFree ?? this.isFree,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      requirements: requirements ?? this.requirements,
      whatYouLearn: whatYouLearn ?? this.whatYouLearn,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lessons: lessons ?? this.lessons,
      userProgress: userProgress ?? this.userProgress,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        instructor,
        thumbnailUrl,
        difficulty,
        durationHours,
        price,
        isFree,
        category,
        tags,
        requirements,
        whatYouLearn,
        isPublished,
        createdAt,
        updatedAt,
        lessons,
        userProgress,
      ];
}

// ============= LESSON MODEL =============

@JsonSerializable()
class LessonModel extends Equatable {
  final int id;
  final int courseId;
  final String? sectionName;
  final int lessonOrder;
  final String title;
  final String? description;
  final String? videoUrl;
  final int? videoDuration; // en segundos
  final String? pdfUrl;
  final String? notesContent;
  final bool hasQuiz;
  final bool isFreePreview;
  final List<QuizQuestion>? quizQuestions;
  final LessonProgress? userProgress;

  const LessonModel({
    required this.id,
    required this.courseId,
    this.sectionName,
    required this.lessonOrder,
    required this.title,
    this.description,
    this.videoUrl,
    this.videoDuration,
    this.pdfUrl,
    this.notesContent,
    this.hasQuiz = false,
    this.isFreePreview = false,
    this.quizQuestions,
    this.userProgress,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) =>
      _$LessonModelFromJson(json);

  Map<String, dynamic> toJson() => _$LessonModelToJson(this);

  /// Obtiene la duración formateada
  String get formattedDuration {
    if (videoDuration == null) return '';

    final minutes = videoDuration! ~/ 60;
    final seconds = videoDuration! % 60;

    if (minutes > 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Verifica si la lección está completada
  bool get isCompleted => userProgress?.completed ?? false;

  /// Obtiene el progreso del video
  double get videoProgress {
    if (userProgress == null || videoDuration == null || videoDuration == 0) {
      return 0;
    }
    return (userProgress!.lastWatchedPosition / videoDuration!) * 100;
  }

  /// Verifica si tiene recursos descargables
  bool get hasResources => pdfUrl != null || notesContent != null;

  /// Verifica si el quiz fue aprobado
  bool get quizPassed {
    if (!hasQuiz || userProgress == null) return false;
    final score = userProgress!.quizScore ?? 0;
    final maxScore = userProgress!.quizMaxScore ?? 100;
    return (score / maxScore) >= 0.7; // 70% para aprobar
  }

  @override
  List<Object?> get props => [
        id,
        courseId,
        sectionName,
        lessonOrder,
        title,
        description,
        videoUrl,
        videoDuration,
        pdfUrl,
        notesContent,
        hasQuiz,
        isFreePreview,
        quizQuestions,
        userProgress,
      ];
}

// ============= QUIZ QUESTION =============

@JsonSerializable()
class QuizQuestion extends Equatable {
  final int id;
  final int lessonId;
  final String questionText;
  final QuestionType questionType;
  final List<String>? options;
  final String correctAnswer;
  final String? explanation;
  final int points;

  const QuizQuestion({
    required this.id,
    required this.lessonId,
    required this.questionText,
    this.questionType = QuestionType.multiple,
    this.options,
    required this.correctAnswer,
    this.explanation,
    this.points = 1,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$QuizQuestionToJson(this);

  /// Verifica si una respuesta es correcta
  bool isCorrect(String answer) {
    return answer.toLowerCase() == correctAnswer.toLowerCase();
  }

  @override
  List<Object?> get props => [
        id,
        lessonId,
        questionText,
        questionType,
        options,
        correctAnswer,
        explanation,
        points,
      ];
}

// ============= COURSE PROGRESS =============

@JsonSerializable()
class CourseProgress extends Equatable {
  final int id;
  final String userId;
  final int courseId;
  final int? currentLessonId;
  final ProgressStatus status;
  final double progressPercentage;
  final DateTime? completedAt;
  final DateTime startedAt;
  final DateTime updatedAt;
  final List<LessonProgress>? lessonProgress;

  const CourseProgress({
    required this.id,
    required this.userId,
    required this.courseId,
    this.currentLessonId,
    this.status = ProgressStatus.notStarted,
    this.progressPercentage = 0,
    this.completedAt,
    required this.startedAt,
    required this.updatedAt,
    this.lessonProgress,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) =>
      _$CourseProgressFromJson(json);

  Map<String, dynamic> toJson() => _$CourseProgressToJson(this);

  /// Obtiene el número de lecciones completadas
  int get completedLessons {
    if (lessonProgress == null) return 0;
    return lessonProgress!.where((lesson) => lesson.completed).length;
  }

  /// Obtiene el total de lecciones
  int get totalLessons => lessonProgress?.length ?? 0;

  /// Obtiene el tiempo total estudiado
  Duration get totalStudyTime {
    if (lessonProgress == null) return Duration.zero;

    int totalSeconds = 0;
    for (final lesson in lessonProgress!) {
      totalSeconds += lesson.lastWatchedPosition;
    }
    return Duration(seconds: totalSeconds);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        courseId,
        currentLessonId,
        status,
        progressPercentage,
        completedAt,
        startedAt,
        updatedAt,
        lessonProgress,
      ];
}

// ============= LESSON PROGRESS =============

@JsonSerializable()
class LessonProgress extends Equatable {
  final int id;
  final int courseProgressId;
  final int lessonId;
  final bool completed;
  final int lastWatchedPosition; // en segundos
  final int? quizScore;
  final int? quizMaxScore;
  final DateTime startedAt;
  final DateTime? completedAt;

  const LessonProgress({
    required this.id,
    required this.courseProgressId,
    required this.lessonId,
    this.completed = false,
    this.lastWatchedPosition = 0,
    this.quizScore,
    this.quizMaxScore,
    required this.startedAt,
    this.completedAt,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) =>
      _$LessonProgressFromJson(json);

  Map<String, dynamic> toJson() => _$LessonProgressToJson(this);

  /// Obtiene el porcentaje del quiz
  double get quizPercentage {
    if (quizScore == null || quizMaxScore == null || quizMaxScore == 0) {
      return 0;
    }
    return (quizScore! / quizMaxScore!) * 100;
  }

  /// Verifica si el quiz fue aprobado (70% o más)
  bool get quizPassed => quizPercentage >= 70;

  @override
  List<Object?> get props => [
        id,
        courseProgressId,
        lessonId,
        completed,
        lastWatchedPosition,
        quizScore,
        quizMaxScore,
        startedAt,
        completedAt,
      ];
}

// ============= ENUMS =============

enum CourseDifficulty {
  @JsonValue('BEGINNER')
  beginner,
  @JsonValue('INTERMEDIATE')
  intermediate,
  @JsonValue('ADVANCED')
  advanced,
}

extension CourseDifficultyExtension on CourseDifficulty {
  String get displayName {
    switch (this) {
      case CourseDifficulty.beginner:
        return 'Principiante';
      case CourseDifficulty.intermediate:
        return 'Intermedio';
      case CourseDifficulty.advanced:
        return 'Avanzado';
    }
  }

  String get icon {
    switch (this) {
      case CourseDifficulty.beginner:
        return '🟢';
      case CourseDifficulty.intermediate:
        return '🟡';
      case CourseDifficulty.advanced:
        return '🔴';
    }
  }
}

enum ProgressStatus {
  @JsonValue('NOT_STARTED')
  notStarted,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed,
}

extension ProgressStatusExtension on ProgressStatus {
  String get displayName {
    switch (this) {
      case ProgressStatus.notStarted:
        return 'No iniciado';
      case ProgressStatus.inProgress:
        return 'En progreso';
      case ProgressStatus.completed:
        return 'Completado';
    }
  }
}

enum QuestionType {
  @JsonValue('MULTIPLE')
  multiple,
  @JsonValue('BOOLEAN')
  boolean,
  @JsonValue('TEXT')
  text,
}

// ============= COURSE LIST RESPONSE =============

@JsonSerializable()
class CourseListResponse extends Equatable {
  final List<CourseModel> courses;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const CourseListResponse({
    required this.courses,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory CourseListResponse.fromJson(Map<String, dynamic> json) =>
      _$CourseListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CourseListResponseToJson(this);

  @override
  List<Object?> get props => [courses, total, page, pageSize, hasMore];
}