class AppConstants {
  // Prevenir instanciación
  AppConstants._();

  // ============= APP INFO =============
  static const String appName = 'Enfocados en Dios TV';
  static const String appNameShort = 'Enfocados TV';
  static const String appDescription = 'Biblia & Academia';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;

  // ============= COMPANY INFO =============
  static const String companyName = 'Enfocados en Dios TV';
  static const String companyWebsite = 'https://www.enfocadosendiostv.com';
  static const String companyEmail = 'info@enfocadosendiostv.com';
  static const String companyPhone = '+1234567890';

  // ============= API CONFIGURATION =============
  static const String apiBaseUrl = 'https://www.enfocadosendiostv.com/api/mobile';
  static const String apiVersion = 'v1';
  static const int apiTimeout = 30000; // 30 segundos
  static const int apiCacheTime = 300000; // 5 minutos

  // ============= STORAGE KEYS =============
  static const String storageKeyAccessToken = 'access_token';
  static const String storageKeyRefreshToken = 'refresh_token';
  static const String storageKeyUser = 'user_data';
  static const String storageKeyTheme = 'theme_mode';
  static const String storageKeyLanguage = 'language';
  static const String storageKeyFirstTime = 'first_time';
  static const String storageKeyBibleVersion = 'bible_version';
  static const String storageKeyFontSize = 'font_size';
  static const String storageKeyNotifications = 'notifications_enabled';
  static const String storageKeyDailyVerseTime = 'daily_verse_time';

  // ============= CACHE KEYS =============
  static const String cacheKeyBibleBooks = 'bible_books';
  static const String cacheKeyBibleVersions = 'bible_versions';
  static const String cacheKeyCategories = 'categories';
  static const String cacheKeyVideos = 'videos';
  static const String cacheKeyCourses = 'courses';

  // ============= PAGINATION =============
  static const int pageSize = 20;
  static const int pageSizeVideos = 12;
  static const int pageSizeCourses = 10;
  static const int pageSizeSearch = 30;
  static const int maxCacheItems = 100;

  // ============= TIMEOUTS =============
  static const int splashDuration = 2000; // 2 segundos
  static const int snackBarDuration = 3000; // 3 segundos
  static const int searchDebounce = 500; // 500ms
  static const int refreshTokenBefore = 60000; // 1 minuto antes de expirar

  // ============= LIMITS =============
  static const int maxNoteLength = 5000;
  static const int maxSearchLength = 100;
  static const int maxPasswordLength = 50;
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxEmailLength = 255;
  static const int maxPhoneLength = 20;

  // ============= BIBLE CONSTANTS =============
  static const int totalBibleBooks = 66;
  static const int oldTestamentBooks = 39;
  static const int newTestamentBooks = 27;
  static const String defaultBibleVersion = 'RVR1960';

  // ============= VIDEO CATEGORIES =============
  static const List<String> videoCategories = [
    'Todos',
    'Debates',
    'Prédicas',
    'Entrevistas',
    'Cursos',
    'Testimonios',
  ];

  // ============= COURSE LEVELS =============
  static const List<String> courseLevels = [
    'Principiante',
    'Intermedio',
    'Avanzado',
  ];

  // ============= SUBSCRIPTION TYPES =============
  static const String subscriptionFree = 'FREE';
  static const String subscriptionPremium = 'PREMIUM';
  static const String subscriptionVip = 'VIP';

  // ============= HIGHLIGHT COLORS =============
  static const List<String> highlightColors = [
    '#FFEB3B', // Yellow
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#E91E63', // Pink
    '#FF9800', // Orange
    '#9C27B0', // Purple
  ];

  // ============= FONT SIZES =============
  static const double fontSizeSmall = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeExtraLarge = 20.0;

  // ============= ANIMATION DURATIONS =============
  static const int animationDurationFast = 200;
  static const int animationDurationNormal = 300;
  static const int animationDurationSlow = 500;

  // ============= REGEX PATTERNS =============
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+?[1-9]\d{1,14}$';
  static const String strongPattern = r'^[HG]\d{1,5}$';
  static const String verseReferencePattern = r'^(\w+)\s+(\d+):(\d+)(-(\d+))?$';

