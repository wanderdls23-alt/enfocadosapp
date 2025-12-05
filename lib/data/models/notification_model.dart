import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required String title,
    required String body,
    required String type,
    required DateTime timestamp,
    @Default(false) bool isRead,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? category,
    String? actionUrl,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}

// Tipos de notificación
enum NotificationType {
  general('general', 'General'),
  dailyVerse('daily_verse', 'Versículo del Día'),
  newVideo('new_video', 'Nuevo Video'),
  newCourse('new_course', 'Nuevo Curso'),
  prayerReminder('prayer_reminder', 'Recordatorio de Oración'),
  eventReminder('event_reminder', 'Recordatorio de Evento'),
  liveStream('live_stream', 'Transmisión en Vivo'),
  courseUpdate('course_update', 'Actualización de Curso'),
  achievement('achievement', 'Logro Desbloqueado'),
  communityUpdate('community_update', 'Actualización de Comunidad'),
  system('system', 'Sistema');

  final String value;
  final String label;

  const NotificationType(this.value, this.label);

  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.general,
    );
  }
}

// Categorías de notificación para filtrado
enum NotificationCategory {
  all('all', 'Todas'),
  spiritual('spiritual', 'Espiritual'),
  educational('educational', 'Educativo'),
  community('community', 'Comunidad'),
  system('system', 'Sistema');

  final String value;
  final String label;

  const NotificationCategory(this.value, this.label);
}

// Extension para NotificationModel
extension NotificationModelX on NotificationModel {
  NotificationType get notificationType => NotificationType.fromValue(type);

  NotificationCategory get notificationCategory {
    switch (notificationType) {
      case NotificationType.dailyVerse:
      case NotificationType.prayerReminder:
        return NotificationCategory.spiritual;
      case NotificationType.newCourse:
      case NotificationType.courseUpdate:
      case NotificationType.achievement:
        return NotificationCategory.educational;
      case NotificationType.communityUpdate:
      case NotificationType.eventReminder:
        return NotificationCategory.community;
      case NotificationType.system:
      case NotificationType.general:
      case NotificationType.newVideo:
      case NotificationType.liveStream:
        return NotificationCategory.system;
    }
  }

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora mismo';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? category,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      category: category ?? this.category,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}