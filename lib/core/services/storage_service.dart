import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Servicio para manejar el almacenamiento local de la aplicación
/// Usa FlutterSecureStorage para datos sensibles y SharedPreferences para configuraciones
class StorageService {
  static StorageService? _instance;
  static late SharedPreferences _prefs;
  static const _secureStorage = FlutterSecureStorage();

  // Singleton pattern
  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  // Inicialización
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============= TOKEN MANAGEMENT =============

  /// Guarda los tokens de autenticación
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _secureStorage.write(
        key: AppConstants.storageKeyAccessToken,
        value: accessToken,
      ),
      _secureStorage.write(
        key: AppConstants.storageKeyRefreshToken,
        value: refreshToken,
      ),
    ]);
  }

  /// Obtiene el access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.storageKeyAccessToken);
  }

  /// Obtiene el refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.storageKeyRefreshToken);
  }

  /// Limpia todos los tokens
  Future<void> clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: AppConstants.storageKeyAccessToken),
      _secureStorage.delete(key: AppConstants.storageKeyRefreshToken),
    ]);
  }

  /// Verifica si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ============= USER DATA =============

  /// Guarda los datos del usuario
  Future<void> saveUser(Map<String, dynamic> userData) async {
    final userJson = jsonEncode(userData);
    await _secureStorage.write(
      key: AppConstants.storageKeyUser,
      value: userJson,
    );
  }

  /// Obtiene los datos del usuario
  Future<Map<String, dynamic>?> getUser() async {
    final userJson = await _secureStorage.read(key: AppConstants.storageKeyUser);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }

  /// Limpia los datos del usuario
  Future<void> clearUser() async {
    await _secureStorage.delete(key: AppConstants.storageKeyUser);
  }

  // ============= PREFERENCES =============

  /// Obtiene el tema actual
  String getTheme() {
    return _prefs.getString(AppConstants.storageKeyTheme) ?? 'system';
  }

  /// Guarda el tema
  Future<bool> setTheme(String theme) {
    return _prefs.setString(AppConstants.storageKeyTheme, theme);
  }

  /// Obtiene el idioma
  String getLanguage() {
    return _prefs.getString(AppConstants.storageKeyLanguage) ?? 'es';
  }

  /// Guarda el idioma
  Future<bool> setLanguage(String language) {
    return _prefs.setString(AppConstants.storageKeyLanguage, language);
  }

  /// Verifica si es la primera vez que se abre la app
  bool isFirstTime() {
    return _prefs.getBool(AppConstants.storageKeyFirstTime) ?? true;
  }

  /// Marca que ya no es la primera vez
  Future<bool> setFirstTime(bool value) {
    return _prefs.setBool(AppConstants.storageKeyFirstTime, value);
  }

  /// Obtiene la versión de la Biblia preferida
  String getBibleVersion() {
    return _prefs.getString(AppConstants.storageKeyBibleVersion) ??
           AppConstants.defaultBibleVersion;
  }

  /// Guarda la versión de la Biblia preferida
  Future<bool> setBibleVersion(String version) {
    return _prefs.setString(AppConstants.storageKeyBibleVersion, version);
  }

  /// Obtiene el tamaño de fuente
  double getFontSize() {
    return _prefs.getDouble(AppConstants.storageKeyFontSize) ??
           AppConstants.fontSizeMedium;
  }

  /// Guarda el tamaño de fuente
  Future<bool> setFontSize(double size) {
    return _prefs.setDouble(AppConstants.storageKeyFontSize, size);
  }

  /// Verifica si las notificaciones están habilitadas
  bool areNotificationsEnabled() {
    return _prefs.getBool(AppConstants.storageKeyNotifications) ?? true;
  }

  /// Habilita o deshabilita las notificaciones
  Future<bool> setNotificationsEnabled(bool enabled) {
    return _prefs.setBool(AppConstants.storageKeyNotifications, enabled);
  }

  /// Obtiene la hora del versículo diario
  String getDailyVerseTime() {
    return _prefs.getString(AppConstants.storageKeyDailyVerseTime) ??
           AppConstants.dailyVerseDefaultTime;
  }

  /// Guarda la hora del versículo diario
  Future<bool> setDailyVerseTime(String time) {
    return _prefs.setString(AppConstants.storageKeyDailyVerseTime, time);
  }

  // ============= CACHE MANAGEMENT =============

  /// Guarda datos en caché con una clave específica
  Future<bool> saveToCache(String key, Map<String, dynamic> data) {
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final jsonString = jsonEncode(cacheData);
    return _prefs.setString('cache_$key', jsonString);
  }

  /// Obtiene datos del caché
  Map<String, dynamic>? getFromCache(String key, {Duration? maxAge}) {
    final jsonString = _prefs.getString('cache_$key');
    if (jsonString == null) return null;

    final cacheData = jsonDecode(jsonString) as Map<String, dynamic>;
    final timestamp = cacheData['timestamp'] as int;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;

    // Si maxAge está definido y el caché es más viejo, retornar null
    if (maxAge != null && age > maxAge.inMilliseconds) {
      return null;
    }

    return cacheData['data'] as Map<String, dynamic>;
  }

  /// Limpia un elemento específico del caché
  Future<bool> clearCacheItem(String key) {
    return _prefs.remove('cache_$key');
  }

  /// Limpia todo el caché
  Future<void> clearAllCache() async {
    final keys = _prefs.getKeys().where((key) => key.startsWith('cache_'));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  // ============= GENERIC STORAGE =============

  /// Guarda un string
  Future<bool> setString(String key, String value) {
    return _prefs.setString(key, value);
  }

  /// Obtiene un string
  String? getString(String key) {
    return _prefs.getString(key);
  }

  /// Guarda un bool
  Future<bool> setBool(String key, bool value) {
    return _prefs.setBool(key, value);
  }

  /// Obtiene un bool
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// Guarda un int
  Future<bool> setInt(String key, int value) {
    return _prefs.setInt(key, value);
  }

  /// Obtiene un int
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  /// Guarda un double
  Future<bool> setDouble(String key, double value) {
    return _prefs.setDouble(key, value);
  }

  /// Obtiene un double
  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  /// Guarda una lista de strings
  Future<bool> setStringList(String key, List<String> value) {
    return _prefs.setStringList(key, value);
  }

  /// Obtiene una lista de strings
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  /// Elimina una clave específica
  Future<bool> remove(String key) {
    return _prefs.remove(key);
  }

  /// Verifica si existe una clave
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  // ============= CLEAR ALL =============

  /// Limpia todo el almacenamiento (logout completo)
  Future<void> clearAll() async {
    // Limpiar secure storage
    await _secureStorage.deleteAll();

    // Limpiar shared preferences pero mantener algunas configuraciones
    final theme = getTheme();
    final language = getLanguage();
    final fontSize = getFontSize();

    await _prefs.clear();

    // Restaurar configuraciones básicas
    await setTheme(theme);
    await setLanguage(language);
    await setFontSize(fontSize);
  }

  /// Limpia solo los datos de sesión (mantiene preferencias)
  Future<void> clearSession() async {
    await clearTokens();
    await clearUser();
    await clearAllCache();
  }

  // ============= DEVICE TOKEN =============

  /// Guarda el token del dispositivo para notificaciones
  Future<void> saveDeviceToken(String token) async {
    await _secureStorage.write(key: 'device_token', value: token);
  }

  /// Obtiene el token del dispositivo
  Future<String?> getDeviceToken() async {
    return await _secureStorage.read(key: 'device_token');
  }
}