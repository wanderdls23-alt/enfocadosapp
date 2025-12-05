import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api_exceptions.dart';

/// Interceptor para manejar errores de manera centralizada
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log del error en modo debug
    if (kDebugMode) {
      _logError(err);
    }

    // Transformar el error en una excepción personalizada
    final customException = _handleError(err);

    // Crear un nuevo DioException con el error personalizado
    final newError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: customException,
      stackTrace: err.stackTrace,
      message: customException.toString(),
    );

    handler.next(newError);
  }

  /// Registra el error en la consola (solo en debug)
  void _logError(DioException error) {
    debugPrint('╔══════════════════════════════════════════════════════════════');
    debugPrint('║ DIO ERROR');
    debugPrint('╟──────────────────────────────────────────────────────────────');
    debugPrint('║ Type: ${error.type}');
    debugPrint('║ Message: ${error.message}');
    debugPrint('║ URL: ${error.requestOptions.uri}');
    debugPrint('║ Method: ${error.requestOptions.method}');

    if (error.response != null) {
      debugPrint('║ Status Code: ${error.response?.statusCode}');
      debugPrint('║ Status Message: ${error.response?.statusMessage}');

      if (error.response?.data != null) {
        debugPrint('║ Response Data: ${error.response?.data}');
      }
    }

    if (error.stackTrace != null) {
      debugPrint('║ StackTrace: ${error.stackTrace}');
    }

    debugPrint('╚══════════════════════════════════════════════════════════════');
  }

  /// Maneja el error y devuelve una excepción personalizada
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return TimeoutException(
          'La conexión tardó demasiado tiempo. Por favor, verifica tu conexión a internet.',
        );

      case DioExceptionType.sendTimeout:
        return TimeoutException(
          'El envío de datos tardó demasiado. Por favor, intenta nuevamente.',
        );

      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          'La recepción de datos tardó demasiado. Por favor, intenta nuevamente.',
        );

      case DioExceptionType.badResponse:
        return _handleResponseError(error);

      case DioExceptionType.cancel:
        return ApiException('La solicitud fue cancelada');

      case DioExceptionType.connectionError:
        return NetworkException(
          'No se pudo conectar al servidor. Verifica tu conexión a internet.',
        );

      case DioExceptionType.badCertificate:
        return ApiException(
          'Error de seguridad: Certificado inválido',
        );

      case DioExceptionType.unknown:
      default:
        if (error.error != null && error.error is Exception) {
          return error.error as Exception;
        }
        return ApiException(
          error.message ?? 'Ha ocurrido un error inesperado',
        );
    }
  }

  /// Maneja errores de respuesta HTTP
  Exception _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // Intentar extraer el mensaje de error del response
    String message = _extractErrorMessage(responseData);

    switch (statusCode) {
      case 400:
        return BadRequestException(message);

      case 401:
        return UnauthorizedException(
          message.isNotEmpty ? message : 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
        );

      case 403:
        return ForbiddenException(
          message.isNotEmpty ? message : 'No tienes permisos para realizar esta acción.',
        );

      case 404:
        return NotFoundException(
          message.isNotEmpty ? message : 'El recurso solicitado no fue encontrado.',
        );

      case 409:
        return ConflictException(
          message.isNotEmpty ? message : 'Conflicto con el estado actual del recurso.',
        );

      case 422:
        // Para errores de validación, intentar extraer los errores de campo
        Map<String, List<String>>? fieldErrors;
        if (responseData is Map && responseData.containsKey('errors')) {
          fieldErrors = _extractFieldErrors(responseData['errors']);
        }
        return ValidationException(
          message.isNotEmpty ? message : 'Error de validación en los datos enviados.',
          errors: fieldErrors,
        );

      case 429:
        return TooManyRequestsException(
          message.isNotEmpty ? message : 'Has realizado demasiadas solicitudes. Por favor, espera un momento.',
        );

      case 500:
        return ServerException(
          'Error interno del servidor. Por favor, intenta más tarde.',
        );

      case 502:
        return ServerException(
          'El servidor no está disponible temporalmente. Por favor, intenta más tarde.',
        );

      case 503:
        return ServerException(
          'Servicio no disponible. Por favor, intenta más tarde.',
        );

      case 504:
        return TimeoutException(
          'El servidor tardó demasiado en responder. Por favor, intenta más tarde.',
        );

      default:
        return ApiException(
          message.isNotEmpty ? message : 'Error desconocido (Código: $statusCode)',
        );
    }
  }

  /// Extrae el mensaje de error del response data
  String _extractErrorMessage(dynamic data) {
    if (data == null) return '';

    if (data is String) {
      return data;
    }

    if (data is Map) {
      // Intentar diferentes formatos comunes de respuesta de error
      if (data.containsKey('error')) {
        if (data['error'] is String) {
          return data['error'];
        } else if (data['error'] is Map && data['error'].containsKey('message')) {
          return data['error']['message'];
        }
      }

      if (data.containsKey('message')) {
        return data['message'];
      }

      if (data.containsKey('msg')) {
        return data['msg'];
      }

      if (data.containsKey('detail')) {
        return data['detail'];
      }

      if (data.containsKey('errors')) {
        if (data['errors'] is String) {
          return data['errors'];
        } else if (data['errors'] is List && data['errors'].isNotEmpty) {
          // Si es una lista de errores, tomar el primero
          final firstError = data['errors'][0];
          if (firstError is String) {
            return firstError;
          } else if (firstError is Map && firstError.containsKey('message')) {
            return firstError['message'];
          }
        }
      }
    }

    return '';
  }

  /// Extrae errores de campo para validaciones
  Map<String, List<String>>? _extractFieldErrors(dynamic errors) {
    if (errors == null || errors is! Map) return null;

    final fieldErrors = <String, List<String>>{};

    errors.forEach((key, value) {
      if (value is List) {
        fieldErrors[key] = value.map((e) => e.toString()).toList();
      } else if (value is String) {
        fieldErrors[key] = [value];
      }
    });

    return fieldErrors.isNotEmpty ? fieldErrors : null;
  }
}