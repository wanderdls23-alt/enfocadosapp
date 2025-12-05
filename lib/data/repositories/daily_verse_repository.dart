import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/services/storage_service.dart';
import '../models/daily_verse_model.dart';
import '../models/bible_models.dart';

/// Repositorio para manejar el versículo diario inteligente
class DailyVerseRepository {
  final ApiClient _apiClient = ApiClient.instance;
  final StorageService _storage = StorageService.instance;

  // ============= VERSÍCULO DIARIO =============

  /// Obtener el versículo del día
  Future<DailyVerseResponse> getTodayVerse() async {
    try {
      // Primero verificar si ya tenemos un versículo para hoy en caché
      final today = DateTime.now();
      final cacheKey = 'daily_verse_${today.year}_${today.month}_${today.day}';

      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(hours: 24),
      );

      if (cachedData != null) {
        return DailyVerseResponse.fromJson(cachedData);
      }

      // Si no hay caché, obtener del servidor
      final response = await _apiClient.get('/daily-verse/today');

      if (response.statusCode == 200 && response.data != null) {
        final verseResponse = DailyVerseResponse.fromJson(response.data['data']);

        // Guardar en caché
        await _storage.saveToCache(cacheKey, response.data['data']);

        // Marcar como leído automáticamente
        await markAsRead(verseResponse.dailyVerse.id);

        return verseResponse;
      } else {
        throw ApiException('Error al obtener versículo diario');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener versículo diario');
    }
  }

  /// Obtener versículo de una fecha específica
  Future<DailyVerseModel?> getVerseByDate(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await _apiClient.get(
        '/daily-verse/date/$dateStr',
      );

      if (response.statusCode == 200 && response.data != null) {
        return DailyVerseModel.fromJson(response.data['data']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw ApiException('Error al obtener versículo');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener versículo');
    }
  }

  /// Obtener historial de versículos diarios
  Future<DailyVerseHistory> getHistory({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '/daily-verse/history',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return DailyVerseHistory.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al obtener historial');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener historial');
    }
  }

  // ============= INTERACCIONES =============

  /// Marcar versículo como leído
  Future<void> markAsRead(int dailyVerseId) async {
    try {
      final response = await _apiClient.put(
        '/daily-verse/$dailyVerseId/read',
      );

      if (response.statusCode != 200) {
        throw ApiException('Error al marcar como leído');
      }
    } on ApiException {
      // No propagar error si falla marcar como leído
    } catch (e) {
      // Silently fail
    }
  }

  /// Calificar versículo
  Future<void> rateVerse({
    required int dailyVerseId,
    required int rating,
  }) async {
    try {
      if (rating < 1 || rating > 5) {
        throw ValidationException('La calificación debe estar entre 1 y 5');
      }

      final response = await _apiClient.post(
        '/daily-verse/$dailyVerseId/rate',
        data: {'rating': rating},
      );

      if (response.statusCode != 200) {
        throw ApiException('Error al calificar versículo');
      }

      // Actualizar caché local con la calificación
      _updateLocalRating(dailyVerseId, rating);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al calificar versículo');
    }
  }

  /// Marcar versículo como compartido
  Future<void> markAsShared({
    required int dailyVerseId,
    required String platform,
  }) async {
    try {
      final response = await _apiClient.post(
        '/daily-verse/$dailyVerseId/share',
        data: {'platform': platform},
      );

      if (response.statusCode != 200) {
        throw ApiException('Error al marcar como compartido');
      }
    } on ApiException {
      // No propagar error si falla
    } catch (e) {
      // Silently fail
    }
  }

  /// Compartir versículo y obtener URL
  Future<String> shareVerse({
    required int dailyVerseId,
    required String platform,
  }) async {
    try {
      // Marcar como compartido
      await markAsShared(
        dailyVerseId: dailyVerseId,
        platform: platform,
      );

      // Generar URL para compartir
      final response = await _apiClient.get(
        '/daily-verse/$dailyVerseId/share-url',
        queryParameters: {'platform': platform},
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['data']['url'];
      } else {
        // Si falla, devolver URL genérica
        return 'https://enfocadosendiostv.com/app';
      }
    } catch (e) {
      // Si falla, devolver URL genérica
      return 'https://enfocadosendiostv.com/app';
    }
  }

