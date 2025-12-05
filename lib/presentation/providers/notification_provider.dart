import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/notification_service.dart';
import '../../data/models/notification_model.dart';

// Provider para el servicio de notificaciones
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Estado de notificaciones
class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final Map<String, bool> preferences;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.preferences = const {},
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
    Map<String, bool>? preferences,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      preferences: preferences ?? this.preferences,
    );
  }
}

// Notifier para manejar el estado de notificaciones
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;
  final Ref ref;

  NotificationNotifier(this._service, this.ref) : super(NotificationState()) {
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    state = state.copyWith(isLoading: true);

    try {
      // Inicializar el servicio
      await _service.initialize();

      // Cargar notificaciones guardadas
      await loadNotifications();

      // Cargar preferencias
      await loadPreferences();

      // Configurar listeners
      _setupNotificationListeners();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al inicializar notificaciones: $e',
      );
    }
  }

  void _setupNotificationListeners() {
    // Escuchar notificaciones en primer plano
    _service.onMessageReceived.listen((notification) {
      _handleNewNotification(notification);
    });

    // Escuchar cuando el usuario toca una notificación
    _service.onNotificationTapped.listen((notification) {
      _handleNotificationTap(notification);
    });
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] ?? 'Nueva notificación',
      body: data['body'] ?? '',
      type: data['type'] ?? 'general',
      timestamp: DateTime.now(),
      isRead: false,
      data: data,
    );

    state = state.copyWith(
      notifications: [notification, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    );

    // Guardar en storage local
    _saveNotifications();
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] ?? 'general';
    final id = data['id'];

    // Marcar como leída si existe
    if (id != null) {
      markAsRead(id);
    }

    // Navegar según el tipo
    _navigateByType(type, data);
  }

  void _navigateByType(String type, Map<String, dynamic> data) {
    // La navegación se manejará en el widget que escucha este provider
    switch (type) {
      case 'daily_verse':
        // Navegar a versículo del día
        break;
      case 'new_video':
        // Navegar a video específico
        if (data['videoId'] != null) {
          // context.push('/videos/player/${data['videoId']}');
        }
        break;
      case 'new_course':
        // Navegar a curso
        if (data['courseId'] != null) {
          // context.push('/academy/course/${data['courseId']}');
        }
        break;
      case 'prayer_reminder':
        // Abrir pantalla de oración
        break;
      case 'event_reminder':
        // Navegar a evento
        if (data['eventId'] != null) {
          // context.push('/community/events/${data['eventId']}');
        }
        break;
    }
  }

  Future<void> loadNotifications() async {
    try {
      // Aquí cargarías las notificaciones del storage local o API
      final notifications = await _loadStoredNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: 'Error al cargar notificaciones: $e');
    }
  }

  Future<List<NotificationModel>> _loadStoredNotifications() async {
    // Simular carga desde storage
    return [];
  }

  Future<void> _saveNotifications() async {
    // Guardar en storage local
    try {
      // Implementar guardado
    } catch (e) {
      print('Error guardando notificaciones: $e');
    }
  }

  Future<void> loadPreferences() async {
    try {
      final prefs = await _service.getNotificationPreferences();
      state = state.copyWith(preferences: prefs);
    } catch (e) {
      state = state.copyWith(error: 'Error al cargar preferencias: $e');
    }
  }

  Future<void> updatePreference(String key, bool value) async {
    try {
      await _service.updateNotificationPreference(key, value);

      final updatedPrefs = Map<String, bool>.from(state.preferences);
      updatedPrefs[key] = value;

      state = state.copyWith(preferences: updatedPrefs);
    } catch (e) {
      state = state.copyWith(error: 'Error al actualizar preferencia: $e');
    }
  }

  void markAsRead(String notificationId) {
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == notificationId && !n.isRead) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );

    _saveNotifications();
  }

  void markAllAsRead() {
    final updatedNotifications = state.notifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    );

    _saveNotifications();
  }

  void clearNotification(String notificationId) {
    final updatedNotifications = state.notifications
        .where((n) => n.id != notificationId)
        .toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );

    _saveNotifications();
  }

  void clearAllNotifications() {
    state = state.copyWith(
      notifications: [],
      unreadCount: 0,
    );

    _saveNotifications();
  }

  Future<void> scheduleDailyVerse(TimeOfDay time) async {
    try {
      await _service.scheduleDailyVerse(time);
    } catch (e) {
      state = state.copyWith(error: 'Error al programar versículo diario: $e');
    }
  }

  Future<void> schedulePrayerReminder(TimeOfDay time, String label) async {
    try {
      await _service.schedulePrayerReminder(time, label);
    } catch (e) {
      state = state.copyWith(error: 'Error al programar recordatorio: $e');
    }
  }

  Future<void> cancelScheduledNotification(int id) async {
    try {
      await _service.cancelScheduledNotification(id);
    } catch (e) {
      state = state.copyWith(error: 'Error al cancelar notificación: $e');
    }
  }

  Future<String?> getToken() async {
    return await _service.getToken();
  }

  Future<void> requestPermission() async {
    try {
      final granted = await _service.requestPermission();
      if (!granted) {
        state = state.copyWith(
          error: 'Permisos de notificación no otorgados',
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Error al solicitar permisos: $e');
    }
  }
}

// Provider para el notifier de notificaciones
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return NotificationNotifier(service, ref);
});

// Provider para el conteo de notificaciones no leídas
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

// Provider para verificar si hay notificaciones nuevas
final hasNewNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(unreadNotificationCountProvider) > 0;
});