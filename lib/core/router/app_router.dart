import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/verify_email_screen.dart';
import '../../presentation/screens/main/main_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/bible/bible_screen.dart';
import '../../presentation/screens/bible/chapter_reader_screen.dart';
import '../../presentation/screens/bible/verse_detail_screen.dart';
import '../../presentation/screens/bible/search_screen.dart';
import '../../presentation/screens/videos/videos_screen.dart';
import '../../presentation/screens/videos/video_player_screen.dart';
import '../../presentation/screens/academy/academy_screen.dart';
import '../../presentation/screens/academy/course_detail_screen.dart';
import '../../presentation/screens/academy/lesson_player_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/settings_screen.dart';
import '../../presentation/screens/daily_verse/daily_verse_screen.dart';
import '../../presentation/screens/community/community_screen.dart';
import '../../presentation/screens/community/prayer_wall_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/providers/auth_provider.dart';
import '../constants/route_names.dart';

/// Provider para el router de la aplicación
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authState,

    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isEmailVerified = authState.user?.emailVerified ?? false;
      final hasCompletedOnboarding = authState.hasCompletedOnboarding;

      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final isSplashRoute = state.matchedLocation == Routes.splash;
      final isOnboardingRoute = state.matchedLocation == Routes.onboarding;

      // Si está en splash, no redirigir
      if (isSplashRoute) return null;

      // Si no ha completado onboarding y no está en onboarding
      if (!hasCompletedOnboarding && !isOnboardingRoute && !isSplashRoute) {
        return Routes.onboarding;
      }

      // Si no está logueado y no está en ruta de auth
      if (!isLoggedIn && !isAuthRoute && !isOnboardingRoute) {
        return Routes.login;
      }

      // Si está logueado pero no ha verificado email
      if (isLoggedIn && !isEmailVerified && state.matchedLocation != Routes.verifyEmail) {
        return Routes.verifyEmail;
      }

      // Si está logueado y está en ruta de auth, ir a home
      if (isLoggedIn && isEmailVerified && isAuthRoute) {
        return Routes.home;
      }

      return null;
    },

    routes: [
      // Splash Screen
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.verifyEmail,
        name: 'verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),

      // Main App with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          // Home
          GoRoute(
            path: Routes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Bible
          GoRoute(
            path: Routes.bible,
            name: 'bible',
            builder: (context, state) => const BibleScreen(),
            routes: [
              GoRoute(
                path: 'chapter/:bookId/:chapter',
                name: 'bible-chapter',
                builder: (context, state) {
                  final bookId = int.parse(state.pathParameters['bookId']!);
                  final chapter = int.parse(state.pathParameters['chapter']!);
                  final versionId = int.tryParse(
                    state.uri.queryParameters['version'] ?? '1'
                  ) ?? 1;

                  return ChapterReaderScreen(
                    bookId: bookId,
                    chapter: chapter,
                    versionId: versionId,
                  );
                },
              ),
              GoRoute(
                path: 'verse/:verseId',
                name: 'verse-detail',
                builder: (context, state) {
                  final verseId = int.parse(state.pathParameters['verseId']!);
                  return VerseDetailScreen(verseId: verseId);
                },
              ),
              GoRoute(
                path: 'search',
                name: 'bible-search',
                builder: (context, state) {
                  final query = state.uri.queryParameters['q'];
                  return SearchScreen(initialQuery: query);
                },
              ),
            ],
          ),

          // Videos
          GoRoute(
            path: Routes.videos,
            name: 'videos',
            builder: (context, state) => const VideosScreen(),
            routes: [
              GoRoute(
                path: 'player/:videoId',
                name: 'video-player',
                builder: (context, state) {
                  final videoId = int.parse(state.pathParameters['videoId']!);
                  return VideoPlayerScreen(videoId: videoId);
                },
              ),
            ],
          ),

          // Academy
          GoRoute(
            path: Routes.academy,
            name: 'academy',
            builder: (context, state) => const AcademyScreen(),
            routes: [
              GoRoute(
                path: 'course/:courseId',
                name: 'course-detail',
                builder: (context, state) {
                  final courseId = int.parse(state.pathParameters['courseId']!);
                  return CourseDetailScreen(courseId: courseId);
                },
              ),
              GoRoute(
                path: 'lesson/:lessonId',
                name: 'lesson-player',
                builder: (context, state) {
                  final lessonId = int.parse(state.pathParameters['lessonId']!);
                  final courseId = int.tryParse(
                    state.uri.queryParameters['course'] ?? ''
                  );

                  return LessonPlayerScreen(
                    lessonId: lessonId,
                    courseId: courseId,
                  );
                },
              ),
            ],
          ),

          // Profile
          GoRoute(
            path: Routes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'edit-profile',
                builder: (context, state) => const EditProfileScreen(),
              ),
              GoRoute(
                path: 'settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Daily Verse (Modal)
      GoRoute(
        path: Routes.dailyVerse,
        name: 'daily-verse',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DailyVerseScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
        ),
      ),

      // Community
      GoRoute(
        path: Routes.community,
        name: 'community',
        builder: (context, state) => const CommunityScreen(),
        routes: [
          GoRoute(
            path: 'prayer-wall',
            name: 'prayer-wall',
            builder: (context, state) => const PrayerWallScreen(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => ErrorScreen(
      error: state.error?.toString() ?? 'Ruta no encontrada',
    ),
  );
});

/// Pantalla de error para rutas no encontradas
class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}