  // ============= PREFERENCIAS Y CONFIGURACIÓN =============

  /// Actualizar preferencias del versículo diario
  Future<void> updatePreferences({
    String? notificationTime,
    List<String>? topics,
    List<int>? preferredBooks,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (notificationTime != null) {
        data['notificationTime'] = notificationTime;
      }
      if (topics != null) {
        data['topics'] = topics;
      }
      if (preferredBooks != null) {
        data['preferredBooks'] = preferredBooks;
      }

      final response = await _apiClient.put(
        '/daily-verse/preferences',
        data: data,
      );

      if (response.statusCode != 200) {
        throw ApiException('Error al actualizar preferencias');
      }

      // Actualizar preferencias locales
      if (notificationTime != null) {
        await _storage.setDailyVerseTime(notificationTime);
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al actualizar preferencias');
    }
  }

  /// Obtener preferencias del versículo diario
  Future<DailyVersePreferences> getPreferences() async {
    try {
      final response = await _apiClient.get('/daily-verse/preferences');

      if (response.statusCode == 200 && response.data != null) {
        return DailyVersePreferences.fromJson(response.data['data']);
      } else {
        // Devolver preferencias por defecto
        return DailyVersePreferences.defaultPreferences();
      }
    } on ApiException {
      // Si falla, devolver preferencias locales
      return _getLocalPreferences();
    } catch (e) {
      return _getLocalPreferences();
    }
  }

  // ============= ESTADÍSTICAS =============

  /// Obtener estadísticas del versículo diario
  Future<DailyVerseStats> getStatistics() async {
    try {
      final response = await _apiClient.get('/daily-verse/stats');

      if (response.statusCode == 200 && response.data != null) {
        return DailyVerseStats.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al obtener estadísticas');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener estadísticas');
    }
  }

  /// Obtener versículos favoritos (calificación 5)
  Future<List<DailyVerseModel>> getFavoriteVerses({
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/daily-verse/favorites',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => DailyVerseModel.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener favoritos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener favoritos');
    }
  }

  // ============= SUGERENCIAS Y FEEDBACK =============

