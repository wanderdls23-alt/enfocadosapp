import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import '../services/storage_service.dart';
import 'api_exceptions.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/cache_interceptor.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final StorageService _storage = StorageService.instance;

  // Singleton pattern
  ApiClient._() {
    _initializeDio();
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  void _initializeDio() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? AppConstants.apiBaseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Version': AppConstants.appVersion,
          'X-App-Platform': 'mobile',
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    // Agregar interceptores en orden
    _dio.interceptors.addAll([
      // Cache interceptor (primero para verificar cache)
      CacheInterceptor(),

      // Auth interceptor (agregar token)
      AuthInterceptor(_storage),

      // Error interceptor (manejo de errores)
      ErrorInterceptor(),

      // Logger (solo en debug)
      if (AppConstants.debugApiCalls)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
    ]);
  }

  // ============= GET REQUEST =============
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool useCache = false,
  }) async {
    try {
      final enhancedOptions = _enhanceOptions(options, useCache);

      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: enhancedOptions,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============= POST REQUEST =============
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============= PUT REQUEST =============
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============= PATCH REQUEST =============
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============= DELETE REQUEST =============
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============= DOWNLOAD FILE =============
  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        data: data,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============= UPLOAD FILE =============
  Future<Response<T>> uploadFile<T>(
    String path,
    String filePath, {
    String fileKey = 'file',
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        fileKey: await MultipartFile.fromFile(filePath),
      });

      return await post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============= REFRESH TOKEN =============
  Future<void> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        throw UnauthorizedException('No refresh token available');
      }

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {'requiresToken': false},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _storage.saveTokens(
          accessToken: data['data']['accessToken'],
          refreshToken: data['data']['refreshToken'],
        );
      } else {
        throw UnauthorizedException('Failed to refresh token');
      }
    } catch (e) {
      // Si falla el refresh, limpiar tokens y redirigir al login
      await _storage.clearTokens();
      throw UnauthorizedException('Session expired');
    }
  }

  // ============= HELPER METHODS =============

  Options _enhanceOptions(Options? options, bool useCache) {
    final enhancedOptions = options ?? Options();

    if (useCache) {
      enhancedOptions.extra = {
        ...?enhancedOptions.extra,
        'useCache': true,
        'cacheDuration': const Duration(minutes: 5),
      };
    }

    return enhancedOptions;
  }

  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('La conexión ha tardado demasiado');

      case DioExceptionType.connectionError:
        return NetworkException('Sin conexión a Internet');

      case DioExceptionType.cancel:
        return ApiException('Solicitud cancelada');

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.badCertificate:
        return ApiException('Certificado de seguridad inválido');

      case DioExceptionType.unknown:
      default:
        return ApiException(
          error.message ?? 'Ha ocurrido un error inesperado',
        );
    }
  }

  Exception _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String message = 'Error desconocido';

    if (responseData != null) {
      if (responseData is Map) {
        message = responseData['error'] ??
                  responseData['message'] ??
                  message;
      } else if (responseData is String) {
        message = responseData;
      }
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(message);
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 409:
        return ConflictException(message);
      case 422:
        return ValidationException(message);
      case 429:
        return TooManyRequestsException(message);
      case 500:
        return ServerException('Error en el servidor');
      case 502:
        return ServerException('Bad Gateway');
      case 503:
        return ServerException('Servicio no disponible');
      default:
        return ApiException(message);
    }
  }

  // ============= PUBLIC GETTERS =============

  Dio get dio => _dio;

  String get baseUrl => _dio.options.baseUrl;

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  void clearCache() {
    // Implementar limpieza de cache si es necesario
  }

  // ============= DISPOSE =============

  void dispose() {
    _dio.close(force: true);
  }
}