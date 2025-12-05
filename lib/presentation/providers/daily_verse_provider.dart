import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/daily_verse_model.dart';
import '../../data/repositories/daily_verse_repository.dart';

/// Provider del repositorio de versículos diarios
final dailyVerseRepositoryProvider = Provider<DailyVerseRepository>((ref) {
  return DailyVerseRepository();
});

/// Provider del versículo del día
final dailyVerseProvider = StateNotifierProvider<DailyVerseNotifier, AsyncValue<DailyVerseResponse>>((ref) {
  return DailyVerseNotifier(ref);
});

/// Notifier para el versículo diario
class DailyVerseNotifier extends StateNotifier<AsyncValue<DailyVerseResponse>> {
  final Ref _ref;
  late final DailyVerseRepository _repository;

  DailyVerseNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(dailyVerseRepositoryProvider);
  }

  /// Cargar el versículo del día
  Future<void> loadTodayVerse() async {
    state = const AsyncValue.loading();

    try {
      final verse = await _repository.getTodayVerse();
      state = AsyncValue.data(verse);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Calificar el versículo
  Future<void> rateVerse(int rating) async {
    final currentState = state;

    if (currentState is AsyncData<DailyVerseResponse>) {
      try {
        await _repository.rateVerse(
          dailyVerseId: currentState.value.dailyVerse.id,
          rating: rating,
        );

        // Actualizar el estado local
        final updatedVerse = currentState.value.dailyVerse.copyWith(
          userRating: rating,
        );

        state = AsyncValue.data(
          currentState.value.copyWith(dailyVerse: updatedVerse),
        );
      } catch (error) {
        // Mantener el estado actual si falla la calificación
      }
    }
  }

  /// Marcar como compartido
  Future<void> markAsShared(String platform) async {
    final currentState = state;

    if (currentState is AsyncData<DailyVerseResponse>) {
      try {
        await _repository.markAsShared(
          dailyVerseId: currentState.value.dailyVerse.id,
          platform: platform,
        );

        // Actualizar contador local
        final updatedVerse = currentState.value.dailyVerse.copyWith(
          shareCount: currentState.value.dailyVerse.shareCount + 1,
        );

        state = AsyncValue.data(
          currentState.value.copyWith(dailyVerse: updatedVerse),
        );
      } catch (error) {
        // Ignorar error
      }
    }
  }

  /// Obtener URL para compartir
  Future<String> getShareUrl(String platform) async {
    final currentState = state;

    if (currentState is AsyncData<DailyVerseResponse>) {
      try {
        return await _repository.shareVerse(
          dailyVerseId: currentState.value.dailyVerse.id,
          platform: platform,
        );
      } catch (error) {
        return 'https://enfocadosendiostv.com/app';
      }
    }

    return 'https://enfocadosendiostv.com/app';
  }

  /// Enviar feedback
  Future<void> sendFeedback(String feedback, {String? reason}) async {
    final currentState = state;

    if (currentState is AsyncData<DailyVerseResponse>) {
      try {
        await _repository.sendFeedback(
          dailyVerseId: currentState.value.dailyVerse.id,
          feedback: feedback,
          reason: reason,
        );
      } catch (error) {
        // Manejar error silenciosamente
      }
    }
  }
}

/// Provider del historial de versículos
final verseHistoryProvider = FutureProvider.family<DailyVerseHistory, int>((ref, limit) async {
  final repository = ref.read(dailyVerseRepositoryProvider);
  return repository.getHistory(limit: limit);
});

/// Provider de versículos favoritos
final favoriteVersesProvider = FutureProvider<List<DailyVerseModel>>((ref) async {
  final repository = ref.read(dailyVerseRepositoryProvider);
  return repository.getFavoriteVerses();
});

/// Provider de estadísticas de versículos
final verseStatsProvider = FutureProvider<DailyVerseStats>((ref) async {
  final repository = ref.read(dailyVerseRepositoryProvider);
  return repository.getStatistics();
});

/// Provider de preferencias del versículo diario
final versePreferencesProvider = StateNotifierProvider<VersePreferencesNotifier, AsyncValue<DailyVersePreferences>>((ref) {
  return VersePreferencesNotifier(ref);
});

/// Notifier para las preferencias del versículo diario
class VersePreferencesNotifier extends StateNotifier<AsyncValue<DailyVersePreferences>> {
  final Ref _ref;
  late final DailyVerseRepository _repository;

  VersePreferencesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(dailyVerseRepositoryProvider);
    loadPreferences();
  }

  /// Cargar preferencias
  Future<void> loadPreferences() async {
    state = const AsyncValue.loading();

    try {
      final preferences = await _repository.getPreferences();
      state = AsyncValue.data(preferences);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Actualizar hora de notificación
  Future<void> updateNotificationTime(String time) async {
    try {
      await _repository.updatePreferences(notificationTime: time);

      final currentState = state;
      if (currentState is AsyncData<DailyVersePreferences>) {
        state = AsyncValue.data(
          DailyVersePreferences(
            notificationTime: time,
            notificationsEnabled: currentState.value.notificationsEnabled,
            topics: currentState.value.topics,
            preferredBooks: currentState.value.preferredBooks,
          ),
        );
      }
    } catch (error) {
      // Manejar error
    }
  }

  /// Actualizar temas preferidos
  Future<void> updateTopics(List<String> topics) async {
    try {
      await _repository.updatePreferences(topics: topics);

      final currentState = state;
      if (currentState is AsyncData<DailyVersePreferences>) {
        state = AsyncValue.data(
          DailyVersePreferences(
            notificationTime: currentState.value.notificationTime,
            notificationsEnabled: currentState.value.notificationsEnabled,
            topics: topics,
            preferredBooks: currentState.value.preferredBooks,
          ),
        );
      }
    } catch (error) {
      // Manejar error
    }
  }

  /// Actualizar libros preferidos
  Future<void> updatePreferredBooks(List<int> books) async {
    try {
      await _repository.updatePreferences(preferredBooks: books);

      final currentState = state;
      if (currentState is AsyncData<DailyVersePreferences>) {
        state = AsyncValue.data(
          DailyVersePreferences(
            notificationTime: currentState.value.notificationTime,
            notificationsEnabled: currentState.value.notificationsEnabled,
            topics: currentState.value.topics,
            preferredBooks: books,
          ),
        );
      }
    } catch (error) {
      // Manejar error
    }
  }
}

/// Provider para versículo de fecha específica
final verseByDateProvider = FutureProvider.family<DailyVerseModel?, DateTime>((ref, date) async {
  final repository = ref.read(dailyVerseRepositoryProvider);
  return repository.getVerseByDate(date);
});

/// Provider para precargar versículos para modo offline
final precacheVersesProvider = FutureProvider.family<void, int>((ref, days) async {
  final repository = ref.read(dailyVerseRepositoryProvider);
  await repository.precacheVerses(days: days);
});

/// Provider para versículo offline
final offlineVerseProvider = FutureProvider.family<DailyVerseModel?, DateTime>((ref, date) async {
  final repository = ref.read(dailyVerseRepositoryProvider);
  return repository.getOfflineVerse(date);
});