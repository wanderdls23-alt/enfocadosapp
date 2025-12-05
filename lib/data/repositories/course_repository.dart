import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/services/storage_service.dart';
import '../models/course_model.dart';

/// Repositorio para manejar todas las operaciones relacionadas con cursos
class CourseRepository {
  final ApiClient _apiClient = ApiClient.instance;
  final StorageService _storage = StorageService.instance;

  // ============= OBTENER CURSOS =============

  /// Obtener lista de cursos con paginación y filtros
  Future<CourseListResponse> getCourses({
    String? category,
    CourseDifficulty? difficulty,
    bool? isFree,
    String? search,
    int page = 1,
    int pageSize = 10,
    String? sortBy = 'createdAt',
  }) async {
    try {
      final queryParams = {
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        if (category != null) 'category': category,
        if (difficulty != null) 'difficulty': difficulty.name.toUpperCase(),
        if (isFree != null) 'isFree': isFree,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      // Generar clave de caché única
      final cacheKey = 'courses_${category ?? 'all'}_${difficulty?.name ?? 'all'}_$page';

      // Intentar obtener del caché si no es búsqueda
      if (search == null) {
        final cachedData = _storage.getFromCache(
          cacheKey,
          maxAge: const Duration(hours: 1),
        );

        if (cachedData != null) {
          return CourseListResponse.fromJson(cachedData);
        }
      }

      final response = await _apiClient.get(
        '/academy/courses',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final courseList = CourseListResponse.fromJson(response.data['data']);

        // Guardar en caché si no es búsqueda
        if (search == null) {
          await _storage.saveToCache(cacheKey, response.data['data']);
        }

        return courseList;
      } else {
        throw ApiException('Error al obtener cursos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener cursos');
    }
  }

  /// Obtener curso por ID con detalles completos
  Future<CourseModel> getCourseById(int courseId) async {
    try {
      final cacheKey = 'course_$courseId';

      // Intentar obtener del caché
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(hours: 2),
      );

      if (cachedData != null) {
        return CourseModel.fromJson(cachedData);
      }

      final response = await _apiClient.get('/academy/courses/$courseId');

      if (response.statusCode == 200 && response.data != null) {
        final course = CourseModel.fromJson(response.data['data']);

        // Guardar en caché
        await _storage.saveToCache(cacheKey, response.data['data']);

        return course;
      } else {
        throw NotFoundException('Curso no encontrado');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al obtener curso');
    }
  }

  /// Obtener cursos destacados
  Future<List<CourseModel>> getFeaturedCourses({int limit = 6}) async {
    try {
      final cacheKey = 'featured_courses_$limit';

      // Intentar obtener del caché
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(hours: 6),
      );

      if (cachedData != null) {
        final List<dynamic> data = cachedData['courses'];
        return data.map((json) => CourseModel.fromJson(json)).toList();
      }

      final response = await _apiClient.get(
        '/academy/courses/featured',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        final courses = data.map((json) => CourseModel.fromJson(json)).toList();

        // Guardar en caché
        await _storage.saveToCache(cacheKey, {'courses': data});

        return courses;
      } else {
        throw ApiException('Error al obtener cursos destacados');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener cursos destacados');
    }
  }

  /// Obtener cursos populares
  Future<List<CourseModel>> getPopularCourses({int limit = 10}) async {
    try {
      final cacheKey = 'popular_courses_$limit';

      // Intentar obtener del caché
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(hours: 3),
      );

      if (cachedData != null) {
        final List<dynamic> data = cachedData['courses'];
        return data.map((json) => CourseModel.fromJson(json)).toList();
      }

      final response = await _apiClient.get(
        '/academy/courses/popular',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        final courses = data.map((json) => CourseModel.fromJson(json)).toList();

        // Guardar en caché
        await _storage.saveToCache(cacheKey, {'courses': data});

        return courses;
      } else {
        throw ApiException('Error al obtener cursos populares');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener cursos populares');
    }
  }

  /// Obtener cursos relacionados
  Future<List<CourseModel>> getRelatedCourses({
    required int courseId,
    int limit = 4,
  }) async {
    try {
      final response = await _apiClient.get(
        '/academy/courses/$courseId/related',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => CourseModel.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener cursos relacionados');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener cursos relacionados');
    }
  }

  // ============= INSCRIPCIÓN =============

  /// Inscribirse en un curso
  Future<CourseProgress> enrollInCourse(int courseId) async {
    try {
      final response = await _apiClient.post(
        '/academy/enroll',
        data: {'courseId': courseId},
      );

      if (response.statusCode == 201 && response.data != null) {
        return CourseProgress.fromJson(response.data['data']);
      } else if (response.statusCode == 409) {
        throw ConflictException('Ya estás inscrito en este curso');
      } else {
        throw ApiException('Error al inscribirse en el curso');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al inscribirse');
    }
  }

  /// Desinscribirse de un curso
  Future<void> unenrollFromCourse(int courseId) async {
    try {
      final response = await _apiClient.delete('/academy/enroll/$courseId');

      if (response.statusCode != 200) {
        throw ApiException('Error al desinscribirse del curso');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al desinscribirse');
    }
  }

  /// Obtener cursos inscritos del usuario
  Future<List<CourseModel>> getEnrolledCourses() async {
    try {
      final response = await _apiClient.get('/academy/my-courses');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => CourseModel.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener cursos inscritos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener cursos inscritos');
    }
  }

  // ============= LECCIONES =============

  /// Obtener lección por ID
  Future<LessonModel> getLessonById(int lessonId) async {
    try {
      final response = await _apiClient.get('/academy/lessons/$lessonId');

      if (response.statusCode == 200 && response.data != null) {
        return LessonModel.fromJson(response.data['data']);
      } else {
        throw NotFoundException('Lección no encontrada');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al obtener lección');
    }
  }

  /// Obtener lecciones de un curso
  Future<List<LessonModel>> getCourseLessons(int courseId) async {
    try {
      final response = await _apiClient.get('/academy/courses/$courseId/lessons');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => LessonModel.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener lecciones');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener lecciones');
    }
  }

  /// Marcar lección como iniciada
  Future<LessonProgress> startLesson(int lessonId) async {
    try {
      final response = await _apiClient.post(
        '/academy/lessons/$lessonId/start',
      );

      if (response.statusCode == 201 && response.data != null) {
        return LessonProgress.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al iniciar lección');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al iniciar lección');
    }
  }

  /// Actualizar progreso de lección
  Future<LessonProgress> updateLessonProgress({
    required int lessonId,
    required int watchedPosition,
    bool completed = false,
  }) async {
    try {
      final response = await _apiClient.put(
        '/academy/lessons/$lessonId/progress',
        data: {
          'watchedPosition': watchedPosition,
          'completed': completed,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return LessonProgress.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al actualizar progreso');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al actualizar progreso');
    }
  }

  /// Marcar lección como completada
  Future<LessonProgress> completeLesson(int lessonId) async {
    try {
      final response = await _apiClient.post(
        '/academy/lessons/$lessonId/complete',
      );

      if (response.statusCode == 200 && response.data != null) {
        return LessonProgress.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al completar lección');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al completar lección');
    }
  }

  // ============= QUIZ =============

  /// Obtener preguntas del quiz
  Future<List<QuizQuestion>> getQuizQuestions(int lessonId) async {
    try {
      final response = await _apiClient.get('/academy/lessons/$lessonId/quiz');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => QuizQuestion.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener quiz');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener quiz');
    }
  }

  /// Enviar respuestas del quiz
  Future<QuizResult> submitQuizAnswers({
    required int lessonId,
    required List<QuizAnswer> answers,
  }) async {
    try {
      final response = await _apiClient.post(
        '/academy/lessons/$lessonId/quiz/submit',
        data: {
          'answers': answers.map((a) => a.toJson()).toList(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return QuizResult.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al enviar quiz');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al enviar quiz');
    }
  }

  /// Obtener intentos previos del quiz
  Future<List<QuizAttempt>> getQuizAttempts(int lessonId) async {
    try {
      final response = await _apiClient.get(
        '/academy/lessons/$lessonId/quiz/attempts',
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => QuizAttempt.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener intentos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener intentos');
    }
  }

  // ============= PROGRESO =============

  /// Obtener progreso general del usuario
  Future<CourseProgress> getCourseProgress(int courseId) async {
    try {
      final response = await _apiClient.get('/academy/courses/$courseId/progress');

      if (response.statusCode == 200 && response.data != null) {
        return CourseProgress.fromJson(response.data['data']);
      } else if (response.statusCode == 404) {
        throw NotFoundException('No estás inscrito en este curso');
      } else {
        throw ApiException('Error al obtener progreso');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener progreso');
    }
  }

  /// Obtener estadísticas de aprendizaje
  Future<LearningStats> getLearningStats() async {
    try {
      final response = await _apiClient.get('/academy/stats');

      if (response.statusCode == 200 && response.data != null) {
        return LearningStats.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al obtener estadísticas');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener estadísticas');
    }
  }

  // ============= CERTIFICADOS =============

  /// Obtener certificado de curso completado
  Future<Certificate> getCourseCertificate(int courseId) async {
    try {
      final response = await _apiClient.get('/academy/courses/$courseId/certificate');

      if (response.statusCode == 200 && response.data != null) {
        return Certificate.fromJson(response.data['data']);
      } else if (response.statusCode == 404) {
        throw NotFoundException('Certificado no disponible');
      } else if (response.statusCode == 403) {
        throw ForbiddenException('Debes completar el curso para obtener el certificado');
      } else {
        throw ApiException('Error al obtener certificado');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener certificado');
    }
  }

  /// Descargar certificado en PDF
  Future<String> downloadCertificatePDF(int courseId) async {
    try {
      final savePath = '/path/to/save/certificate_$courseId.pdf';

      await _apiClient.download(
        '/academy/courses/$courseId/certificate/pdf',
        savePath,
      );

      return savePath;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al descargar certificado');
    }
  }

  /// Obtener todos los certificados del usuario
  Future<List<Certificate>> getUserCertificates() async {
    try {
      final response = await _apiClient.get('/academy/certificates');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Certificate.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener certificados');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener certificados');
    }
  }

  // ============= CATEGORÍAS =============

  /// Obtener categorías de cursos
  Future<List<String>> getCategories() async {
    try {
      // Intentar obtener del caché
      final cachedData = _storage.getFromCache(
        'course_categories',
        maxAge: const Duration(days: 7),
      );

      if (cachedData != null) {
        final List<dynamic> data = cachedData['categories'];
        return data.cast<String>();
      }

      final response = await _apiClient.get('/academy/categories');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        final categories = data.cast<String>();

        // Guardar en caché
        await _storage.saveToCache('course_categories', {'categories': data});

        return categories;
      } else {
        throw ApiException('Error al obtener categorías');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener categorías');
    }
  }

  // ============= BÚSQUEDA =============

  /// Buscar cursos
  Future<CourseListResponse> searchCourses({
    required String query,
    String? category,
    CourseDifficulty? difficulty,
    bool? isFree,
    int page = 1,
    int pageSize = 20,
  }) async {
    return getCourses(
      search: query,
      category: category,
      difficulty: difficulty,
      isFree: isFree,
      page: page,
      pageSize: pageSize,
    );
  }
}

// ============= MODELOS ADICIONALES =============

/// Modelo para respuesta de quiz
class QuizAnswer {
  final int questionId;
  final String answer;

  QuizAnswer({required this.questionId, required this.answer});

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'answer': answer,
  };
}

/// Modelo para resultado del quiz
class QuizResult {
  final int score;
  final int maxScore;
  final bool passed;
  final int correctAnswers;
  final int totalQuestions;
  final Map<int, bool>? answerResults;

  QuizResult({
    required this.score,
    required this.maxScore,
    required this.passed,
    required this.correctAnswers,
    required this.totalQuestions,
    this.answerResults,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
    score: json['score'],
    maxScore: json['maxScore'],
    passed: json['passed'],
    correctAnswers: json['correctAnswers'],
    totalQuestions: json['totalQuestions'],
    answerResults: json['answerResults']?.cast<int, bool>(),
  );
}

/// Modelo para intento de quiz
class QuizAttempt {
  final int id;
  final int score;
  final int maxScore;
  final bool passed;
  final DateTime attemptedAt;

  QuizAttempt({
    required this.id,
    required this.score,
    required this.maxScore,
    required this.passed,
    required this.attemptedAt,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) => QuizAttempt(
    id: json['id'],
    score: json['score'],
    maxScore: json['maxScore'],
    passed: json['passed'],
    attemptedAt: DateTime.parse(json['attemptedAt']),
  );
}

/// Modelo para estadísticas de aprendizaje
class LearningStats {
  final int totalCourses;
  final int completedCourses;
  final int totalLessons;
  final int completedLessons;
  final Duration totalStudyTime;
  final double averageScore;
  final int certificates;

  LearningStats({
    required this.totalCourses,
    required this.completedCourses,
    required this.totalLessons,
    required this.completedLessons,
    required this.totalStudyTime,
    required this.averageScore,
    required this.certificates,
  });

  factory LearningStats.fromJson(Map<String, dynamic> json) => LearningStats(
    totalCourses: json['totalCourses'],
    completedCourses: json['completedCourses'],
    totalLessons: json['totalLessons'],
    completedLessons: json['completedLessons'],
    totalStudyTime: Duration(seconds: json['totalStudyTimeSeconds']),
    averageScore: json['averageScore'].toDouble(),
    certificates: json['certificates'],
  );
}

/// Modelo para certificado
class Certificate {
  final int id;
  final int courseId;
  final String courseName;
  final String userName;
  final DateTime completedAt;
  final String certificateUrl;
  final String certificateCode;

  Certificate({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.userName,
    required this.completedAt,
    required this.certificateUrl,
    required this.certificateCode,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) => Certificate(
    id: json['id'],
    courseId: json['courseId'],
    courseName: json['courseName'],
    userName: json['userName'],
    completedAt: DateTime.parse(json['completedAt']),
    certificateUrl: json['certificateUrl'],
    certificateCode: json['certificateCode'],
  );
}