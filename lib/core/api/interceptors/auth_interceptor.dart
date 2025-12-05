import 'package:dio/dio.dart';
import '../../services/storage_service.dart';
import '../api_exceptions.dart';

/// Interceptor para manejar la autenticación en las peticiones
class AuthInterceptor extends Interceptor {
  final StorageService _storage;
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Si la petición no requiere token, continuar
    if (options.extra['requiresToken'] == false) {
      return handler.next(options);
    }

    // Si se está refrescando el token, encolar la petición
    if (_isRefreshing) {
      _pendingRequests.add(options);
      return;
    }

    // Obtener token de acceso
    final accessToken = await _storage.getAccessToken();

    if (accessToken != null) {
      // Agregar token al header
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    // Agregar headers adicionales
    options.headers.addAll({
      'X-App-Platform': 'mobile',
      'X-App-Version': '1.0.0',
    });

    return handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // Si la respuesta es exitosa, continuar
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Si el error es 401 (Unauthorized)
    if (err.response?.statusCode == 401) {
      // Si ya estamos refrescando, encolar la petición
      if (_isRefreshing) {
        _pendingRequests.add(err.requestOptions);
        return;
      }

      // Marcar que estamos refrescando
      _isRefreshing = true;

      try {
        // Intentar refrescar el token
        await _refreshToken();

        // Obtener el nuevo token
        final newAccessToken = await _storage.getAccessToken();

        if (newAccessToken != null) {
          // Actualizar el token en la petición original
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          // Reintentar la petición original
          final response = await _retry(err.requestOptions);

          // Procesar las peticiones pendientes
          await _processPendingRequests(newAccessToken);

          _isRefreshing = false;
          _pendingRequests.clear();

          return handler.resolve(response);
        }
      } catch (e) {
        // Si falla el refresh, limpiar tokens y propagar el error
        await _storage.clearSession();
        _isRefreshing = false;
        _pendingRequests.clear();

        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: UnauthorizedException('Sesión expirada. Por favor inicia sesión nuevamente.'),
            type: DioExceptionType.badResponse,
            response: err.response,
          ),
        );
      }
    }

    // Para otros errores, continuar con el manejo normal
    return handler.next(err);
  }

  /// Refresca el token de acceso
  Future<void> _refreshToken() async {
    final dio = Dio();
    final refreshToken = await _storage.getRefreshToken();

    if (refreshToken == null) {
      throw UnauthorizedException('No refresh token available');
    }

    try {
      final response = await dio.post(
        '${dio.options.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        await _storage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'] ?? refreshToken,
        );
      } else {
        throw UnauthorizedException('Failed to refresh token');
      }
    } catch (e) {
      throw UnauthorizedException('Failed to refresh token: ${e.toString()}');
    } finally {
      dio.close();
    }
  }

  /// Reintenta una petición con el nuevo token
  Future<Response> _retry(RequestOptions requestOptions) async {
    final dio = Dio();

    try {
      final options = Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        validateStatus: requestOptions.validateStatus,
        receiveTimeout: requestOptions.receiveTimeout,
        sendTimeout: requestOptions.sendTimeout,
        extra: requestOptions.extra,
      );

      return await dio.request(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options,
      );
    } finally {
      dio.close();
    }
  }

  /// Procesa las peticiones pendientes con el nuevo token
  Future<void> _processPendingRequests(String newToken) async {
    for (final request in _pendingRequests) {
      request.headers['Authorization'] = 'Bearer $newToken';
      // Aquí podrías reintentar las peticiones pendientes si es necesario
    }
  }
}