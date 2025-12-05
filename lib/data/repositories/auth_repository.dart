import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/services/storage_service.dart';
import '../models/user_model.dart';

/// Repositorio para manejar la autenticación
class AuthRepository {
  final ApiClient _apiClient = ApiClient.instance;
  final StorageService _storage = StorageService.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Login con email y contraseña
  Future<AuthResponse> login(String email, String password) async {
    try {
      // Obtener información del dispositivo
      final deviceData = await _getDeviceInfo();

      final response = await _apiClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'deviceToken': await _storage.getDeviceToken(),
          'platform': deviceData['platform'],
          'deviceInfo': deviceData,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final authData = AuthResponse.fromJson(response.data['data']);

        // Guardar tokens y datos del usuario
        await _saveAuthData(authData);

        return authData;
      } else {
        throw ApiException('Error al iniciar sesión');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al iniciar sesión');
    }
  }

  /// Registro de nuevo usuario
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final deviceData = await _getDeviceInfo();

      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
          'deviceToken': await _storage.getDeviceToken(),
          'platform': deviceData['platform'],
          'deviceInfo': deviceData,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final authData = AuthResponse.fromJson(response.data['data']);

        // Guardar tokens y datos del usuario
        await _saveAuthData(authData);

        return authData;
      } else {
        throw ApiException('Error al crear la cuenta');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al crear la cuenta');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      // Intentar hacer logout en el servidor
      await _apiClient.post('/auth/logout');
    } catch (e) {
      // Si falla, continuar con el logout local
    } finally {
      // Limpiar datos locales
      await _storage.clearSession();
      _apiClient.removeAuthToken();
    }
  }

  /// Refrescar token
  Future<void> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();

      if (refreshToken == null) {
        throw UnauthorizedException('No hay token de refresco disponible');
      }

      final response = await _apiClient.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];

        await _storage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'] ?? refreshToken,
        );

        _apiClient.setAuthToken(data['accessToken']);
      } else {
        throw UnauthorizedException('Error al refrescar el token');
      }
    } catch (e) {
      throw UnauthorizedException('Error al refrescar la sesión');
    }
  }

  /// Recuperar contraseña
  Future<void> forgotPassword(String email) async {
    try {
      final response = await _apiClient.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw ApiException('Error al enviar el correo de recuperación');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al procesar la solicitud');
    }
  }

  /// Resetear contraseña
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await _apiClient.post(
        '/auth/reset-password',
        data: {
          'token': token,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw ApiException('Error al cambiar la contraseña');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al procesar la solicitud');
    }
  }

  /// Verificar email
  Future<void> verifyEmail(String token) async {
    try {
      final response = await _apiClient.post(
        '/auth/verify-email',
        data: {'token': token},
      );

      if (response.statusCode != 200) {
        throw ApiException('Error al verificar el email');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al procesar la solicitud');
    }
  }

  /// Reenviar email de verificación
  Future<void> resendVerificationEmail() async {
    try {
      final response = await _apiClient.post('/auth/resend-verification');

      if (response.statusCode != 200) {
        throw ApiException('Error al enviar el email de verificación');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al procesar la solicitud');
    }
  }

  /// Obtener usuario actual
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _apiClient.get('/auth/me');

      if (response.statusCode == 200 && response.data != null) {
        final user = UserModel.fromJson(response.data['data']);

        // Actualizar datos locales
        await _storage.saveUser(user.toJson());

        return user;
      } else {
        throw ApiException('Error al obtener datos del usuario');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al obtener datos del usuario');
    }
  }

  /// Actualizar perfil
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '/auth/profile',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final user = UserModel.fromJson(response.data['data']);

        // Actualizar datos locales
        await _storage.saveUser(user.toJson());

        return user;
      } else {
        throw ApiException('Error al actualizar el perfil');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al actualizar el perfil');
    }
  }

  /// Cambiar contraseña
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _apiClient.put(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode != 200) {
        throw ApiException('Error al cambiar la contraseña');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al cambiar la contraseña');
    }
  }

  /// Eliminar cuenta
  Future<void> deleteAccount(String password) async {
    try {
      final response = await _apiClient.delete(
        '/auth/account',
        data: {'password': password},
      );

      if (response.statusCode == 200) {
        // Limpiar datos locales
        await _storage.clearAll();
        _apiClient.removeAuthToken();
      } else {
        throw ApiException('Error al eliminar la cuenta');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al eliminar la cuenta');
    }
  }

  /// Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final token = await _storage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Obtener token almacenado
  Future<String?> getStoredToken() async {
    return await _storage.getAccessToken();
  }

  /// Actualizar token del dispositivo para notificaciones
  Future<void> updateDeviceToken(String token) async {
    try {
      await _storage.saveDeviceToken(token);

      // Si el usuario está autenticado, actualizar en el servidor
      if (await isAuthenticated()) {
        await _apiClient.put(
          '/auth/device-token',
          data: {'deviceToken': token},
        );
      }
    } catch (e) {
      // Silently fail - no es crítico
    }
  }

  // ============= MÉTODOS PRIVADOS =============

  /// Guardar datos de autenticación
  Future<void> _saveAuthData(AuthResponse authData) async {
    // Guardar tokens
    await _storage.saveTokens(
      accessToken: authData.accessToken,
      refreshToken: authData.refreshToken,
    );

    // Guardar datos del usuario
    await _storage.saveUser(authData.user.toJson());

    // Configurar token en el cliente API
    _apiClient.setAuthToken(authData.accessToken);
  }

  /// Obtener información del dispositivo
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    Map<String, dynamic> deviceData = {};

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData = {
          'platform': 'ANDROID',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'deviceId': androidInfo.id,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceData = {
          'platform': 'IOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'deviceId': iosInfo.identifierForVendor,
        };
      }
    } catch (e) {
      // Si falla, enviar información básica
      deviceData = {
        'platform': Platform.isAndroid ? 'ANDROID' : 'IOS',
      };
    }

    return deviceData;
  }
}

/// Modelo de respuesta de autenticación
class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user']),
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }
}