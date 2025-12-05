import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/video_model.dart';
import '../../providers/video_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';

class VideosScreen extends ConsumerStatefulWidget {
  const VideosScreen({super.key});

  @override
  ConsumerState<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends ConsumerState<VideosScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();

    // Cargar videos iniciales
    Future.microtask(() {
      ref.read(videosProvider.notifier).loadVideos();
    });

    // Listener para paginación infinita
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (ref.read(videosProvider.notifier).hasMore) {
        ref.read(videosProvider.notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(videosProvider);
    final categories = ref.watch(videoCategoriesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(videosProvider.notifier).refresh(),
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
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Videos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        Colors.red.shade800,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        bottom: -30,
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 150,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Botón de búsqueda
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _showSearchDialog,
                ),
                // Botón de historial
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    context.push(Routes.videoHistory);
                  },
                ),
              ],
            ),

            // Categorías
            SliverToBoxAdapter(
              child: Container(
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory == category.id;

                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(category.icon),
                          const SizedBox(width: 4),
                          Text(category.name),
                        ],
                      ),
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category.id : null;
                        });
                        ref.read(videosProvider.notifier).filterByCategory(
                          selected ? category.id : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Lista de videos
            videos.when(
              data: (videoList) {
                if (videoList.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.video_library_outlined,
                      title: 'No hay videos',
                      message: _selectedCategory != null
                          ? 'No hay videos en esta categoría'
                          : 'No hay videos disponibles en este momento',
                      buttonText: _selectedCategory != null ? 'Ver todos' : null,
                      onAction: _selectedCategory != null
                          ? () {
                              setState(() => _selectedCategory = null);
                              ref.read(videosProvider.notifier).filterByCategory(null);
                            }
                          : null,
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == videoList.length) {
                        // Indicador de carga al final
                        return ref.read(videosProvider.notifier).hasMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox(height: 100);
                      }

                      final video = videoList[index];
                      return VideoListItem(
                        video: video,
                        onTap: () {
                          context.push('${Routes.videos}/player/${video.id}');
                        },
                      );
                    },
                    childCount: videoList.length + 1,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: LoadingIndicator(),
              ),
              error: (error, _) => SliverFillRemaining(
                child: CustomErrorWidget(
                  message: 'Error al cargar los videos',
                  onRetry: () {
                    ref.read(videosProvider.notifier).refresh();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';

        return AlertDialog(
          title: const Text('Buscar Videos'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ingresa tu búsqueda...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => searchQuery = value,
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.pop(context);
                ref.read(videosProvider.notifier).searchVideos(value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (searchQuery.isNotEmpty) {
                  Navigator.pop(context);
                  ref.read(videosProvider.notifier).searchVideos(searchQuery);
                }
              },
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
  }
}

/// Widget para cada item de video en la lista
class VideoListItem extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;

  const VideoListItem({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    video.mediumQualityThumbnail,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),

                // Play button overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),

                // Duración
                if (video.duration != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.formattedDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Categoría badge
                if (video.category != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(video.category!),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        video.category!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Información del video
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Estadísticas
                  Row(
                    children: [
                      _buildStat(
                        icon: Icons.remove_red_eye_outlined,
                        value: video.formattedViews,
                      ),
                      const SizedBox(width: 16),
                      _buildStat(
                        icon: Icons.thumb_up_outlined,
                        value: video.formattedLikes,
                      ),
                      const Spacer(),
                      Text(
                        video.publishedTimeAgo,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    final cat = VideoCategory.getCategoryById(category);
    if (cat != null) {
      return Color(int.parse(cat.color.replaceFirst('#', '0xFF')));
    }
    return AppColors.primary;
  }
}