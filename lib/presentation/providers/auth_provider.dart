import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/services/storage_service.dart';

/// Provider del repositorio de autenticación
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider del usuario actual
final currentUserProvider = StateProvider<UserModel?>((ref) {
  return null;
});

/// Provider del estado de autenticación
final authStateProvider = ChangeNotifierProvider<AuthState>((ref) {
  return AuthState(ref);
});

/// Estado de autenticación
class AuthState extends ChangeNotifier {
  final Ref _ref;
  final AuthRepository _authRepository;
  final StorageService _storage = StorageService.instance;

  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _hasCompletedOnboarding = false;
  String? _error;

  AuthState(this._ref) : _authRepository = _ref.read(authRepositoryProvider) {
    _checkAuthStatus();
  }

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  String? get error => _error;

  /// Verificar estado de autenticación inicial
  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Verificar si hay token guardado
      final hasToken = await _storage.hasValidToken();
      _hasCompletedOnboarding = _storage.hasCompletedOnboarding();

      if (hasToken) {
        // Obtener perfil del usuario
        _user = await _authRepository.getCurrentUser();
        _isAuthenticated = true;
        _ref.read(currentUserProvider.notifier).state = _user;
      }
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login con email y contraseña
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authRepository.login(
        email: email,
        password: password,
      );

      _user = response.user;
      _isAuthenticated = true;
      _ref.read(currentUserProvider.notifier).state = _user;

      // Guardar token
      await _storage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isAuthenticated = false;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login con Google
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authRepository.loginWithGoogle();

      _user = response.user;
      _isAuthenticated = true;
      _ref.read(currentUserProvider.notifier).state = _user;

      await _storage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login con Apple
  Future<bool> loginWithApple() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authRepository.loginWithApple();

      _user = response.user;
      _isAuthenticated = true;
      _ref.read(currentUserProvider.notifier).state = _user;

      await _storage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registro con email y contraseña
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authRepository.register(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );

      _user = response.user;
      _isAuthenticated = true;
      _ref.read(currentUserProvider.notifier).state = _user;

      await _storage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();
    } catch (e) {
      // Ignorar errores del servidor en logout
    } finally {
      // Limpiar estado local
      _user = null;
      _isAuthenticated = false;
      _ref.read(currentUserProvider.notifier).state = null;

      // Limpiar storage
      await _storage.clearTokens();
      await _storage.clearCache();

      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualizar perfil de usuario
  Future<bool> updateProfile(UserModel updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.updateProfile(
        displayName: updatedUser.displayName,
        bio: updatedUser.bio,
        photoUrl: updatedUser.photoUrl,
      );

      _ref.read(currentUserProvider.notifier).state = _user;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Marcar onboarding como completado
  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _storage.setOnboardingCompleted();
    notifyListeners();
  }

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refrescar token si es necesario
  Future<void> refreshTokenIfNeeded() async {
    try {
      await _authRepository.refreshToken();
    } catch (e) {
      // Si falla el refresh, hacer logout
      await logout();
    }
  }
}

/// Provider para manejo de formularios de auth
final authFormProvider = StateNotifierProvider<AuthFormNotifier, AuthFormState>((ref) {
  return AuthFormNotifier();
});

/// Estado del formulario de autenticación
class AuthFormState {
  final bool obscurePassword;
  final bool rememberMe;
  final bool acceptedTerms;
  final Map<String, String> errors;

  const AuthFormState({
    this.obscurePassword = true,
    this.rememberMe = false,
    this.acceptedTerms = false,
    this.errors = const {},
  });

  AuthFormState copyWith({
    bool? obscurePassword,
    bool? rememberMe,
    bool? acceptedTerms,
    Map<String, String>? errors,
  }) {
    return AuthFormState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      rememberMe: rememberMe ?? this.rememberMe,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      errors: errors ?? this.errors,
    );
  }
}

/// Notifier para el formulario de autenticación
class AuthFormNotifier extends StateNotifier<AuthFormState> {
  AuthFormNotifier() : super(const AuthFormState());

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleRememberMe() {
    state = state.copyWith(rememberMe: !state.rememberMe);
  }

  void toggleAcceptTerms() {
    state = state.copyWith(acceptedTerms: !state.acceptedTerms);
  }

  void setError(String field, String message) {
    final errors = Map<String, String>.from(state.errors);
    errors[field] = message;
    state = state.copyWith(errors: errors);
  }

  void clearErrors() {
    state = state.copyWith(errors: {});
  }

  void clearError(String field) {
    final errors = Map<String, String>.from(state.errors);
    errors.remove(field);
    state = state.copyWith(errors: errors);
  }

  bool validateEmail(String email) {
    if (email.isEmpty) {
      setError('email', 'El email es requerido');
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setError('email', 'Email inválido');
      return false;
    }

    clearError('email');
    return true;
  }

  bool validatePassword(String password) {
    if (password.isEmpty) {
      setError('password', 'La contraseña es requerida');
      return false;
    }

    if (password.length < 6) {
      setError('password', 'La contraseña debe tener al menos 6 caracteres');
      return false;
    }

    clearError('password');
    return true;
  }

  bool validateUsername(String username) {
    if (username.isEmpty) {
      setError('username', 'El nombre de usuario es requerido');
      return false;
    }

    if (username.length < 3) {
      setError('username', 'El nombre de usuario debe tener al menos 3 caracteres');
      return false;
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(username)) {
      setError('username', 'Solo se permiten letras, números y guion bajo');
      return false;
    }

    clearError('username');
    return true;
  }

  void reset() {
    state = const AuthFormState();
  }
}