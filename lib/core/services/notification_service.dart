import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handler para mensajes en background
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

/// Servicio de notificaciones
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _initialized = false;

  // Callbacks
  Function(RemoteMessage)? onMessageReceived;
  Function(Map<String, dynamic>)? onNotificationTapped;
  Function(String)? onTokenRefresh;

  /// Obtener token FCM
  String? get fcmToken => _fcmToken;

  /// Inicializar servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Configurar notificaciones locales
      await _setupLocalNotifications();

      // Solicitar permisos
      await _requestPermissions();

      // Obtener token FCM
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Guardar token
      if (_fcmToken != null) {
        await _saveToken(_fcmToken!);
        onTokenRefresh?.call(_fcmToken!);
      }

      // Listener para refresh del token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _saveToken(newToken);
        onTokenRefresh?.call(newToken);
      });

      // Configurar handlers de mensajes
      _setupMessageHandlers();

      // Manejar notificación inicial (si la app fue abierta por una notificación)
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      _initialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Configurar notificaciones locales
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejar tap en notificación local
        if (response.payload != null) {
          final data = json.decode(response.payload!);
          onNotificationTapped?.call(data);
        }
      },
    );

    // Crear canal de notificación para Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'enfocados_tv_channel',
        'Enfocados TV',
        description: 'Notificaciones de Enfocados en Dios TV',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Solicitar permisos
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('Notification permissions status: ${settings.authorizationStatus}');

    if (Platform.isIOS) {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Configurar handlers de mensajes
  void _setupMessageHandlers() {
    // Mensajes en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _handleMessage(message);
      _showLocalNotification(message);
    });

    // App abierta desde notificación (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from notification: ${message.messageId}');
      _handleMessage(message);
    });

    // Background handler (debe ser top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Manejar mensaje recibido
  void _handleMessage(RemoteMessage message) {
    onMessageReceived?.call(message);

    // Navegar según el tipo de notificación
    if (message.data.isNotEmpty) {
      final type = message.data['type'];
      final payload = message.data['payload'];

      switch (type) {
        case 'daily_verse':
          // Navegar a versículo diario
          onNotificationTapped?.call({
            'route': '/daily-verse',
            'data': payload,
          });
          break;
        case 'new_video':
          // Navegar a video
          onNotificationTapped?.call({
            'route': '/videos/player/${payload['videoId']}',
            'data': payload,
          });
          break;
        case 'course_reminder':
          // Navegar a curso
          onNotificationTapped?.call({
            'route': '/academy/course/${payload['courseId']}',
            'data': payload,
          });
          break;
        case 'community':
          // Navegar a comunidad
          onNotificationTapped?.call({
            'route': '/community',
            'data': payload,
          });
          break;
        default:
          // Navegación por defecto
          onNotificationTapped?.call(message.data);
      }
    }
  }

  /// Mostrar notificación local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'enfocados_tv_channel',
      'Enfocados TV',
      channelDescription: 'Notificaciones de Enfocados en Dios TV',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFCC0000),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: json.encode(message.data),
    );
  }

  /// Programar notificación local
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'enfocados_tv_channel',
      'Enfocados TV',
      channelDescription: 'Notificaciones de Enfocados en Dios TV',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFCC0000),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: data != null ? json.encode(data) : null,
    );
  }

  /// Programar versículo diario
  Future<void> scheduleDailyVerse({
    required TimeOfDay time,
    bool enabled = true,
  }) async {
    // Cancelar notificaciones anteriores
    await cancelDailyVerse();

    if (!enabled) return;

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await scheduleNotification(
      title: '📖 Versículo del Día',
      body: '¡Tu versículo diario te está esperando!',
      scheduledDate: scheduledDate,
      data: {'type': 'daily_verse'},
    );

    // Guardar preferencia
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_verse_notifications', enabled);
    await prefs.setString('daily_verse_time', '${time.hour}:${time.minute}');
  }

  /// Cancelar versículo diario
  Future<void> cancelDailyVerse() async {
    await _localNotifications.cancel(1); // ID fijo para versículo diario
  }

  /// Suscribirse a tema
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Desuscribirse de tema
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Guardar token en servidor
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);

    // TODO: Enviar token al servidor backend
    // await ApiClient.updateFcmToken(token);
  }

  /// Limpiar todas las notificaciones
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Obtener badge count (iOS)
  Future<int> getBadgeCount() async {
    if (Platform.isIOS) {
      // Implementar con plugin específico si es necesario
      return 0;
    }
    return 0;
  }

  /// Establecer badge count (iOS)
  Future<void> setBadgeCount(int count) async {
    if (Platform.isIOS) {
      // Implementar con plugin específico si es necesario
    }
  }

  /// Verificar si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Abrir configuración de notificaciones
  Future<void> openNotificationSettings() async {
    await _firebaseMessaging.requestPermission();
  }
}

/// Extension para TimeOfDay
extension TimeOfDayExtension on TimeOfDay {
  DateTime toDateTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}