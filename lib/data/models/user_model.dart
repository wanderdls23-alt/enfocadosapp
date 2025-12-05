import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? avatarUrl;
  final bool emailVerified;
  final SubscriptionType subscriptionType;
  final DateTime? subscriptionEnds;
  final DateTime? lastAppLogin;
  final String? appVersion;
  final String? deviceToken;
  final Platform? platform;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.avatarUrl,
    this.emailVerified = false,
    this.subscriptionType = SubscriptionType.free,
    this.subscriptionEnds,
    this.lastAppLogin,
    this.appVersion,
    this.deviceToken,
    this.platform,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor para crear desde JSON
  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Método para convertir a JSON
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  /// Copia con modificaciones
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? avatarUrl,
    bool? emailVerified,
    SubscriptionType? subscriptionType,
    DateTime? subscriptionEnds,
    DateTime? lastAppLogin,
    String? appVersion,
    String? deviceToken,
    Platform? platform,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionEnds: subscriptionEnds ?? this.subscriptionEnds,
      lastAppLogin: lastAppLogin ?? this.lastAppLogin,
      appVersion: appVersion ?? this.appVersion,
      deviceToken: deviceToken ?? this.deviceToken,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verifica si el usuario tiene suscripción activa
  bool get hasActiveSubscription {
    if (subscriptionType == SubscriptionType.free) return false;
    if (subscriptionEnds == null) return true;
    return subscriptionEnds!.isAfter(DateTime.now());
  }

  /// Verifica si es usuario premium o VIP
  bool get isPremium =>
      subscriptionType == SubscriptionType.premium ||
      subscriptionType == SubscriptionType.vip;

  /// Verifica si es usuario VIP
  bool get isVip => subscriptionType == SubscriptionType.vip;

  /// Obtiene las iniciales del usuario
  String get initials {
    if (name == null || name!.isEmpty) {
      return email.substring(0, 2).toUpperCase();
    }

    final parts = name!.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name!.substring(0, 2).toUpperCase();
  }

  /// Obtiene el nombre para mostrar
  String get displayName => name ?? email.split('@')[0];

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        phone,
        avatarUrl,
        emailVerified,
        subscriptionType,
        subscriptionEnds,
        lastAppLogin,
        appVersion,
        deviceToken,
        platform,
        createdAt,
        updatedAt,
      ];
}

/// Enum para tipos de suscripción
enum SubscriptionType {
  @JsonValue('FREE')
  free,
  @JsonValue('PREMIUM')
  premium,
  @JsonValue('VIP')
  vip,
}

/// Extension para SubscriptionType
extension SubscriptionTypeExtension on SubscriptionType {
  String get displayName {
    switch (this) {
      case SubscriptionType.free:
        return 'Gratis';
      case SubscriptionType.premium:
        return 'Premium';
      case SubscriptionType.vip:
        return 'VIP';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionType.free:
        return 'Acceso básico a la aplicación';
      case SubscriptionType.premium:
        return 'Acceso completo a contenido premium';
      case SubscriptionType.vip:
        return 'Acceso total con beneficios exclusivos';
    }
  }
}

/// Enum para plataforma
enum Platform {
  @JsonValue('IOS')
  ios,
  @JsonValue('ANDROID')
  android,
  @JsonValue('WEB')
  web,
}

/// Modelo para preferencias del usuario
@JsonSerializable()
class UserPreferences extends Equatable {
  final int defaultBibleVersion;
  final double fontSize;
  final ThemeMode theme;
  final NotificationSettings notifications;
  final String language;

  const UserPreferences({
    this.defaultBibleVersion = 1,
    this.fontSize = 16.0,
    this.theme = ThemeMode.system,
    this.notifications = const NotificationSettings(),
    this.language = 'es',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);

  UserPreferences copyWith({
    int? defaultBibleVersion,
    double? fontSize,
    ThemeMode? theme,
    NotificationSettings? notifications,
    String? language,
  }) {
    return UserPreferences(
      defaultBibleVersion: defaultBibleVersion ?? this.defaultBibleVersion,
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      notifications: notifications ?? this.notifications,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [
        defaultBibleVersion,
        fontSize,
        theme,
        notifications,
        language,
      ];
}

/// Enum para modo de tema
enum ThemeMode {
  @JsonValue('light')
  light,
  @JsonValue('dark')
  dark,
  @JsonValue('system')
  system,
}

/// Modelo para configuración de notificaciones
@JsonSerializable()
class NotificationSettings extends Equatable {
  final bool dailyVerse;
  final String dailyVerseTime;
  final bool newVideos;
  final bool courseUpdates;
  final bool events;

  const NotificationSettings({
    this.dailyVerse = true,
    this.dailyVerseTime = '08:00',
    this.newVideos = true,
    this.courseUpdates = true,
    this.events = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);

  NotificationSettings copyWith({
    bool? dailyVerse,
    String? dailyVerseTime,
    bool? newVideos,
    bool? courseUpdates,
    bool? events,
  }) {
    return NotificationSettings(
      dailyVerse: dailyVerse ?? this.dailyVerse,
      dailyVerseTime: dailyVerseTime ?? this.dailyVerseTime,
      newVideos: newVideos ?? this.newVideos,
      courseUpdates: courseUpdates ?? this.courseUpdates,
      events: events ?? this.events,
    );
  }

  @override
  List<Object?> get props => [
        dailyVerse,
        dailyVerseTime,
        newVideos,
        courseUpdates,
        events,
      ];
}