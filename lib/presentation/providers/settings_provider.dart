import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';

/// Modelo de configuraciones de la app
class AppSettings {
  final bool pushNotificationsEnabled;
  final bool dailyVerseEnabled;
  final TimeOfDay dailyVerseTime;
  final bool videoNotificationsEnabled;
  final bool courseRemindersEnabled;
  final String defaultBibleVersion;
  final double bibleFontSize;
  final bool showVerseNumbers;
  final bool showFootnotes;
  final String videoQuality;
  final bool autoplayEnabled;
  final bool pipEnabled;
  final ThemeMode themeMode;
  final String language;
  final bool offlineModeEnabled;
  final bool dataSaverEnabled;

  const AppSettings({
    this.pushNotificationsEnabled = true,
    this.dailyVerseEnabled = true,
    this.dailyVerseTime = const TimeOfDay(hour: 8, minute: 0),
    this.videoNotificationsEnabled = true,
    this.courseRemindersEnabled = true,
    this.defaultBibleVersion = 'RVR 1960',
    this.bibleFontSize = 16.0,
    this.showVerseNumbers = true,
    this.showFootnotes = true,
    this.videoQuality = 'Auto',
    this.autoplayEnabled = true,
    this.pipEnabled = false,
    this.themeMode = ThemeMode.system,
    this.language = 'Español',
    this.offlineModeEnabled = false,
    this.dataSaverEnabled = false,
  });

  AppSettings copyWith({
    bool? pushNotificationsEnabled,
    bool? dailyVerseEnabled,
    TimeOfDay? dailyVerseTime,
    bool? videoNotificationsEnabled,
    bool? courseRemindersEnabled,
    String? defaultBibleVersion,
    double? bibleFontSize,
    bool? showVerseNumbers,
    bool? showFootnotes,
    String? videoQuality,
    bool? autoplayEnabled,
    bool? pipEnabled,
    ThemeMode? themeMode,
    String? language,
    bool? offlineModeEnabled,
    bool? dataSaverEnabled,
  }) {
    return AppSettings(
      pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      dailyVerseEnabled: dailyVerseEnabled ?? this.dailyVerseEnabled,
      dailyVerseTime: dailyVerseTime ?? this.dailyVerseTime,
      videoNotificationsEnabled: videoNotificationsEnabled ?? this.videoNotificationsEnabled,
      courseRemindersEnabled: courseRemindersEnabled ?? this.courseRemindersEnabled,
      defaultBibleVersion: defaultBibleVersion ?? this.defaultBibleVersion,
      bibleFontSize: bibleFontSize ?? this.bibleFontSize,
      showVerseNumbers: showVerseNumbers ?? this.showVerseNumbers,
      showFootnotes: showFootnotes ?? this.showFootnotes,
      videoQuality: videoQuality ?? this.videoQuality,
      autoplayEnabled: autoplayEnabled ?? this.autoplayEnabled,
      pipEnabled: pipEnabled ?? this.pipEnabled,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      offlineModeEnabled: offlineModeEnabled ?? this.offlineModeEnabled,
      dataSaverEnabled: dataSaverEnabled ?? this.dataSaverEnabled,
    );
  }
}

/// Provider de configuraciones
class SettingsNotifier extends StateNotifier<AppSettings> {
  final NotificationService _notificationService;
  SharedPreferences? _prefs;

  SettingsNotifier(this._notificationService) : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    state = AppSettings(
      pushNotificationsEnabled: _prefs?.getBool('push_notifications') ?? true,
      dailyVerseEnabled: _prefs?.getBool('daily_verse') ?? true,
      dailyVerseTime: _parseTimeOfDay(_prefs?.getString('daily_verse_time') ?? '8:0'),
      videoNotificationsEnabled: _prefs?.getBool('video_notifications') ?? true,
      courseRemindersEnabled: _prefs?.getBool('course_reminders') ?? true,
      defaultBibleVersion: _prefs?.getString('bible_version') ?? 'RVR 1960',
      bibleFontSize: _prefs?.getDouble('bible_font_size') ?? 16.0,
      showVerseNumbers: _prefs?.getBool('show_verse_numbers') ?? true,
      showFootnotes: _prefs?.getBool('show_footnotes') ?? true,
      videoQuality: _prefs?.getString('video_quality') ?? 'Auto',
      autoplayEnabled: _prefs?.getBool('autoplay') ?? true,
      pipEnabled: _prefs?.getBool('pip') ?? false,
      themeMode: _parseThemeMode(_prefs?.getString('theme_mode') ?? 'system'),
      language: _prefs?.getString('language') ?? 'Español',
      offlineModeEnabled: _prefs?.getBool('offline_mode') ?? false,
      dataSaverEnabled: _prefs?.getBool('data_saver') ?? false,
    );
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> updatePushNotifications(bool enabled) async {
    state = state.copyWith(pushNotificationsEnabled: enabled);
    await _prefs?.setBool('push_notifications', enabled);

    if (!enabled) {
      // Desactivar todas las notificaciones
      await _notificationService.clearAllNotifications();
    }
  }

