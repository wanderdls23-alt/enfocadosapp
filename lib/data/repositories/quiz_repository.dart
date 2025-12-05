import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/services/api_service.dart';
import '../models/quiz_model.dart';

class QuizRepository {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  QuizRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Obtener quiz por ID
  Future<QuizModel> getQuiz(String quizId) async {
    try {
      final response = await _apiService.get('/quizzes/$quizId');

      if (response.data['success']) {
        return QuizModel.fromJson(response.data['quiz']);
      }

      throw Exception('Quiz no encontrado');
    } catch (e) {
      throw Exception('Error al obtener quiz: $e');
    }
  }

  /// Obtener quizzes de un curso
  Future<List<QuizModel>> getCourseQuizzes(String courseId) async {
    try {
      final response = await _apiService.get('/courses/$courseId/quizzes');

      if (response.data['success']) {
        return (response.data['quizzes'] as List)
            .map((quiz) => QuizModel.fromJson(quiz))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Error al obtener quizzes del curso: $e');
    }
  }

  /// Obtener quizzes de un módulo
  Future<List<QuizModel>> getModuleQuizzes(String moduleId) async {
    try {
      final response = await _apiService.get('/modules/$moduleId/quizzes');

      if (response.data['success']) {
        return (response.data['quizzes'] as List)
            .map((quiz) => QuizModel.fromJson(quiz))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Error al obtener quizzes del módulo: $e');
    }
  }

  /// Iniciar intento de quiz
  Future<QuizAttempt> startQuizAttempt(String quizId) async {
    try {
      final response = await _apiService.post(
        '/quizzes/$quizId/start',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.data['success']) {
        final attempt = QuizAttempt.fromJson(response.data['attempt']);

        // Guardar intento en progreso localmente
        await _saveAttemptLocally(attempt);

        return attempt;
      }

      throw Exception(response.data['error'] ?? 'No se pudo iniciar el quiz');
    } catch (e) {
      throw Exception('Error al iniciar quiz: $e');
    }
  }

  /// Enviar respuesta a una pregunta
  Future<void> submitAnswer({
    required String attemptId,
    required String questionId,
    required List<String> answerIds,
  }) async {
    try {
      // Guardar respuesta localmente primero (por si falla la conexión)
      await _saveAnswerLocally(attemptId, questionId, answerIds);

      final response = await _apiService.post(
        '/quiz-attempts/$attemptId/answer',
        data: {
          'questionId': questionId,
          'answerIds': answerIds,
        },
      );

      if (!response.data['success']) {
        throw Exception(response.data['error'] ?? 'Error al guardar respuesta');
      }
    } catch (e) {
      // Si falla, al menos está guardado localmente
      print('Error al enviar respuesta (guardada localmente): $e');
    }
  }

  /// Completar intento de quiz
  Future<QuizAttempt> completeQuizAttempt(String attemptId) async {
    try {
      // Primero sincronizar respuestas locales
      await _syncLocalAnswers(attemptId);

      final response = await _apiService.post(
        '/quiz-attempts/$attemptId/complete',
        data: {
          'completedAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.data['success']) {
        final completedAttempt = QuizAttempt.fromJson(response.data['attempt']);

        // Limpiar datos locales
        await _clearLocalAttempt(attemptId);

        return completedAttempt;
      }

      throw Exception(response.data['error'] ?? 'Error al completar quiz');
    } catch (e) {
      throw Exception('Error al completar quiz: $e');
    }
  }

  /// Abandonar intento de quiz
  Future<void> abandonQuizAttempt(String attemptId) async {
    try {
      await _apiService.post(
        '/quiz-attempts/$attemptId/abandon',
      );

      // Limpiar datos locales
      await _clearLocalAttempt(attemptId);
    } catch (e) {
      print('Error al abandonar quiz: $e');
    }
  }

  /// Obtener intentos de un quiz
  Future<List<QuizAttempt>> getQuizAttempts(String quizId) async {
    try {
      final response = await _apiService.get('/quizzes/$quizId/attempts');

      if (response.data['success']) {
        return (response.data['attempts'] as List)
            .map((attempt) => QuizAttempt.fromJson(attempt))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Error al obtener intentos: $e');
    }
  }

  /// Obtener intento específico
  Future<QuizAttempt?> getAttempt(String attemptId) async {
    try {
      final response = await _apiService.get('/quiz-attempts/$attemptId');

      if (response.data['success']) {
        return QuizAttempt.fromJson(response.data['attempt']);
      }

      return null;
    } catch (e) {
      throw Exception('Error al obtener intento: $e');
    }
  }

  /// Obtener estadísticas de un quiz
  Future<QuizStatistics> getQuizStatistics(String quizId) async {
    try {
      final response = await _apiService.get('/quizzes/$quizId/statistics');

      if (response.data['success']) {
        return QuizStatistics.fromJson(response.data['statistics']);
      }

      throw Exception('No se pudieron obtener estadísticas');
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Verificar elegibilidad para tomar quiz
  Future<QuizEligibility> checkQuizEligibility(String quizId) async {
    try {
      final response = await _apiService.get('/quizzes/$quizId/eligibility');

      if (response.data['success']) {
        return QuizEligibility.fromJson(response.data['eligibility']);
      }

      return QuizEligibility(
        canTake: false,
        reason: response.data['error'] ?? 'No elegible',
      );
    } catch (e) {
      return QuizEligibility(
        canTake: false,
        reason: 'Error al verificar elegibilidad',
      );
    }
  }

  /// Obtener pista para una pregunta
  Future<String?> getQuestionHint({
    required String quizId,
    required String questionId,
    required int hintLevel,
  }) async {
    try {
      final response = await _apiService.get(
        '/quizzes/$quizId/questions/$questionId/hint',
        queryParameters: {'level': hintLevel},
      );

      if (response.data['success']) {
        return response.data['hint'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Reportar problema con pregunta
  Future<bool> reportQuestionIssue({
    required String quizId,
    required String questionId,
    required String issue,
    String? description,
  }) async {
    try {
      final response = await _apiService.post(
        '/quizzes/$quizId/questions/$questionId/report',
        data: {
          'issue': issue,
          'description': description,
        },
      );

      return response.data['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // ============= MÉTODOS DE ALMACENAMIENTO LOCAL =============

  /// Guardar intento localmente
  Future<void> _saveAttemptLocally(QuizAttempt attempt) async {
    try {
      await _secureStorage.write(
        key: 'quiz_attempt_${attempt.id}',
        value: attempt.toJson().toString(),
      );
    } catch (e) {
      print('Error al guardar intento localmente: $e');
    }
  }

  /// Guardar respuesta localmente
  Future<void> _saveAnswerLocally(
    String attemptId,
    String questionId,
    List<String> answerIds,
  ) async {
    try {
      final key = 'quiz_answer_${attemptId}_$questionId';
      await _secureStorage.write(
        key: key,
        value: answerIds.join(','),
      );
    } catch (e) {
      print('Error al guardar respuesta localmente: $e');
    }
  }

  /// Sincronizar respuestas locales con servidor
  Future<void> _syncLocalAnswers(String attemptId) async {
    try {
      // Obtener todas las claves de respuestas para este intento
      final allData = await _secureStorage.readAll();
      final prefix = 'quiz_answer_${attemptId}_';

      for (final entry in allData.entries) {
        if (entry.key.startsWith(prefix)) {
          final questionId = entry.key.replaceFirst(prefix, '');
          final answerIds = entry.value.split(',');

          // Intentar enviar al servidor
          try {
            await _apiService.post(
              '/quiz-attempts/$attemptId/answer',
              data: {
                'questionId': questionId,
                'answerIds': answerIds,
              },
            );
          } catch (e) {
            print('Error sincronizando respuesta $questionId: $e');
          }
        }
      }
    } catch (e) {
      print('Error sincronizando respuestas: $e');
    }
  }

  /// Limpiar datos locales de un intento
  Future<void> _clearLocalAttempt(String attemptId) async {
    try {
      // Eliminar intento
      await _secureStorage.delete(key: 'quiz_attempt_$attemptId');

      // Eliminar todas las respuestas
      final allData = await _secureStorage.readAll();
      final prefix = 'quiz_answer_${attemptId}_';

      for (final key in allData.keys) {
        if (key.startsWith(prefix)) {
          await _secureStorage.delete(key: key);
        }
      }
    } catch (e) {
      print('Error limpiando datos locales: $e');
    }
  }

  /// Obtener intento local (para recuperación en caso de cierre inesperado)
  Future<QuizAttempt?> getLocalAttempt(String attemptId) async {
    try {
      final data = await _secureStorage.read(key: 'quiz_attempt_$attemptId');
      if (data != null) {
        return QuizAttempt.fromJson(Map<String, dynamic>.from(data as Map));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

// ============= QUIZ ELIGIBILITY MODEL =============

class QuizEligibility {
  final bool canTake;
  final String? reason;
  final int? remainingAttempts;
  final DateTime? nextAvailableAt;

  QuizEligibility({
    required this.canTake,
    this.reason,
    this.remainingAttempts,
    this.nextAvailableAt,
  });

  factory QuizEligibility.fromJson(Map<String, dynamic> json) {
    return QuizEligibility(
      canTake: json['canTake'] ?? false,
      reason: json['reason'],
      remainingAttempts: json['remainingAttempts'],
      nextAvailableAt: json['nextAvailableAt'] != null
          ? DateTime.parse(json['nextAvailableAt'])
          : null,
    );
  }
}