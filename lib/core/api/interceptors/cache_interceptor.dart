import 'dart:convert';
import 'package:dio/dio.dart';
import '../../services/storage_service.dart';

/// Interceptor para manejar el caché de las peticiones GET
class CacheInterceptor extends Interceptor {
  final StorageService _storage = StorageService.instance;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Solo cachear peticiones GET
    if (options.method != 'GET') {
      return handler.next(options);
    }

    // Verificar si la petición requiere caché
    final useCache = options.extra['useCache'] ?? false;
    if (!useCache) {
      return handler.next(options);
    }

    // Generar clave de caché única
    final cacheKey = _generateCacheKey(options);

    // Obtener duración del caché
    final cacheDuration = options.extra['cacheDuration'] as Duration? ??
                          const Duration(minutes: 5);

    // Intentar obtener datos del caché
    final cachedData = _storage.getFromCache(cacheKey, maxAge: cacheDuration);

    if (cachedData != null) {
      // Si hay datos en caché, devolver respuesta desde el caché
      final response = Response(
        requestOptions: options,
        statusCode: 200,
        data: cachedData,
        extra: {'fromCache': true},
      );

      return handler.resolve(response);
    }

    // Si no hay caché, continuar con la petición normal
    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // Solo cachear respuestas exitosas de peticiones GET
    if (response.requestOptions.method != 'GET' ||
        response.statusCode != 200) {
      return handler.next(response);
    }

    // Verificar si la petición requiere caché
    final useCache = response.requestOptions.extra['useCache'] ?? false;
    if (!useCache) {
      return handler.next(response);
    }

    // No volver a cachear si la respuesta ya viene del caché
    if (response.extra?['fromCache'] == true) {
      return handler.next(response);
    }

    // Generar clave de caché
    final cacheKey = _generateCacheKey(response.requestOptions);

    // Guardar en caché
    if (response.data != null) {
      await _storage.saveToCache(cacheKey, response.data);
    }

    return handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Si hay un error de red, intentar devolver datos del caché
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {

      final useCache = err.requestOptions.extra['useCache'] ?? false;

      if (useCache && err.requestOptions.method == 'GET') {
        final cacheKey = _generateCacheKey(err.requestOptions);

        // Intentar obtener del caché sin restricción de tiempo
        final cachedData = _storage.getFromCache(cacheKey);

        if (cachedData != null) {
          // Devolver datos del caché aunque estén expirados
          final response = Response(
            requestOptions: err.requestOptions,
            statusCode: 200,
            data: cachedData,
            extra: {
              'fromCache': true,
              'stale': true,
            },
          );

          return handler.resolve(response);
        }
      }
    }

    // Si no hay caché o no se puede usar, propagar el error
    handler.next(err);
  }

  /// Genera una clave única para el caché basada en la petición
  String _generateCacheKey(RequestOptions options) {
    final uri = options.uri;
    final queryParams = options.queryParameters;

    // Crear una clave única basada en la URL y parámetros
    final keyData = {
      'path': uri.path,
      'query': queryParams,
    };

    // Convertir a string y hacer hash simple
    final jsonString = jsonEncode(keyData);
    final bytes = utf8.encode(jsonString);
    final hash = bytes.fold(0, (prev, element) => prev + element);

    return 'api_cache_${hash.abs()}';
  }
}