  Future<void> updateDailyVerse(bool enabled) async {
    state = state.copyWith(dailyVerseEnabled: enabled);
    await _prefs?.setBool('daily_verse', enabled);

    if (enabled) {
      await _notificationService.scheduleDailyVerse(
        time: state.dailyVerseTime,
        enabled: true,
      );
    } else {
      await _notificationService.cancelDailyVerse();
    }
  }

  Future<void> updateDailyVerseTime(TimeOfDay time) async {
    state = state.copyWith(dailyVerseTime: time);
    await _prefs?.setString('daily_verse_time', '${time.hour}:${time.minute}');

    if (state.dailyVerseEnabled) {
      await _notificationService.scheduleDailyVerse(
        time: time,
        enabled: true,
      );
    }
  }

  Future<void> updateVideoNotifications(bool enabled) async {
    state = state.copyWith(videoNotificationsEnabled: enabled);
    await _prefs?.setBool('video_notifications', enabled);

    if (enabled) {
      await _notificationService.subscribeToTopic('new_videos');
    } else {
      await _notificationService.unsubscribeFromTopic('new_videos');
    }
  }

  Future<void> updateCourseReminders(bool enabled) async {
    state = state.copyWith(courseRemindersEnabled: enabled);
    await _prefs?.setBool('course_reminders', enabled);

    if (enabled) {
      await _notificationService.subscribeToTopic('course_reminders');
    } else {
      await _notificationService.unsubscribeFromTopic('course_reminders');
    }
  }

  Future<void> updateBibleVersion(String version) async {
    state = state.copyWith(defaultBibleVersion: version);
    await _prefs?.setString('bible_version', version);
  }

  Future<void> updateBibleFontSize(double size) async {
    state = state.copyWith(bibleFontSize: size);
    await _prefs?.setDouble('bible_font_size', size);
  }

  Future<void> updateShowVerseNumbers(bool show) async {
    state = state.copyWith(showVerseNumbers: show);
    await _prefs?.setBool('show_verse_numbers', show);
  }

  Future<void> updateShowFootnotes(bool show) async {
    state = state.copyWith(showFootnotes: show);
    await _prefs?.setBool('show_footnotes', show);
  }

  Future<void> updateVideoQuality(String quality) async {
    state = state.copyWith(videoQuality: quality);
    await _prefs?.setString('video_quality', quality);
  }

  Future<void> updateAutoplay(bool enabled) async {
    state = state.copyWith(autoplayEnabled: enabled);
    await _prefs?.setBool('autoplay', enabled);
  }

  Future<void> updatePip(bool enabled) async {
    state = state.copyWith(pipEnabled: enabled);
    await _prefs?.setBool('pip', enabled);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);

    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      default:
        modeString = 'system';
    }

    await _prefs?.setString('theme_mode', modeString);
  }

  Future<void> updateLanguage(String language) async {
    state = state.copyWith(language: language);
    await _prefs?.setString('language', language);
  }

  Future<void> updateOfflineMode(bool enabled) async {
    state = state.copyWith(offlineModeEnabled: enabled);
    await _prefs?.setBool('offline_mode', enabled);
  }

  Future<void> updateDataSaver(bool enabled) async {
    state = state.copyWith(dataSaverEnabled: enabled);
    await _prefs?.setBool('data_saver', enabled);
  }

  Future<void> resetSettings() async {
    state = const AppSettings();
    await _prefs?.clear();
    await _loadSettings();
  }
}

/// Provider principal de configuraciones
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final notificationService = NotificationService();
  return SettingsNotifier(notificationService);
});

/// Provider para el tema actual
final currentThemeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

/// Provider para el idioma actual
final currentLanguageProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).language;
});

/// Provider para la versión de Biblia predeterminada
final defaultBibleVersionProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).defaultBibleVersion;
});

/// Provider para el tamaño de fuente de la Biblia
final bibleFontSizeProvider = Provider<double>((ref) {
  return ref.watch(settingsProvider).bibleFontSize;
});

/// Provider para modo offline
final offlineModeProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).offlineModeEnabled;
});

/// Provider para modo ahorro de datos
final dataSaverProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).dataSaverEnabled;
});