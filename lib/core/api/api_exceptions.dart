/// Clase base para todas las excepciones de la API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException(
    this.message, {
    this.statusCode,
    this.data,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException [$statusCode]: $message';
    }
    return 'ApiException: $message';
  }
}

/// Excepción de red - no hay conexión a Internet
class NetworkException extends ApiException {
  const NetworkException([String message = 'Sin conexión a Internet'])
      : super(message);
}

/// Excepción de timeout - la solicitud tardó demasiado
class TimeoutException extends ApiException {
  const TimeoutException([String message = 'La conexión ha tardado demasiado'])
      : super(message);
}

/// Excepción 400 - Bad Request
class BadRequestException extends ApiException {
  const BadRequestException([String message = 'Solicitud incorrecta'])
      : super(message, statusCode: 400);
}

/// Excepción 401 - Unauthorized
class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'No autorizado'])
      : super(message, statusCode: 401);
}

/// Excepción 403 - Forbidden
class ForbiddenException extends ApiException {
  const ForbiddenException([String message = 'Acceso prohibido'])
      : super(message, statusCode: 403);
}

/// Excepción 404 - Not Found
class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Recurso no encontrado'])
      : super(message, statusCode: 404);
}

/// Excepción 409 - Conflict
class ConflictException extends ApiException {
  const ConflictException([String message = 'Conflicto con el estado actual'])
      : super(message, statusCode: 409);
}

/// Excepción 422 - Unprocessable Entity
class ValidationException extends ApiException {
  final Map<String, List<String>>? errors;

  const ValidationException(
    String message, {
    this.errors,
  }) : super(message, statusCode: 422);

  String getFieldError(String field) {
    if (errors == null || !errors!.containsKey(field)) {
      return '';
    }
    return errors![field]!.join(', ');
  }

  List<String> getAllErrors() {
    if (errors == null) return [message];

    final allErrors = <String>[];
    errors!.forEach((field, fieldErrors) {
      allErrors.addAll(fieldErrors);
    });
    return allErrors;
  }
}

/// Excepción 429 - Too Many Requests
class TooManyRequestsException extends ApiException {
  const TooManyRequestsException([
    String message = 'Demasiadas solicitudes. Por favor, espera un momento.',
  ]) : super(message, statusCode: 429);
}

/// Excepción 500+ - Server Error
class ServerException extends ApiException {
  const ServerException([String message = 'Error en el servidor'])
      : super(message, statusCode: 500);
}

/// Excepción de caché - error al leer/escribir en caché
class CacheException extends ApiException {
  const CacheException([String message = 'Error de caché'])
      : super(message);
}

/// Excepción de almacenamiento local
class StorageException extends ApiException {
  const StorageException([String message = 'Error de almacenamiento'])
      : super(message);
}

/// Excepción de parsing - error al parsear datos
class ParsingException extends ApiException {
  const ParsingException([String message = 'Error al procesar datos'])
      : super(message);
}

/// Excepción de permisos
class PermissionException extends ApiException {
  const PermissionException([String message = 'Permisos insuficientes'])
      : super(message);
}

/// Excepción de features no disponibles
class FeatureNotAvailableException extends ApiException {
  const FeatureNotAvailableException([
    String message = 'Esta función no está disponible',
  ]) : super(message);
}

/// Excepción de suscripción requerida
class SubscriptionRequiredException extends ApiException {
  const SubscriptionRequiredException([
    String message = 'Se requiere suscripción para acceder a este contenido',
  ]) : super(message);
}

/// Excepción de contenido no disponible offline
class OfflineContentException extends ApiException {
  const OfflineContentException([
    String message = 'Este contenido no está disponible sin conexión',
  ]) : super(message);
}