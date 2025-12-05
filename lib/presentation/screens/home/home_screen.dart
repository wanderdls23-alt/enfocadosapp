import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../providers/daily_verse_provider.dart';
import '../../providers/video_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/home/daily_verse_card.dart';
import '../../widgets/home/featured_video_card.dart';
import '../../widgets/home/course_carousel.dart';
import '../../widgets/home/quick_actions.dart';
import '../../widgets/home/live_indicator.dart';
import '../../widgets/common/notification_badge.dart';
import '../../../presentation/providers/notification_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales
    Future.microtask(() {
      ref.read(dailyVerseProvider.notifier).loadTodayVerse();
      ref.read(videosProvider.notifier).loadVideos();
      ref.read(coursesProvider.notifier).loadFeaturedCourses();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final dailyVerse = ref.watch(dailyVerseProvider);
    final videos = ref.watch(videosProvider);
    final courses = ref.watch(coursesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Enfocados en Dios TV',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (user != null) ...[
                            Text(
                              '¡Hola, ${user.displayName ?? user.username}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                // Live Indicator
                const LiveIndicator(),

                // Notificaciones con badge dinámico
                IconButton(
                  icon: NotificationBadge(
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  onPressed: () {
                    context.push(Routes.notifications);
                  },
                ),

                // Búsqueda
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    context.push(Routes.bibleSearch);
                  },
                ),
              ],
            ),

            // Contenido
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Versículo del día
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: dailyVerse.when(
                      data: (verse) => DailyVerseCard(
                        verse: verse,
                        onTap: () => context.push(Routes.dailyVerse),
                      ),
                      loading: () => const ShimmerDailyVerseCard(),
                      error: (error, _) => CustomErrorWidget(
                        message: 'Error al cargar el versículo',
                        onRetry: () {
                          ref.read(dailyVerseProvider.notifier).loadTodayVerse();
                        },
                      ),
                    ),
                  ),

                  // Acciones rápidas
                  const QuickActions(),

                  // Video destacado
                  _buildSectionHeader(
                    title: 'Video Destacado',
                    icon: Icons.play_circle_outline,
                    onViewAll: () => context.go(Routes.videos),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: videos.when(
                      data: (videoList) {
                        if (videoList.isEmpty) {
                          return const Center(
                            child: Text('No hay videos disponibles'),
                          );
                        }
                        return FeaturedVideoCard(
                          video: videoList.first,
                          onTap: () {
                            context.push('${Routes.videos}/player/${videoList.first.id}');
                          },
                        );
                      },
                      loading: () => const ShimmerFeaturedVideoCard(),
                      error: (error, _) => CustomErrorWidget(
                        message: 'Error al cargar videos',
                        onRetry: () {
                          ref.read(videosProvider.notifier).loadVideos();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cursos destacados
                  _buildSectionHeader(
                    title: 'Cursos Destacados',
                    icon: Icons.school_outlined,
                    onViewAll: () => context.go(Routes.academy),
                  ),
                  courses.when(
                    data: (courseList) {
                      if (courseList.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No hay cursos disponibles'),
                          ),
                        );
                      }
                      return CourseCarousel(
                        courses: courseList,
                        onCourseTap: (course) {
                          context.push('${Routes.academy}/course/${course.id}');
                        },
                      );
                    },
                    loading: () => const ShimmerCourseCarousel(),
                    error: (error, _) => CustomErrorWidget(
                      message: 'Error al cargar cursos',
                      onRetry: () {
                        ref.read(coursesProvider.notifier).loadFeaturedCourses();
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Estadísticas rápidas
                  _buildStatistics(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.read(dailyVerseProvider.notifier).loadTodayVerse(),
      ref.read(videosProvider.notifier).loadVideos(),
      ref.read(coursesProvider.notifier).loadFeaturedCourses(),
    ]);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos días';
    } else if (hour < 18) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onViewAll,
            child: const Text(
              'Ver todos',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.gold.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Tu Progreso Espiritual',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.menu_book,
                value: '7',
                label: 'Días leyendo',
                color: AppColors.primary,
              ),
              _buildStatItem(
                icon: Icons.favorite,
                value: '23',
                label: 'Versículos',
                color: AppColors.gold,
              ),
              _buildStatItem(
                icon: Icons.school,
                value: '3',
                label: 'Cursos',
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}