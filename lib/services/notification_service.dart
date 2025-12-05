import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

import '../core/constants/storage_keys.dart';
import '../domain/entities/notification.dart';
import '../data/repositories/notification_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final NotificationRepository _repository = NotificationRepository();

  // Notification channels
  static const String _dailyVerseChannel = 'daily_verse';
  static const String _prayerReminderChannel = 'prayer_reminder';
  static const String _liveStreamChannel = 'live_stream';
  static const String _courseChannel = 'course';
  static const String _communityChannel = 'community';
  static const String _generalChannel = 'general';

  // Stream controller for notifications
  final List<VoidCallback> _listeners = [];

  bool _initialized = false;
  String? _fcmToken;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _fcm.getToken();
      print('FCM Token: $_fcmToken');

      // Save token to backend
      if (_fcmToken != null) {
        await _repository.updateFCMToken(_fcmToken!);
      }

      // Listen to token refresh
      _fcm.onTokenRefresh.listen((token) {
        _fcmToken = token;
        _repository.updateFCMToken(token);
      });

      // Configure FCM handlers
      _configureFCMHandlers();

      // Schedule local notifications
      await _scheduleLocalNotifications();

      _initialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }

    final settings = await _fcm.getNotificationSettings();
    print('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'daily_verse',
        'Versículo Diario',
        description: 'Notificaciones del versículo del día',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'prayer_reminder',
        'Recordatorios de Oración',
        description: 'Recordatorios para momentos de oración',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'live_stream',
        'Transmisiones en Vivo',
        description: 'Alertas de transmisiones en vivo',
        importance: Importance.max,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'course',
        'Academia',
        description: 'Notificaciones de cursos y lecciones',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'community',
        'Comunidad',
        description: 'Actividad de la comunidad',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      AndroidNotificationChannel(
        'general',
        'General',
        description: 'Notificaciones generales',
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _configureFCMHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      _handleMessage(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened app from background: ${message.messageId}');
      _handleNotificationTap(message.data);
    });

    // Check if app was opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('App opened from terminated state: ${message.messageId}');
        _handleNotificationTap(message.data);
      }
    });
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Show local notification
      await _showLocalNotification(
        title: notification.title ?? 'Enfocados en Dios TV',
        body: notification.body ?? '',
        payload: jsonEncode(data),
        channelId: data['channel'] ?? _generalChannel,
      );
    }

    // Save to local storage
    await _saveNotificationToLocal(AppNotification(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? 'Notificación',
      body: notification?.body ?? '',
      type: data['type'] ?? 'general',
      data: data,
      timestamp: DateTime.now(),
      isRead: false,
    ));

    // Notify listeners
    _notifyListeners();
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'general',
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNotificationTap(data);
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] ?? 'general';
    final targetId = data['targetId'];

    // Navigate based on notification type
    switch (type) {
      case 'daily_verse':
        _navigateTo('/bible/verse/$targetId');
        break;
      case 'live_stream':
        _navigateTo('/videos/live');
        break;
      case 'new_video':
        _navigateTo('/videos/$targetId');
        break;
      case 'course_reminder':
        _navigateTo('/academy/course/$targetId');
        break;
      case 'prayer_request':
        _navigateTo('/community/prayers/$targetId');
        break;
      case 'event':
        _navigateTo('/community/events/$targetId');
        break;
      default:
        _navigateTo('/notifications');
    }
  }

  void _navigateTo(String route) {
    // This should be handled by your navigation service
    // NavigationService().navigateTo(route);
  }

  // Schedule local notifications
  Future<void> _scheduleLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    // Schedule daily verse
    if (prefs.getBool(StorageKeys.dailyVerseEnabled) ?? true) {
      await _scheduleDailyVerse();
    }

    // Schedule prayer reminders
    if (prefs.getBool(StorageKeys.prayerRemindersEnabled) ?? false) {
      await _schedulePrayerReminders();
    }
  }

  Future<void> _scheduleDailyVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(StorageKeys.dailyVerseTime) ?? '08:00';
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    const androidDetails = AndroidNotificationDetails(
      'daily_verse',
      'Versículo Diario',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule daily notification
    await _localNotifications.zonedSchedule(
      1, // Notification ID
      'Versículo del Día',
      'Tu versículo diario te espera',
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _schedulePrayerReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final timesJson = prefs.getString(StorageKeys.prayerTimes);

    if (timesJson != null) {
      final times = List<String>.from(jsonDecode(timesJson));

      for (int i = 0; i < times.length; i++) {
        final parts = times[i].split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        const androidDetails = AndroidNotificationDetails(
          'prayer_reminder',
          'Recordatorio de Oración',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _localNotifications.zonedSchedule(
          100 + i, // Notification ID
          'Momento de Oración',
          'Es hora de conectar con Dios',
          _nextInstanceOfTime(hour, minute),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }

  DateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Public methods
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  Future<void> sendLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<List<AppNotification>> getStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(StorageKeys.notifications);

    if (notificationsJson != null) {
      final List<dynamic> decoded = jsonDecode(notificationsJson);
      return decoded.map((json) => AppNotification.fromJson(json)).toList();
    }

    return [];
  }

  Future<void> markNotificationAsRead(String id) async {
    final notifications = await getStoredNotifications();
    final index = notifications.indexWhere((n) => n.id == id);

    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      await _saveNotifications(notifications);
      _notifyListeners();
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final notifications = await getStoredNotifications();
    final updatedNotifications = notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();

    await _saveNotifications(updatedNotifications);
    _notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    final notifications = await getStoredNotifications();
    notifications.removeWhere((n) => n.id == id);
    await _saveNotifications(notifications);
    _notifyListeners();
  }

  Future<void> clearAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.notifications);
    _notifyListeners();
  }

  Future<int> getUnreadCount() async {
    final notifications = await getStoredNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  // Settings management
  Future<void> updateDailyVerseSettings({
    required bool enabled,
    String? time,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.dailyVerseEnabled, enabled);

    if (time != null) {
      await prefs.setString(StorageKeys.dailyVerseTime, time);
    }

    // Cancel existing and reschedule if enabled
    await _localNotifications.cancel(1);
    if (enabled) {
      await _scheduleDailyVerse();
    }
  }

  Future<void> updatePrayerReminderSettings({
    required bool enabled,
    List<String>? times,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.prayerRemindersEnabled, enabled);

    if (times != null) {
      await prefs.setString(StorageKeys.prayerTimes, jsonEncode(times));
    }

    // Cancel existing reminders
    for (int i = 0; i < 10; i++) {
      await _localNotifications.cancel(100 + i);
    }

    // Reschedule if enabled
    if (enabled) {
      await _schedulePrayerReminders();
    }
  }

  // Private helper methods
  Future<void> _saveNotificationToLocal(AppNotification notification) async {
    final notifications = await getStoredNotifications();
    notifications.insert(0, notification);

    // Keep only last 100 notifications
    if (notifications.length > 100) {
      notifications.removeRange(100, notifications.length);
    }

    await _saveNotifications(notifications);
  }

  Future<void> _saveNotifications(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final json = notifications.map((n) => n.toJson()).toList();
    await prefs.setString(StorageKeys.notifications, jsonEncode(json));
  }

  // Listener management
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // Testing methods (only for development)
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: 'Notificación de Prueba',
      body: 'Esta es una notificación de prueba de Enfocados en Dios TV',
      channelId: _generalChannel,
    );
  }

  Future<void> sendDailyVerseNotification(String verse, String reference) async {
    await _showLocalNotification(
      title: 'Versículo del Día',
      body: '$verse - $reference',
      channelId: _dailyVerseChannel,
      payload: jsonEncode({
        'type': 'daily_verse',
        'verse': verse,
        'reference': reference,
      }),
    );
  }

  Future<void> sendLiveStreamNotification(String title) async {
    await _showLocalNotification(
      title: '🔴 Transmisión en Vivo',
      body: title,
      channelId: _liveStreamChannel,
      payload: jsonEncode({
        'type': 'live_stream',
      }),
    );
  }

  Future<void> sendCourseReminderNotification(String courseName, String lessonTitle) async {
    await _showLocalNotification(
      title: 'Continúa tu aprendizaje',
      body: '$courseName: $lessonTitle',
      channelId: _courseChannel,
      payload: jsonEncode({
        'type': 'course_reminder',
        'course': courseName,
        'lesson': lessonTitle,
      }),
    );
  }

  Future<void> sendCommunityNotification(String type, String message) async {
    await _showLocalNotification(
      title: _getCommunityNotificationTitle(type),
      body: message,
      channelId: _communityChannel,
      payload: jsonEncode({
        'type': type,
      }),
    );
  }

  String _getCommunityNotificationTitle(String type) {
    switch (type) {
      case 'prayer_request':
        return 'Nueva Petición de Oración';
      case 'testimony':
        return 'Nuevo Testimonio';
      case 'event':
        return 'Próximo Evento';
      case 'comment':
        return 'Nuevo Comentario';
      default:
        return 'Actividad en la Comunidad';
    }
  }
}

// Notification entity
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.isRead,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: json['type'],
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'],
    );
  }
}