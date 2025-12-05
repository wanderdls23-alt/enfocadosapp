/// Nombres de rutas de la aplicación
class Routes {
  Routes._();

  // Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyEmail = '/auth/verify-email';

  // Main
  static const String home = '/home';
  static const String bible = '/bible';
  static const String videos = '/videos';
  static const String academy = '/academy';
  static const String profile = '/profile';

  // Features
  static const String dailyVerse = '/daily-verse';
  static const String community = '/community';
  static const String donations = '/donations';
  static const String notifications = '/notifications';

  // Bible sub-routes
  static const String bibleChapter = '/bible/chapter';
  static const String bibleVerse = '/bible/verse';
  static const String bibleSearch = '/bible/search';
  static const String bibleNotes = '/bible/notes';
  static const String bibleHighlights = '/bible/highlights';
  static const String bibleFavorites = '/bible/favorites';

  // Video sub-routes
  static const String videoPlayer = '/videos/player';
  static const String videoCategories = '/videos/categories';
  static const String videoHistory = '/videos/history';
  static const String videoDownloads = '/videos/downloads';

  // Academy sub-routes
  static const String courseDetail = '/academy/course';
  static const String lessonPlayer = '/academy/lesson';
  static const String myCourses = '/academy/my-courses';
  static const String certificates = '/academy/certificates';

  // Profile sub-routes
  static const String editProfile = '/profile/edit';
  static const String settings = '/profile/settings';
  static const String preferences = '/profile/preferences';
  static const String privacy = '/profile/privacy';
  static const String help = '/profile/help';
  static const String about = '/profile/about';

  // Community sub-routes
  static const String prayerWall = '/community/prayer-wall';
  static const String testimonies = '/community/testimonies';
  static const String groups = '/community/groups';
  static const String events = '/community/events';
}