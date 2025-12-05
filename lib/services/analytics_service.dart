import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Configuración inicial
  Future<void> initialize() async {
    await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    await _logAppOpen();
  }

  // ==================== EVENTOS DE USUARIO ====================

  // Login de usuario
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
    await _setUserProperty('login_method', method);
  }

  // Registro de usuario
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
    await _setUserProperty('signup_method', method);
  }

  // Logout de usuario
  Future<void> logLogout() async {
    await _analytics.logEvent(
      name: 'logout',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Establecer ID de usuario
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(userId: userId);
  }

  // Establecer propiedades del usuario
  Future<void> setUserProperties({
    String? name,
    String? email,
    String? membershipLevel,
    bool? isPremium,
  }) async {
    if (name != null) {
      await _setUserProperty('user_name', name);
    }
    if (email != null) {
      await _setUserProperty('user_email', email);
    }
    if (membershipLevel != null) {
      await _setUserProperty('membership_level', membershipLevel);
    }
    if (isPremium != null) {
      await _setUserProperty('is_premium', isPremium.toString());
    }
  }

  // ==================== EVENTOS DE BIBLIA ====================

  // Lectura de capítulo
  Future<void> logBibleChapterRead({
    required String book,
    required int chapter,
    required int readTime,
  }) async {
    await _analytics.logEvent(
      name: 'bible_chapter_read',
      parameters: {
        'book': book,
        'chapter': chapter,
        'read_time_seconds': readTime,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Búsqueda en la Biblia
  Future<void> logBibleSearch({
    required String query,
    required int resultsCount,
  }) async {
    await _analytics.logEvent(
      name: 'bible_search',
      parameters: {
        'search_term': query,
        'results_count': resultsCount,
      },
    );
  }

  // Versículo marcado como favorito
  Future<void> logBibleVerseFavorited({
    required String reference,
    required String book,
    required int chapter,
    required int verse,
  }) async {
    await _analytics.logEvent(
      name: 'bible_verse_favorited',
      parameters: {
        'reference': reference,
        'book': book,
        'chapter': chapter,
        'verse': verse,
      },
    );
  }

  // Versículo compartido
  Future<void> logBibleVerseShared({
    required String reference,
    required String platform,
  }) async {
    await _analytics.logShare(
      contentType: 'bible_verse',
      itemId: reference,
      method: platform,
    );
  }

  // Concordancia Strong consultada
  Future<void> logStrongConcordanceView(String strongNumber) async {
    await _analytics.logEvent(
      name: 'strong_concordance_view',
      parameters: {
        'strong_number': strongNumber,
      },
    );
  }

  // Plan de lectura iniciado
  Future<void> logReadingPlanStarted({
    required String planId,
    required String planName,
    required int durationDays,
  }) async {
    await _analytics.logEvent(
      name: 'reading_plan_started',
      parameters: {
        'plan_id': planId,
        'plan_name': planName,
        'duration_days': durationDays,
      },
    );
  }

  // Plan de lectura completado
  Future<void> logReadingPlanCompleted({
    required String planId,
    required String planName,
    required int completionDays,
  }) async {
    await _analytics.logEvent(
      name: 'reading_plan_completed',
      parameters: {
        'plan_id': planId,
        'plan_name': planName,
        'completion_days': completionDays,
      },
    );
  }

  // ==================== EVENTOS DE VIDEOS ====================

  // Video iniciado
  Future<void> logVideoStart({
    required String videoId,
    required String title,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'video_start',
      parameters: {
        'video_id': videoId,
        'video_title': title,
        'video_category': category,
      },
    );
  }

  // Video completado
  Future<void> logVideoComplete({
    required String videoId,
    required String title,
    required int watchTime,
  }) async {
    await _analytics.logEvent(
      name: 'video_complete',
      parameters: {
        'video_id': videoId,
        'video_title': title,
        'watch_time_seconds': watchTime,
      },
    );
  }

  // Video compartido
  Future<void> logVideoShared({
    required String videoId,
    required String title,
    required String platform,
  }) async {
    await _analytics.logShare(
      contentType: 'video',
      itemId: videoId,
      method: platform,
    );
  }

  // Live stream visto
  Future<void> logLiveStreamViewed({
    required String streamId,
    required int watchTime,
  }) async {
    await _analytics.logEvent(
      name: 'live_stream_viewed',
      parameters: {
        'stream_id': streamId,
        'watch_time_seconds': watchTime,
      },
    );
  }

  // ==================== EVENTOS DE ACADEMIA ====================

  // Inscripción en curso
  Future<void> logCourseEnrollment({
    required String courseId,
    required String courseName,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'course_enrollment',
      parameters: {
        'course_id': courseId,
        'course_name': courseName,
        'course_category': category,
      },
    );
  }

  // Lección completada
  Future<void> logLessonComplete({
    required String courseId,
    required String lessonId,
    required String lessonTitle,
    required int lessonNumber,
  }) async {
    await _analytics.logEvent(
      name: 'lesson_complete',
      parameters: {
        'course_id': courseId,
        'lesson_id': lessonId,
        'lesson_title': lessonTitle,
        'lesson_number': lessonNumber,
      },
    );
  }

  // Curso completado
  Future<void> logCourseComplete({
    required String courseId,
    required String courseName,
    required int completionDays,
  }) async {
    await _analytics.logEvent(
      name: 'course_complete',
      parameters: {
        'course_id': courseId,
        'course_name': courseName,
        'completion_days': completionDays,
      },
    );
  }

  // Quiz completado
  Future<void> logQuizComplete({
    required String quizId,
    required int score,
    required int totalQuestions,
  }) async {
    await _analytics.logEvent(
      name: 'quiz_complete',
      parameters: {
        'quiz_id': quizId,
        'score': score,
        'total_questions': totalQuestions,
        'percentage': (score * 100 / totalQuestions).round(),
      },
    );
  }

  // Certificado generado
  Future<void> logCertificateGenerated({
    required String courseId,
    required String certificateId,
  }) async {
    await _analytics.logEvent(
      name: 'certificate_generated',
      parameters: {
        'course_id': courseId,
        'certificate_id': certificateId,
      },
    );
  }

  // ==================== EVENTOS DE COMUNIDAD ====================

  // Petición de oración publicada
  Future<void> logPrayerRequestPosted() async {
    await _analytics.logEvent(
      name: 'prayer_request_posted',
    );
  }

  // Oración por otros
  Future<void> logPrayerForOthers(String requestId) async {
    await _analytics.logEvent(
      name: 'prayer_for_others',
      parameters: {
        'request_id': requestId,
      },
    );
  }

  // Testimonio compartido
  Future<void> logTestimonyShared() async {
    await _analytics.logEvent(
      name: 'testimony_shared',
    );
  }

  // Evento marcado para asistir
  Future<void> logEventRegistration({
    required String eventId,
    required String eventName,
    required String eventType,
  }) async {
    await _analytics.logEvent(
      name: 'event_registration',
      parameters: {
        'event_id': eventId,
        'event_name': eventName,
        'event_type': eventType,
      },
    );
  }

  // ==================== EVENTOS DE DONACIONES ====================

  // Donación iniciada
  Future<void> logDonationStarted({
    required double amount,
    required String currency,
    required String type,
  }) async {
    await _analytics.logEvent(
      name: 'donation_started',
      parameters: {
        'value': amount,
        'currency': currency,
        'donation_type': type,
      },
    );
  }

  // Donación completada
  Future<void> logDonationCompleted({
    required double amount,
    required String currency,
    required String type,
    required String paymentMethod,
  }) async {
    await _analytics.logPurchase(
      currency: currency,
      value: amount,
      items: [
        AnalyticsEventItem(
          itemName: 'donation_$type',
          itemCategory: 'donation',
          price: amount,
          quantity: 1,
        ),
      ],
    );

    await _analytics.logEvent(
      name: 'donation_completed',
      parameters: {
        'value': amount,
        'currency': currency,
        'donation_type': type,
        'payment_method': paymentMethod,
      },
    );
  }

  // ==================== EVENTOS DE NAVEGACIÓN ====================

  // Pantalla vista
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // Tab cambiado
  Future<void> logTabChange({
    required String fromTab,
    required String toTab,
  }) async {
    await _analytics.logEvent(
      name: 'tab_change',
      parameters: {
        'from_tab': fromTab,
        'to_tab': toTab,
      },
    );
  }

  // ==================== EVENTOS DE ENGAGEMENT ====================

  // App abierta
  Future<void> _logAppOpen() async {
    await _analytics.logAppOpen();
  }

  // Sesión iniciada
  Future<void> logSessionStart() async {
    await _analytics.logEvent(
      name: 'session_start',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Notificación recibida
  Future<void> logNotificationReceived({
    required String type,
    required String? campaignId,
  }) async {
    await _analytics.logEvent(
      name: 'notification_receive',
      parameters: {
        'notification_type': type,
        if (campaignId != null) 'campaign_id': campaignId,
      },
    );
  }

  // Notificación abierta
  Future<void> logNotificationOpen({
    required String type,
    required String? campaignId,
  }) async {
    await _analytics.logEvent(
      name: 'notification_open',
      parameters: {
        'notification_type': type,
        if (campaignId != null) 'campaign_id': campaignId,
      },
    );
  }

  // ==================== EVENTOS DE CONFIGURACIÓN ====================

  // Tema cambiado
  Future<void> logThemeChanged(String theme) async {
    await _analytics.logEvent(
      name: 'theme_changed',
      parameters: {
        'theme': theme,
      },
    );
    await _setUserProperty('preferred_theme', theme);
  }

  // Idioma cambiado
  Future<void> logLanguageChanged(String language) async {
    await _analytics.logEvent(
      name: 'language_changed',
      parameters: {
        'language': language,
      },
    );
    await _setUserProperty('preferred_language', language);
  }

  // Tamaño de fuente cambiado
  Future<void> logFontSizeChanged(String size) async {
    await _analytics.logEvent(
      name: 'font_size_changed',
      parameters: {
        'size': size,
      },
    );
    await _setUserProperty('preferred_font_size', size);
  }

  // ==================== EVENTOS DE ERROR ====================

  // Error capturado
  Future<void> logError({
    required String error,
    required String? stackTrace,
    required String screen,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_message': error.substring(0, 100), // Limitar longitud
        'screen': screen,
        'has_stack_trace': stackTrace != null,
      },
    );
  }

  // ==================== UTILIDADES PRIVADAS ====================

  Future<void> _setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(
      name: name,
      value: value,
    );
  }

  // ==================== EVENTOS PERSONALIZADOS ====================

  // Evento personalizado genérico
  Future<void> logCustomEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  // ==================== SEGUIMIENTO DE CONVERSIÓN ====================

  // Objetivo completado
  Future<void> logGoalCompleted({
    required String goalName,
    required Map<String, dynamic> parameters,
  }) async {
    await _analytics.logEvent(
      name: 'goal_completed',
      parameters: {
        'goal_name': goalName,
        ...parameters,
      },
    );
  }

  // ==================== A/B TESTING ====================

  // Experimento visto
  Future<void> logExperimentViewed({
    required String experimentId,
    required String variant,
  }) async {
    await _analytics.logEvent(
      name: 'experiment_viewed',
      parameters: {
        'experiment_id': experimentId,
        'variant': variant,
      },
    );
    await _setUserProperty('experiment_$experimentId', variant);
  }
}