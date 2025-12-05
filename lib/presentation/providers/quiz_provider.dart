import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../data/models/quiz_model.dart';
import '../../data/repositories/quiz_repository.dart';

/// Provider del repositorio de quizzes
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository();
});

/// Provider de quiz específico
final quizProvider = FutureProvider.family<QuizModel, String>((ref, quizId) async {
  final repository = ref.read(quizRepositoryProvider);
  return repository.getQuiz(quizId);
});

/// Provider de quizzes de un curso
final courseQuizzesProvider = FutureProvider.family<List<QuizModel>, String>((ref, courseId) async {
  final repository = ref.read(quizRepositoryProvider);
  return repository.getCourseQuizzes(courseId);
});

/// Provider del intento actual de quiz
final currentQuizAttemptProvider = StateNotifierProvider<CurrentQuizAttemptNotifier, AsyncValue<QuizAttempt?>>((ref) {
  return CurrentQuizAttemptNotifier(ref);
});

/// Notifier para el intento actual
class CurrentQuizAttemptNotifier extends StateNotifier<AsyncValue<QuizAttempt?>> {
  final Ref _ref;
  late final QuizRepository _repository;
  Timer? _autoSaveTimer;

  CurrentQuizAttemptNotifier(this._ref) : super(const AsyncValue.data(null)) {
    _repository = _ref.read(quizRepositoryProvider);
  }

  /// Iniciar nuevo intento
  Future<void> startQuiz(String quizId) async {
    state = const AsyncValue.loading();

    try {
      final attempt = await _repository.startQuizAttempt(quizId);
      state = AsyncValue.data(attempt);

      // Iniciar auto-guardado cada 30 segundos
      _startAutoSave();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Enviar respuesta
  Future<void> submitAnswer({
    required String questionId,
    required List<String> answerIds,
  }) async {
    final currentState = state;

    if (currentState is AsyncData<QuizAttempt?> && currentState.value != null) {
      final attempt = currentState.value!;

      // Actualizar respuestas localmente
      final updatedAnswers = Map<String, List<String>>.from(attempt.answers);
      updatedAnswers[questionId] = answerIds;

      state = AsyncValue.data(
        attempt.copyWith(answers: updatedAnswers),
      );

      // Enviar al servidor
      try {
        await _repository.submitAnswer(
          attemptId: attempt.id,
          questionId: questionId,
          answerIds: answerIds,
        );
      } catch (e) {
        // Error manejado silenciosamente, la respuesta está guardada localmente
      }
    }
  }

  /// Completar quiz
  Future<QuizAttempt?> completeQuiz() async {
    final currentState = state;

    if (currentState is AsyncData<QuizAttempt?> && currentState.value != null) {
      state = const AsyncValue.loading();

      try {
        _stopAutoSave();
        final completedAttempt = await _repository.completeQuizAttempt(
          currentState.value!.id,
        );
        state = const AsyncValue.data(null);
        return completedAttempt;
      } catch (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
        return null;
      }
    }

    return null;
  }

  /// Abandonar quiz
  Future<void> abandonQuiz() async {
    final currentState = state;

    if (currentState is AsyncData<QuizAttempt?> && currentState.value != null) {
      _stopAutoSave();
      await _repository.abandonQuizAttempt(currentState.value!.id);
      state = const AsyncValue.data(null);
    }
  }

  /// Pausar quiz (guardar progreso)
  Future<void> pauseQuiz() async {
    final currentState = state;

    if (currentState is AsyncData<QuizAttempt?> && currentState.value != null) {
      // Sincronizar respuestas con servidor
      for (final entry in currentState.value!.answers.entries) {
        await _repository.submitAnswer(
          attemptId: currentState.value!.id,
          questionId: entry.key,
          answerIds: entry.value,
        );
      }
    }
  }

  /// Reanudar quiz pausado
  Future<void> resumeQuiz(String attemptId) async {
    state = const AsyncValue.loading();

    try {
      final attempt = await _repository.getAttempt(attemptId);
      if (attempt != null && attempt.status == QuizAttemptStatus.inProgress) {
        state = AsyncValue.data(attempt);
        _startAutoSave();
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void _startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      pauseQuiz();
    });
  }

  void _stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  @override
  void dispose() {
    _stopAutoSave();
    super.dispose();
  }
}

/// Provider de temporizador de quiz
final quizTimerProvider = StateNotifierProvider<QuizTimerNotifier, Duration>((ref) {
  return QuizTimerNotifier(ref);
});

/// Notifier para el temporizador
class QuizTimerNotifier extends StateNotifier<Duration> {
  final Ref _ref;
  Timer? _timer;
  DateTime? _startTime;

  QuizTimerNotifier(this._ref) : super(Duration.zero);

  /// Iniciar temporizador
  void startTimer({int? timeLimitMinutes}) {
    _startTime = DateTime.now();
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsed = DateTime.now().difference(_startTime!);
      state = elapsed;

      // Si hay límite de tiempo, verificar si se ha excedido
      if (timeLimitMinutes != null) {
        final limitDuration = Duration(minutes: timeLimitMinutes);
        if (elapsed >= limitDuration) {
          stopTimer();
          // Notificar que el tiempo se agotó
          _ref.read(currentQuizAttemptProvider.notifier).completeQuiz();
        }
      }
    });
  }

