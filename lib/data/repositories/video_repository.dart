import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/services/storage_service.dart';
import '../models/video_model.dart';

/// Repositorio para manejar todas las operaciones relacionadas con videos
class VideoRepository {
  final ApiClient _apiClient = ApiClient.instance;
  final StorageService _storage = StorageService.instance;

  // ============= OBTENER VIDEOS =============

  /// Obtener lista de videos con paginación
  Future<VideoListResponse> getVideos({
    String? category,
    String? search,
    int page = 1,
    int pageSize = 12,
    String? sortBy = 'publishedAt',
    bool useCache = true,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'pageSize': pageSize,
        'sortBy': sortBy,
        if (category != null && category != 'todos') 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      // Generar clave de caché única
      final cacheKey = 'videos_${category ?? 'all'}_${page}_$pageSize';

      // Intentar obtener del caché si está habilitado
      if (useCache && search == null) {
        final cachedData = _storage.getFromCache(
          cacheKey,
          maxAge: const Duration(minutes: 30),
        );

        if (cachedData != null) {
          return VideoListResponse.fromJson(cachedData);
        }
      }

      final response = await _apiClient.get(
        '/videos',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final videoList = VideoListResponse.fromJson(response.data['data']);

        // Guardar en caché si no es búsqueda
        if (search == null) {
          await _storage.saveToCache(cacheKey, response.data['data']);
        }

        return videoList;
      } else {
        throw ApiException('Error al obtener videos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener videos');
    }
  }

  /// Obtener video por ID
  Future<VideoModel> getVideoById(int videoId) async {
    try {
      final cacheKey = 'video_$videoId';

      // Intentar obtener del caché
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(hours: 1),
      );

      if (cachedData != null) {
        return VideoModel.fromJson(cachedData);
      }

      final response = await _apiClient.get('/videos/$videoId');

      if (response.statusCode == 200 && response.data != null) {
        final video = VideoModel.fromJson(response.data['data']);

        // Guardar en caché
        await _storage.saveToCache(cacheKey, response.data['data']);

        return video;
      } else {
        throw NotFoundException('Video no encontrado');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al obtener video');
    }
  }

  /// Obtener video por YouTube ID
  Future<VideoModel> getVideoByYouTubeId(String youtubeId) async {
    try {
      final response = await _apiClient.get('/videos/youtube/$youtubeId');

      if (response.statusCode == 200 && response.data != null) {
        return VideoModel.fromJson(response.data['data']);
      } else {
        throw NotFoundException('Video no encontrado');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al obtener video');
    }
  }

  /// Obtener últimos videos
  Future<List<VideoModel>> getLatestVideos({int limit = 10}) async {
    try {
      final cacheKey = 'latest_videos_$limit';

      // Intentar obtener del caché
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(minutes: 15),
      );

      if (cachedData != null) {
        final List<dynamic> data = cachedData['videos'];
        return data.map((json) => VideoModel.fromJson(json)).toList();
      }

      final response = await _apiClient.get(
        '/videos/latest',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        final videos = data.map((json) => VideoModel.fromJson(json)).toList();

        // Guardar en caché
        await _storage.saveToCache(cacheKey, {'videos': data});

        return videos;
      } else {
        throw ApiException('Error al obtener últimos videos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener últimos videos');
    }
  }

  /// Obtener videos relacionados
  Future<List<VideoModel>> getRelatedVideos({
    required int videoId,
    int limit = 6,
  }) async {
    try {
      final response = await _apiClient.get(
        '/videos/$videoId/related',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => VideoModel.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener videos relacionados');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener videos relacionados');
    }
  }

  /// Obtener videos más vistos
  Future<List<VideoModel>> getPopularVideos({
    int limit = 10,
    String? timeRange = 'week', // week, month, year, all
  }) async {
    try {
      final cacheKey = 'popular_videos_${timeRange}_$limit';

      // Intentar obtener del caché
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(hours: 6),
      );

      if (cachedData != null) {
        final List<dynamic> data = cachedData['videos'];
        return data.map((json) => VideoModel.fromJson(json)).toList();
      }

      final response = await _apiClient.get(
        '/videos/popular',
        queryParameters: {
          'limit': limit,
          'timeRange': timeRange,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        final videos = data.map((json) => VideoModel.fromJson(json)).toList();

        // Guardar en caché
        await _storage.saveToCache(cacheKey, {'videos': data});

        return videos;
      } else {
        throw ApiException('Error al obtener videos populares');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener videos populares');
    }
  }

  // ============= CATEGORÍAS =============

  /// Obtener categorías disponibles
  Future<List<String>> getCategories() async {
    try {
      // Intentar obtener del caché
      final cachedData = _storage.getFromCache(
        'video_categories',
        maxAge: const Duration(days: 7),
      );

      if (cachedData != null) {
        final List<dynamic> data = cachedData['categories'];
        return data.cast<String>();
      }

      final response = await _apiClient.get('/videos/categories');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        final categories = data.cast<String>();

        // Guardar en caché
        await _storage.saveToCache('video_categories', {'categories': data});

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

  // ============= HISTORIAL =============

  /// Guardar progreso de video
  Future<VideoHistory> saveVideoProgress({
    required int videoId,
    required int watchedDuration,
    required int lastPosition,
    bool completed = false,
  }) async {
    try {
      final response = await _apiClient.post(
        '/videos/history',
        data: {
          'videoId': videoId,
          'watchedDuration': watchedDuration,
          'lastPosition': lastPosition,
          'completed': completed,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        return VideoHistory.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al guardar progreso');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al guardar progreso');
    }
  }

  /// Obtener historial de videos vistos
  Future<List<VideoHistory>> getVideoHistory({
    int? limit,
    int? offset,
  }) async {
    try {
      final response = await _apiClient.get(
        '/videos/history',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => VideoHistory.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener historial');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener historial');
    }
  }

  /// Obtener progreso de un video específico
  Future<VideoHistory?> getVideoProgress(int videoId) async {
    try {
      final response = await _apiClient.get('/videos/history/$videoId');

      if (response.statusCode == 200 && response.data != null) {
        return VideoHistory.fromJson(response.data['data']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw ApiException('Error al obtener progreso');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener progreso');
    }
  }

  /// Limpiar historial
  Future<void> clearHistory() async {
    try {
      final response = await _apiClient.delete('/videos/history');

      if (response.statusCode != 200) {
        throw ApiException('Error al limpiar historial');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al limpiar historial');
    }
  }

  /// Eliminar video del historial
  Future<void> deleteFromHistory(int videoId) async {
    try {
      final response = await _apiClient.delete('/videos/history/$videoId');

      if (response.statusCode != 200) {
        throw ApiException('Error al eliminar del historial');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al eliminar del historial');
    }
  }

  // ============= BÚSQUEDA =============

  /// Buscar videos
  Future<VideoListResponse> searchVideos({
    required String query,
    String? category,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/videos/search',
        queryParameters: {
          'query': query,
          if (category != null) 'category': category,
          'page': page,
          'pageSize': pageSize,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return VideoListResponse.fromJson(response.data['data']);
      } else {
        throw ApiException('Error en la búsqueda');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado en la búsqueda');
    }
  }

  // ============= INTERACCIONES =============

  /// Dar like a un video
  Future<void> likeVideo(int videoId) async {
    try {
      final response = await _apiClient.post('/videos/$videoId/like');

      if (response.statusCode != 200) {
        throw ApiException('Error al dar like');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al dar like');
    }
  }

  /// Quitar like de un video
  Future<void> unlikeVideo(int videoId) async {
    try {
      final response = await _apiClient.delete('/videos/$videoId/like');

      if (response.statusCode != 200) {
        throw ApiException('Error al quitar like');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al quitar like');
    }
  }

  /// Reportar un problema con un video
  Future<void> reportVideo({
    required int videoId,
    required String reason,
    String? details,
  }) async {
    try {
      final response = await _apiClient.post(
        '/videos/$videoId/report',
        data: {
          'reason': reason,
          if (details != null) 'details': details,
        },
      );

      if (response.statusCode != 201) {
        throw ApiException('Error al reportar video');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al reportar video');
    }
  }

  // ============= SINCRONIZACIÓN CON YOUTUBE =============

  /// Sincronizar videos desde YouTube
  Future<int> syncVideosFromYouTube() async {
    try {
      final response = await _apiClient.post('/videos/sync');

      if (response.statusCode == 200 && response.data != null) {
        return response.data['data']['syncedCount'] ?? 0;
      } else {
        throw ApiException('Error al sincronizar videos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al sincronizar videos');
    }
  }

  /// Obtener estado de sincronización
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final response = await _apiClient.get('/videos/sync/status');

      if (response.statusCode == 200 && response.data != null) {
        return response.data['data'];
      } else {
        throw ApiException('Error al obtener estado de sincronización');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener estado');
    }
  }

  // ============= DESCARGA OFFLINE =============

  /// Marcar video para descarga offline
  Future<void> markForOfflineDownload(int videoId) async {
    try {
      // Guardar en storage local la marca de descarga pendiente
      final downloads = _storage.getStringList('pending_downloads') ?? [];
      if (!downloads.contains(videoId.toString())) {
        downloads.add(videoId.toString());
        await _storage.setStringList('pending_downloads', downloads);
      }
    } catch (e) {
      throw StorageException('Error al marcar para descarga');
    }
  }

  /// Obtener videos marcados para descarga
  Future<List<int>> getPendingDownloads() async {
    try {
      final downloads = _storage.getStringList('pending_downloads') ?? [];
      return downloads.map((id) => int.parse(id)).toList();
    } catch (e) {
      throw StorageException('Error al obtener descargas pendientes');
    }
  }

  /// Eliminar marca de descarga
  Future<void> removeOfflineDownload(int videoId) async {
    try {
      final downloads = _storage.getStringList('pending_downloads') ?? [];
      downloads.remove(videoId.toString());
      await _storage.setStringList('pending_downloads', downloads);
    } catch (e) {
      throw StorageException('Error al eliminar marca de descarga');
    }
  }
}