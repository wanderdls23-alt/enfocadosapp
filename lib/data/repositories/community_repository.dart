import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_client.dart';
import '../../core/services/cache_service.dart';
import '../models/prayer_request_model.dart';
import '../models/testimony_model.dart';

/// Repositorio para la comunidad
class CommunityRepository {
  final ApiClient _apiClient = ApiClient();
  final CacheService _cacheService = CacheService();

  static const String _prayerRequestsCacheKey = 'prayer_requests';
  static const String _testimoniesCacheKey = 'testimonies';
  static const String _eventsCacheKey = 'events';

  /// Obtener peticiones de oración
  Future<List<PrayerRequest>> getPrayerRequests({
    int page = 1,
    int limit = 20,
    String? category,
    bool? isUrgent,
  }) async {
    try {
      // Intentar obtener de caché primero
      final cachedData = await _cacheService.getCachedData(_prayerRequestsCacheKey);
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        return jsonList.map((json) => PrayerRequest.fromJson(json)).toList();
      }

      // Si no hay caché, obtener del servidor
      final response = await _apiClient.get(
        '/community/prayer-requests',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (category != null) 'category': category,
          if (isUrgent != null) 'isUrgent': isUrgent,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final requests = data.map((json) => PrayerRequest.fromJson(json)).toList();

        // Guardar en caché
        await _cacheService.cacheData(
          _prayerRequestsCacheKey,
          json.encode(data),
          duration: const Duration(minutes: 5),
        );

        return requests;
      } else {
        throw Exception('Error al obtener peticiones de oración');
      }
    } catch (e) {
      print('Error getting prayer requests: $e');
      // Intentar devolver datos de caché si hay error
      final cachedData = await _cacheService.getCachedData(_prayerRequestsCacheKey);
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        return jsonList.map((json) => PrayerRequest.fromJson(json)).toList();
      }
      throw e;
    }
  }

  /// Obtener peticiones de oración por categoría
  Future<List<PrayerRequest>> getPrayerRequestsByCategory(String category) async {
    return getPrayerRequests(category: category);
  }

  /// Obtener testimonios
  Future<List<Testimony>> getTestimonies({
    int page = 1,
    int limit = 20,
    String? category,
    bool? isFeatured,
  }) async {
    try {
      // Intentar obtener de caché primero
      final cachedData = await _cacheService.getCachedData(_testimoniesCacheKey);
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        return jsonList.map((json) => Testimony.fromJson(json)).toList();
      }

      final response = await _apiClient.get(
        '/community/testimonies',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (category != null) 'category': category,
          if (isFeatured != null) 'isFeatured': isFeatured,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final testimonies = data.map((json) => Testimony.fromJson(json)).toList();

        // Guardar en caché
        await _cacheService.cacheData(
          _testimoniesCacheKey,
          json.encode(data),
          duration: const Duration(minutes: 5),
        );

        return testimonies;
      } else {
        throw Exception('Error al obtener testimonios');
      }
    } catch (e) {
      print('Error getting testimonies: $e');
      // Intentar devolver datos de caché si hay error
      final cachedData = await _cacheService.getCachedData(_testimoniesCacheKey);
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        return jsonList.map((json) => Testimony.fromJson(json)).toList();
      }
      throw e;
    }
  }

  /// Obtener testimonios destacados
  Future<List<Testimony>> getFeaturedTestimonies() async {
    return getTestimonies(isFeatured: true);
  }

  /// Obtener testimonios por categoría
  Future<List<Testimony>> getTestimoniesByCategory(String category) async {
    return getTestimonies(category: category);
  }

  /// Obtener eventos
  Future<List<dynamic>> getEvents({
    int page = 1,
    int limit = 20,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final response = await _apiClient.get(
        '/community/events',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
          if (toDate != null) 'toDate': toDate.toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Error al obtener eventos');
      }
    } catch (e) {
      print('Error getting events: $e');
      return [];
    }
  }

  /// Orar por una petición
  Future<void> prayForRequest(String requestId) async {
    try {
      await _apiClient.post('/community/prayer-requests/$requestId/pray');
      // Limpiar caché para actualizar contadores
      await _cacheService.clearCache(_prayerRequestsCacheKey);
    } catch (e) {
      print('Error praying for request: $e');
      throw e;
    }
  }

  /// Quitar oración de una petición
  Future<void> unprayForRequest(String requestId) async {
    try {
      await _apiClient.delete('/community/prayer-requests/$requestId/pray');
      await _cacheService.clearCache(_prayerRequestsCacheKey);
    } catch (e) {
      print('Error unpraying for request: $e');
      throw e;
    }
  }

  /// Dar like a un testimonio
  Future<void> likeTestimony(String testimonyId) async {
    try {
      await _apiClient.post('/community/testimonies/$testimonyId/like');
      await _cacheService.clearCache(_testimoniesCacheKey);
    } catch (e) {
      print('Error liking testimony: $e');
      throw e;
    }
  }

  /// Quitar like de un testimonio
  Future<void> unlikeTestimony(String testimonyId) async {
    try {
      await _apiClient.delete('/community/testimonies/$testimonyId/like');
      await _cacheService.clearCache(_testimoniesCacheKey);
    } catch (e) {
      print('Error unliking testimony: $e');
      throw e;
    }
  }

  /// Crear petición de oración
  Future<PrayerRequest> createPrayerRequest({
    required String title,
    required String content,
    String? category,
    bool isAnonymous = false,
    bool isUrgent = false,
    List<String>? tags,
    String? bibleReference,
  }) async {
    try {
      final response = await _apiClient.post(
        '/community/prayer-requests',
        data: {
          'title': title,
          'content': content,
          'category': category,
          'isAnonymous': isAnonymous,
          'isUrgent': isUrgent,
          'tags': tags,
          'bibleReference': bibleReference,
        },
      );

      if (response.statusCode == 201) {
        await _cacheService.clearCache(_prayerRequestsCacheKey);
        return PrayerRequest.fromJson(response.data['data']);
      } else {
        throw Exception('Error al crear petición de oración');
      }
    } catch (e) {
      print('Error creating prayer request: $e');
      throw e;
    }
  }

  /// Actualizar petición de oración
  Future<PrayerRequest> updatePrayerRequest({
    required String requestId,
    String? title,
    String? content,
    String? category,
    bool? isUrgent,
    List<String>? tags,
    String? bibleReference,
  }) async {
    try {
      final response = await _apiClient.put(
        '/community/prayer-requests/$requestId',
        data: {
          if (title != null) 'title': title,
          if (content != null) 'content': content,
          if (category != null) 'category': category,
          if (isUrgent != null) 'isUrgent': isUrgent,
          if (tags != null) 'tags': tags,
          if (bibleReference != null) 'bibleReference': bibleReference,
        },
      );

      if (response.statusCode == 200) {
        await _cacheService.clearCache(_prayerRequestsCacheKey);
        return PrayerRequest.fromJson(response.data['data']);
      } else {
        throw Exception('Error al actualizar petición de oración');
      }
    } catch (e) {
      print('Error updating prayer request: $e');
      throw e;
    }
  }

  /// Eliminar petición de oración
  Future<void> deletePrayerRequest(String requestId) async {
    try {
      await _apiClient.delete('/community/prayer-requests/$requestId');
      await _cacheService.clearCache(_prayerRequestsCacheKey);
    } catch (e) {
      print('Error deleting prayer request: $e');
      throw e;
    }
  }

  /// Crear testimonio
  Future<Testimony> createTestimony({
    required String title,
    required String content,
    String? category,
    String? imageUrl,
    String? videoUrl,
    List<String>? tags,
    String? bibleReference,
    List<String>? beforeImages,
    List<String>? afterImages,
  }) async {
    try {
      final response = await _apiClient.post(
        '/community/testimonies',
        data: {
          'title': title,
          'content': content,
          'category': category,
          'imageUrl': imageUrl,
          'videoUrl': videoUrl,
          'tags': tags,
          'bibleReference': bibleReference,
          'beforeImages': beforeImages,
          'afterImages': afterImages,
        },
      );

      if (response.statusCode == 201) {
        await _cacheService.clearCache(_testimoniesCacheKey);
        return Testimony.fromJson(response.data['data']);
      } else {
        throw Exception('Error al crear testimonio');
      }
    } catch (e) {
      print('Error creating testimony: $e');
      throw e;
    }
  }

  /// Eliminar testimonio
  Future<void> deleteTestimony(String testimonyId) async {
    try {
      await _apiClient.delete('/community/testimonies/$testimonyId');
      await _cacheService.clearCache(_testimoniesCacheKey);
    } catch (e) {
      print('Error deleting testimony: $e');
      throw e;
    }
  }

  /// Obtener comentarios de una petición
  Future<List<PrayerComment>> getPrayerComments(
    String requestId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/community/prayer-requests/$requestId/comments',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => PrayerComment.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener comentarios');
      }
    } catch (e) {
      print('Error getting prayer comments: $e');
      return [];
    }
  }

  /// Agregar comentario a una petición
  Future<PrayerComment> addPrayerComment({
    required String requestId,
    required String content,
    bool isPrayer = false,
    String? bibleVerse,
  }) async {
    try {
      final response = await _apiClient.post(
        '/community/prayer-requests/$requestId/comments',
        data: {
          'content': content,
          'isPrayer': isPrayer,
          'bibleVerse': bibleVerse,
        },
      );

      if (response.statusCode == 201) {
        return PrayerComment.fromJson(response.data['data']);
      } else {
        throw Exception('Error al agregar comentario');
      }
    } catch (e) {
      print('Error adding prayer comment: $e');
      throw e;
    }
  }

  /// Obtener comentarios de un testimonio
  Future<List<TestimonyComment>> getTestimonyComments(
    String testimonyId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/community/testimonies/$testimonyId/comments',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => TestimonyComment.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener comentarios');
      }
    } catch (e) {
      print('Error getting testimony comments: $e');
      return [];
    }
  }

  /// Agregar comentario a un testimonio
  Future<TestimonyComment> addTestimonyComment({
    required String testimonyId,
    required String content,
    String? parentId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/community/testimonies/$testimonyId/comments',
        data: {
          'content': content,
          'parentId': parentId,
        },
      );

      if (response.statusCode == 201) {
        return TestimonyComment.fromJson(response.data['data']);
      } else {
        throw Exception('Error al agregar comentario');
      }
    } catch (e) {
      print('Error adding testimony comment: $e');
      throw e;
    }
  }

  /// Obtener estadísticas de la comunidad
  Future<dynamic> getStatistics() async {
    try {
      final response = await _apiClient.get('/community/statistics');

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Error al obtener estadísticas');
      }
    } catch (e) {
      print('Error getting statistics: $e');
      throw e;
    }
  }

  /// Reportar contenido
  Future<void> reportContent({
    required String contentType,
    required String contentId,
    required String reason,
    String? description,
  }) async {
    try {
      await _apiClient.post(
        '/community/reports',
        data: {
          'contentType': contentType,
          'contentId': contentId,
          'reason': reason,
          'description': description,
        },
      );
    } catch (e) {
      print('Error reporting content: $e');
      throw e;
    }
  }

  /// Buscar en la comunidad
  Future<Map<String, dynamic>> searchCommunity({
    required String query,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/community/search',
        queryParameters: {
          'q': query,
          'type': type,
          'page': page,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Error al buscar');
      }
    } catch (e) {
      print('Error searching community: $e');
      return {};
    }
  }
}