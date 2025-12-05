import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/course_model.dart';
import '../../data/repositories/course_repository.dart';

/// Provider del repositorio de cursos
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository();
});

/// Provider de la lista de cursos
final coursesProvider = StateNotifierProvider<CoursesNotifier, AsyncValue<List<CourseModel>>>((ref) {
  return CoursesNotifier(ref);
});

/// Notifier para la lista de cursos
class CoursesNotifier extends StateNotifier<AsyncValue<List<CourseModel>>> {
  final Ref _ref;
  late final CourseRepository _repository;

  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentCategory;
  CourseDifficulty? _currentDifficulty;

  CoursesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(courseRepositoryProvider);
  }

  /// Cargar cursos destacados
  Future<void> loadFeaturedCourses() async {
    state = const AsyncValue.loading();

    try {
      final courses = await _repository.getFeaturedCourses();
      state = AsyncValue.data(courses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Cargar todos los cursos
  Future<void> loadCourses({
    String? category,
    CourseDifficulty? difficulty,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    _currentCategory = category;
    _currentDifficulty = difficulty;

    try {
      final response = await _repository.getCourses(
        page: _currentPage,
        category: category,
        difficulty: difficulty,
      );

      if (refresh || state is! AsyncData) {
        state = AsyncValue.data(response.courses);
      } else {
        final currentCourses = state.value ?? [];
        state = AsyncValue.data([...currentCourses, ...response.courses]);
      }

      _hasMore = response.hasMore;
      _currentPage++;
    } catch (error, stackTrace) {
      if (refresh || state is! AsyncData) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  /// Cargar más cursos (paginación)
  Future<void> loadMore() async {
    if (!_hasMore || state is AsyncLoading) return;

    try {
      final response = await _repository.getCourses(
        page: _currentPage,
        category: _currentCategory,
        difficulty: _currentDifficulty,
      );

      final currentCourses = state.value ?? [];
      state = AsyncValue.data([...currentCourses, ...response.courses]);

      _hasMore = response.hasMore;
      _currentPage++;
    } catch (error) {
      // Mantener cursos actuales si falla la carga
    }
  }

  /// Refrescar lista de cursos
  Future<void> refresh() async {
    await loadCourses(
      category: _currentCategory,
      difficulty: _currentDifficulty,
      refresh: true,
    );
  }

  bool get hasMore => _hasMore;
}

/// Provider de mis cursos (inscritos)
final myCoursesProvider = StateNotifierProvider<MyCoursesNotifier, AsyncValue<List<CourseModel>>>((ref) {
  return MyCoursesNotifier(ref);
});

/// Notifier para mis cursos
class MyCoursesNotifier extends StateNotifier<AsyncValue<List<CourseModel>>> {
  final Ref _ref;
  late final CourseRepository _repository;

  MyCoursesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(courseRepositoryProvider);
  }

  /// Cargar cursos inscritos
  Future<void> loadMyCourses() async {
    state = const AsyncValue.loading();

    try {
      final courses = await _repository.getEnrolledCourses();
      state = AsyncValue.data(courses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Inscribirse en un curso
  Future<bool> enrollInCourse(int courseId) async {
    try {
      await _repository.enrollInCourse(courseId);

      // Recargar la lista de cursos
      await loadMyCourses();

      return true;
    } catch (error) {
      return false;
    }
  }
}

/// Provider para un curso específico
final courseDetailProvider = FutureProvider.family<CourseModel, int>((ref, courseId) async {
  final repository = ref.read(courseRepositoryProvider);
  return repository.getCourse(courseId);
});

/// Provider del progreso del curso
final courseProgressProvider = StateNotifierProvider.family<CourseProgressNotifier, AsyncValue<CourseProgress?>, int>((ref, courseId) {
  return CourseProgressNotifier(ref, courseId);
});

/// Notifier para el progreso del curso
class CourseProgressNotifier extends StateNotifier<AsyncValue<CourseProgress?>> {
  final Ref _ref;
  final int courseId;
  late final CourseRepository _repository;

  CourseProgressNotifier(this._ref, this.courseId) : super(const AsyncValue.loading()) {
    _repository = _ref.read(courseRepositoryProvider);
    loadProgress();
  }

  /// Cargar progreso del curso
  Future<void> loadProgress() async {
    state = const AsyncValue.loading();

    try {
      final progress = await _repository.getCourseProgress(courseId);
      state = AsyncValue.data(progress);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Actualizar progreso de la lección
  Future<void> updateLessonProgress({
    required int lessonId,
    required int position,
  }) async {
    try {
      await _repository.updateLessonProgress(
        lessonId: lessonId,
        position: position,
      );

      // Recargar progreso
      await loadProgress();
    } catch (error) {
      // Manejar error
    }
  }

  /// Completar lección
  Future<void> completeLesson(int lessonId) async {
    try {
      await _repository.completeLesson(lessonId);

      // Recargar progreso
      await loadProgress();
    } catch (error) {
      // Manejar error
    }
  }
}

/// Provider para el quiz de la lección
final lessonQuizProvider = StateNotifierProvider.family<LessonQuizNotifier, LessonQuizState, int>((ref, lessonId) {
  return LessonQuizNotifier(ref, lessonId);
});

/// Estado del quiz de la lección
class LessonQuizState {
  final List<QuizQuestion> questions;
  final Map<int, String> answers;
  final bool isSubmitted;
  final int? score;
  final int? maxScore;

  const LessonQuizState({
    this.questions = const [],
    this.answers = const {},
    this.isSubmitted = false,
    this.score,
    this.maxScore,
  });

  bool get isPassed => score != null && maxScore != null && (score! / maxScore!) >= 0.7;

  LessonQuizState copyWith({
    List<QuizQuestion>? questions,
    Map<int, String>? answers,
    bool? isSubmitted,
    int? score,
    int? maxScore,
  }) {
    return LessonQuizState(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
    );
  }
}

/// Notifier para el quiz de la lección
class LessonQuizNotifier extends StateNotifier<LessonQuizState> {
  final Ref _ref;
  final int lessonId;
  late final CourseRepository _repository;

  LessonQuizNotifier(this._ref, this.lessonId) : super(const LessonQuizState()) {
    _repository = _ref.read(courseRepositoryProvider);
    loadQuiz();
  }

  /// Cargar preguntas del quiz
  Future<void> loadQuiz() async {
    try {
      final questions = await _repository.getLessonQuiz(lessonId);

      final maxScore = questions.fold<int>(
        0,
        (sum, question) => sum + question.points,
      );

      state = state.copyWith(
        questions: questions,
        maxScore: maxScore,
      );
    } catch (error) {
      // Manejar error
    }
  }

  /// Responder pregunta
  void answerQuestion(int questionId, String answer) {
    if (state.isSubmitted) return;

    final newAnswers = Map<int, String>.from(state.answers);
    newAnswers[questionId] = answer;

    state = state.copyWith(answers: newAnswers);
  }

  /// Enviar quiz
  Future<void> submitQuiz() async {
    if (state.isSubmitted) return;

    try {
      // Calcular puntaje
      int score = 0;
      for (final question in state.questions) {
        final userAnswer = state.answers[question.id];
        if (userAnswer != null && question.isCorrect(userAnswer)) {
          score += question.points;
        }
      }

      // Enviar al servidor
      await _repository.submitQuiz(
        lessonId: lessonId,
        answers: state.answers.entries.map((e) => {
          'questionId': e.key,
          'answer': e.value,
        }).toList(),
      );

      state = state.copyWith(
        isSubmitted: true,
        score: score,
      );
    } catch (error) {
      // Manejar error
    }
  }

  /// Reintentar quiz
  void retryQuiz() {
    state = state.copyWith(
      answers: {},
      isSubmitted: false,
      score: null,
    );
  }
}

/// Provider de certificados
final certificatesProvider = FutureProvider<List<Certificate>>((ref) async {
  final repository = ref.read(courseRepositoryProvider);
  return repository.getCertificates();
});

/// Modelo de certificado
class Certificate {
  final int id;
  final int courseId;
  final String courseName;
  final String studentName;
  final DateTime completedAt;
  final String certificateUrl;

  const Certificate({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.studentName,
    required this.completedAt,
    required this.certificateUrl,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'],
      courseId: json['courseId'],
      courseName: json['courseName'],
      studentName: json['studentName'],
      completedAt: DateTime.parse(json['completedAt']),
      certificateUrl: json['certificateUrl'],
    );
  }
}