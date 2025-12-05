import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/themes/app_colors.dart';
import '../../../data/models/video_model.dart';
import '../../providers/video_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final int videoId;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;
  bool _showControls = true;
  int _watchedSeconds = 0;

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _initializePlayer(String youtubeId) {
    _controller = YoutubePlayerController(
      initialVideoId: youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        hideControls: false,
      ),
    );

    // Listener para el progreso
    _controller.addListener(() {
      if (_controller.value.isPlaying) {
        final position = _controller.value.position.inSeconds;
        if (position > _watchedSeconds) {
          _watchedSeconds = position;

          // Actualizar progreso cada 10 segundos
          if (_watchedSeconds % 10 == 0) {
            ref.read(videoHistoryProvider.notifier).updateProgress(
              videoId: widget.videoId,
              position: _watchedSeconds,
              duration: _controller.metadata.duration.inSeconds,
            );
          }
        }
      }

      // Detectar cambio de pantalla completa
      if (_controller.value.isFullScreen != _isFullScreen) {
        setState(() {
          _isFullScreen = _controller.value.isFullScreen;
        });

        if (_isFullScreen) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        } else {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoAsync = ref.watch(videoDetailProvider(widget.videoId));
    final relatedVideos = ref.watch(relatedVideosProvider(widget.videoId));

    return videoAsync.when(
      data: (video) {
        // Inicializar player solo una vez
        if (!_controller.initialVideoId.contains(video.youtubeId)) {
          _initializePlayer(video.youtubeId);
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                // Player
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(
                    controller: _controller,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: AppColors.primary,
                    progressColors: ProgressBarColors(
                      playedColor: AppColors.primary,
                      handleColor: AppColors.primary,
                      bufferedColor: AppColors.primary.withOpacity(0.3),
                    ),
                    onReady: () {
                      // Player listo
                    },
                    onEnded: (metadata) {
                      // Video terminado, marcar como completado
                      ref.read(videoHistoryProvider.notifier).updateProgress(
                        videoId: widget.videoId,
                        position: metadata.duration.inSeconds,
                        duration: metadata.duration.inSeconds,
                      );
                    },
                    topActions: [
                      // Botón de cerrar
                      if (!_isFullScreen)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      const Spacer(),
                      // Título del video
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            video.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Información y videos relacionados
                if (!_isFullScreen)
                  Expanded(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info del video
                            _buildVideoInfo(video),

                            // Acciones
                            _buildVideoActions(video),

                            const Divider(),

                            // Videos relacionados
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Videos Relacionados',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),

                            relatedVideos.when(
                              data: (videos) => ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: videos.length,
                                itemBuilder: (context, index) {
                                  final relatedVideo = videos[index];
                                  return _buildRelatedVideoTile(relatedVideo);
                                },
                              ),
                              loading: () => const ShimmerListItem(),
                              error: (_, __) => const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: LoadingIndicator(
            color: Colors.white,
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CustomErrorWidget(
            message: 'Error al cargar el video',
            onRetry: () {
              ref.invalidate(videoDetailProvider(widget.videoId));
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoInfo(VideoModel video) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            video.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Estadísticas
          Row(
            children: [
              Text(
                video.formattedViews,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                video.publishedTimeAgo,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (video.category != null) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.category!,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (video.description != null) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Descripción',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    video.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoActions(VideoModel video) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Like
          Column(
            children: [
              IconButton(
                onPressed: () {
                  // TODO: Implementar like
                },
                icon: const Icon(Icons.thumb_up_outlined),
              ),
              Text(
                video.formattedLikes,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),

          // Compartir
          IconButton(
            onPressed: () {
              Share.share(
                '${video.title}\n${video.youtubeUrl}\n\nVía Enfocados en Dios TV',
                subject: video.title,
              );
            },
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Compartir',
          ),

          // Descargar
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Descarga disponible próximamente'),
                ),
              );
            },
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Descargar',
          ),

          // Guardar
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video guardado en tu lista'),
                ),
              );
            },
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Guardar',
          ),

          // Ver en YouTube
          IconButton(
            onPressed: () {
              // TODO: Abrir en YouTube
            },
            icon: Image.asset(
              'assets/icons/youtube.png',
              width: 24,
              height: 24,
            ),
            tooltip: 'Ver en YouTube',
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedVideoTile(VideoModel video) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            video.mediumQualityThumbnail,
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        video.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${video.formattedViews} • ${video.publishedTimeAgo}',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      onTap: () {
        // Navegar al nuevo video
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(videoId: video.id),
          ),
        );
      },
    );
  }
}