  /// Pausar temporizador
  void pauseTimer() {
    _timer?.cancel();
  }

  /// Reanudar temporizador
  void resumeTimer() {
    if (_startTime != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final elapsed = DateTime.now().difference(_startTime!);
        state = elapsed;
      });
    }
  }

  /// Detener temporizador
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Obtener tiempo formateado
  String get formattedTime {
    final minutes = state.inMinutes;
    final seconds = state.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider de estadísticas de quiz
final quizStatisticsProvider = FutureProvider.family<QuizStatistics, String>((ref, quizId) async {
  final repository = ref.read(quizRepositoryProvider);
  return repository.getQuizStatistics(quizId);
});

/// Provider de intentos de quiz
final quizAttemptsProvider = FutureProvider.family<List<QuizAttempt>, String>((ref, quizId) async {
  final repository = ref.read(quizRepositoryProvider);
  return repository.getQuizAttempts(quizId);
});

/// Provider de elegibilidad de quiz
final quizEligibilityProvider = FutureProvider.family<QuizEligibility, String>((ref, quizId) async {
  final repository = ref.read(quizRepositoryProvider);
  return repository.checkQuizEligibility(quizId);
});

/// Provider de respuesta seleccionada para pregunta actual
final selectedAnswersProvider = StateProvider.family<List<String>, String>((ref, questionId) {
  // Obtener respuestas del intento actual si existen
  final attemptState = ref.watch(currentQuizAttemptProvider);

  if (attemptState is AsyncData<QuizAttempt?> && attemptState.value != null) {
    return attemptState.value!.answers[questionId] ?? [];
  }

  return [];
});

/// Provider de pregunta actual en el quiz
final currentQuestionIndexProvider = StateProvider<int>((ref) => 0);

/// Provider de modo de revisión
final reviewModeProvider = StateProvider<bool>((ref) => false);

/// Provider de pistas usadas
final usedHintsProvider = StateNotifierProvider<UsedHintsNotifier, Map<String, int>>((ref) {
  return UsedHintsNotifier();
});

/// Notifier para pistas usadas
class UsedHintsNotifier extends StateNotifier<Map<String, int>> {
  UsedHintsNotifier() : super({});

  void useHint(String questionId) {
    final currentLevel = state[questionId] ?? 0;
    state = {
      ...state,
      questionId: currentLevel + 1,
    };
  }

  int getHintLevel(String questionId) {
    return state[questionId] ?? 0;
  }

  void reset() {
    state = {};
  }
}