  // ============= ERROR MESSAGES =============
  static const String errorGeneral = 'Ha ocurrido un error. Por favor intenta nuevamente.';
  static const String errorNetwork = 'Sin conexión a Internet';
  static const String errorTimeout = 'La conexión ha tardado demasiado';
  static const String errorUnauthorized = 'Sesión expirada. Por favor inicia sesión nuevamente.';
  static const String errorNotFound = 'Recurso no encontrado';
  static const String errorServer = 'Error en el servidor. Por favor intenta más tarde.';

  // ============= SUCCESS MESSAGES =============
  static const String successLogin = '¡Bienvenido de vuelta!';
  static const String successRegister = '¡Cuenta creada exitosamente!';
  static const String successLogout = 'Sesión cerrada';
  static const String successSaved = 'Guardado exitosamente';
  static const String successDeleted = 'Eliminado exitosamente';
  static const String successUpdated = 'Actualizado exitosamente';

  // ============= VALIDATION MESSAGES =============
  static const String validationRequired = 'Este campo es requerido';
  static const String validationEmail = 'Ingresa un email válido';
  static const String validationPassword = 'La contraseña debe tener al menos 8 caracteres';
  static const String validationPasswordMatch = 'Las contraseñas no coinciden';
  static const String validationPhone = 'Ingresa un número de teléfono válido';

  // ============= PLACEHOLDER TEXTS =============
  static const String placeholderEmail = 'correo@ejemplo.com';
  static const String placeholderPassword = '••••••••';
  static const String placeholderName = 'Juan Pérez';
  static const String placeholderPhone = '+1234567890';
  static const String placeholderSearch = 'Buscar...';
  static const String placeholderNote = 'Escribe tu nota aquí...';

  // ============= BUTTON LABELS =============
  static const String buttonLogin = 'Iniciar Sesión';
  static const String buttonRegister = 'Crear Cuenta';
  static const String buttonLogout = 'Cerrar Sesión';
  static const String buttonSave = 'Guardar';
  static const String buttonCancel = 'Cancelar';
  static const String buttonDelete = 'Eliminar';
  static const String buttonEdit = 'Editar';
  static const String buttonShare = 'Compartir';
  static const String buttonContinue = 'Continuar';
  static const String buttonBack = 'Atrás';
  static const String buttonNext = 'Siguiente';
  static const String buttonFinish = 'Finalizar';
  static const String buttonRetry = 'Reintentar';

  // ============= SOCIAL MEDIA =============
  static const String facebookUrl = 'https://facebook.com/enfocadosendiostv';
  static const String instagramUrl = 'https://instagram.com/enfocadosendiostv';
  static const String youtubeUrl = 'https://youtube.com/@enfocadosendiostv';
  static const String whatsappNumber = '+1234567890';

  // ============= YOUTUBE CONFIG =============
  static const String youtubeChannelId = 'UC_YOUR_CHANNEL_ID';
  static const String youtubeApiKey = 'YOUR_YOUTUBE_API_KEY';
  static const int youtubeMaxResults = 50;

  // ============= FIREBASE CONFIG =============
  static const String firebaseNotificationChannel = 'enfocados_tv_channel';
  static const String firebaseNotificationIcon = '@mipmap/ic_launcher';

  // ============= DAILY VERSE CONFIG =============
  static const String dailyVerseDefaultTime = '08:00';
  static const int dailyVerseHistoryLimit = 30;

  // ============= READING PLAN DURATIONS =============
  static const List<int> readingPlanDurations = [
    7,   // 1 semana
    30,  // 1 mes
    90,  // 3 meses
    180, // 6 meses
    365, // 1 año
  ];

  // ============= FILE EXTENSIONS =============
  static const List<String> imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  static const List<String> videoExtensions = ['.mp4', '.avi', '.mov', '.mkv'];
  static const List<String> documentExtensions = ['.pdf', '.doc', '.docx', '.txt'];

  // ============= FEATURE FLAGS =============
  static const bool enableOfflineMode = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableDailyVerse = true;
  static const bool enableStrong = true;
  static const bool enableCommentary = true;
  static const bool enableReadingPlans = true;
  static const bool enableCommunity = true;
  static const bool enableDownloads = true;

  // ============= DEBUG FLAGS =============
  static const bool debugMode = false;
  static const bool debugShowFps = false;
  static const bool debugShowTouches = false;
  static const bool debugApiCalls = false;
}