  /// Enviar feedback sobre el versículo
  Future<void> sendFeedback({
    required int dailyVerseId,
    required String feedback,
    String? reason,
  }) async {
    try {
      final response = await _apiClient.post(
        '/daily-verse/$dailyVerseId/feedback',
        data: {
          'feedback': feedback,
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode != 201) {
        throw ApiException('Error al enviar feedback');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al enviar feedback');
    }
  }

  /// Reportar problema con el versículo
  Future<void> reportIssue({
    required int dailyVerseId,
    required String issue,
    String? details,
  }) async {
    try {
      final response = await _apiClient.post(
        '/daily-verse/$dailyVerseId/report',
        data: {
          'issue': issue,
          if (details != null) 'details': details,
        },
      );

      if (response.statusCode != 201) {
        throw ApiException('Error al reportar problema');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al reportar problema');
    }
  }

  // ============= MÉTODOS PRIVADOS =============

  /// Actualizar calificación en caché local
  void _updateLocalRating(int dailyVerseId, int rating) {
    try {
      final today = DateTime.now();
      final cacheKey = 'daily_verse_${today.year}_${today.month}_${today.day}';

      final cachedData = _storage.getFromCache(cacheKey);
      if (cachedData != null) {
        cachedData['dailyVerse']['userRating'] = rating;
        _storage.saveToCache(cacheKey, cachedData);
      }
    } catch (e) {
      // Silently fail
    }
  }

  /// Obtener preferencias locales
  DailyVersePreferences _getLocalPreferences() {
    final notificationTime = _storage.getDailyVerseTime();
    return DailyVersePreferences(
      notificationTime: notificationTime,
      notificationsEnabled: _storage.areNotificationsEnabled(),
      topics: [],
      preferredBooks: [],
    );
  }

  // ============= OFFLINE SUPPORT =============

  /// Precargar versículos para modo offline
  Future<void> precacheVerses({int days = 7}) async {
    try {
      final response = await _apiClient.get(
        '/daily-verse/precache',
        queryParameters: {'days': days},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> verses = response.data['data'];

        // Guardar cada versículo en caché
        for (final verseData in verses) {
          final verse = DailyVerseModel.fromJson(verseData);
          final date = verse.shownDate;
          final cacheKey = 'daily_verse_${date.year}_${date.month}_${date.day}';

          await _storage.saveToCache(cacheKey, {
            'dailyVerse': verseData,
          });
        }
      }
    } catch (e) {
      // Silently fail - no es crítico
    }
  }

  /// Obtener versículo offline
  Future<DailyVerseModel?> getOfflineVerse(DateTime date) async {
    try {
      final cacheKey = 'daily_verse_${date.year}_${date.month}_${date.day}';
      final cachedData = _storage.getFromCache(cacheKey);

      if (cachedData != null) {
        return DailyVerseModel.fromJson(cachedData['dailyVerse']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

// ============= MODELOS ADICIONALES =============

/// Modelo para preferencias del versículo diario
class DailyVersePreferences {
  final String notificationTime;
  final bool notificationsEnabled;
  final List<String> topics;
  final List<int> preferredBooks;

  DailyVersePreferences({
    required this.notificationTime,
    required this.notificationsEnabled,
    required this.topics,
    required this.preferredBooks,
  });

  factory DailyVersePreferences.fromJson(Map<String, dynamic> json) {
    return DailyVersePreferences(
      notificationTime: json['notificationTime'] ?? '08:00',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      topics: List<String>.from(json['topics'] ?? []),
      preferredBooks: List<int>.from(json['preferredBooks'] ?? []),
    );
  }

  factory DailyVersePreferences.defaultPreferences() {
    return DailyVersePreferences(
      notificationTime: '08:00',
      notificationsEnabled: true,
      topics: [],
      preferredBooks: [],
    );
  }

  Map<String, dynamic> toJson() => {
    'notificationTime': notificationTime,
    'notificationsEnabled': notificationsEnabled,
    'topics': topics,
    'preferredBooks': preferredBooks,
  };
}

/// Modelo para estadísticas del versículo diario
class DailyVerseStats {
  final int totalDays;
  final int consecutiveDays;
  final int totalRead;
  final int totalShared;
  final int totalRated;
  final double averageRating;
  final Map<String, int> topBooks;
  final Map<String, int> topTopics;

  DailyVerseStats({
    required this.totalDays,
    required this.consecutiveDays,
    required this.totalRead,
    required this.totalShared,
    required this.totalRated,
    required this.averageRating,
    required this.topBooks,
    required this.topTopics,
  });

  factory DailyVerseStats.fromJson(Map<String, dynamic> json) {
    return DailyVerseStats(
      totalDays: json['totalDays'] ?? 0,
      consecutiveDays: json['consecutiveDays'] ?? 0,
      totalRead: json['totalRead'] ?? 0,
      totalShared: json['totalShared'] ?? 0,
      totalRated: json['totalRated'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      topBooks: Map<String, int>.from(json['topBooks'] ?? {}),
      topTopics: Map<String, int>.from(json['topTopics'] ?? {}),
    );
  }

  /// Obtener el libro más leído
  String? get mostReadBook {
    if (topBooks.isEmpty) return null;
    return topBooks.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Obtener el tema más frecuente
  String? get mostFrequentTopic {
    if (topTopics.isEmpty) return null;
    return topTopics.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Porcentaje de versículos leídos
  double get readPercentage {
    if (totalDays == 0) return 0;
    return (totalRead / totalDays) * 100;
  }

  /// Porcentaje de versículos compartidos
  double get sharePercentage {
    if (totalDays == 0) return 0;
    return (totalShared / totalDays) * 100;
  }
}