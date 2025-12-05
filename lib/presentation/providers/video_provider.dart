import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/video_model.dart';
import '../../data/repositories/video_repository.dart';

/// Provider del repositorio de videos
final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  return VideoRepository();
});

/// Provider de la lista de videos
final videosProvider = StateNotifierProvider<VideosNotifier, AsyncValue<List<VideoModel>>>((ref) {
  return VideosNotifier(ref);
});

/// Notifier para la lista de videos
class VideosNotifier extends StateNotifier<AsyncValue<List<VideoModel>>> {
  final Ref _ref;
  late final VideoRepository _repository;

  int _currentPage = 1;
  bool _hasMore = true;
  String? _currentCategory;
  String? _currentSearchQuery;

  VideosNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(videoRepositoryProvider);
  }

  /// Cargar videos iniciales
  Future<void> loadVideos({
    String? category,
    String? search,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      state = const AsyncValue.loading();
    }

    _currentCategory = category;
    _currentSearchQuery = search;

    try {
      final response = await _repository.getVideos(
        page: _currentPage,
        category: category,
        search: search,
      );

      if (refresh || state is! AsyncData) {
        state = AsyncValue.data(response.videos);
      } else {
        final currentVideos = state.value ?? [];
        state = AsyncValue.data([...currentVideos, ...response.videos]);
      }

      _hasMore = response.hasMore;
      _currentPage++;
    } catch (error, stackTrace) {
      if (refresh || state is! AsyncData) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  /// Cargar más videos (paginación)
  Future<void> loadMore() async {
    if (!_hasMore || state is AsyncLoading) return;

    try {
      final response = await _repository.getVideos(
        page: _currentPage,
        category: _currentCategory,
        search: _currentSearchQuery,
      );

      final currentVideos = state.value ?? [];
      state = AsyncValue.data([...currentVideos, ...response.videos]);

      _hasMore = response.hasMore;
      _currentPage++;
    } catch (error) {
      // Mantener videos actuales si falla la carga
    }
  }

  /// Refrescar lista de videos
  Future<void> refresh() async {
    await loadVideos(
      category: _currentCategory,
      search: _currentSearchQuery,
      refresh: true,
    );
  }

  /// Buscar videos
  Future<void> searchVideos(String query) async {
    await loadVideos(search: query, refresh: true);
  }

  /// Filtrar por categoría
  Future<void> filterByCategory(String? category) async {
    await loadVideos(category: category, refresh: true);
  }

  bool get hasMore => _hasMore;
}

/// Provider para un video específico
final videoDetailProvider = FutureProvider.family<VideoModel, int>((ref, videoId) async {
  final repository = ref.read(videoRepositoryProvider);
  return repository.getVideo(videoId);
});

/// Provider del historial de videos
final videoHistoryProvider = StateNotifierProvider<VideoHistoryNotifier, AsyncValue<List<VideoHistory>>>((ref) {
  return VideoHistoryNotifier(ref);
});

/// Notifier para el historial de videos
class VideoHistoryNotifier extends StateNotifier<AsyncValue<List<VideoHistory>>> {
  final Ref _ref;
  late final VideoRepository _repository;

  VideoHistoryNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(videoRepositoryProvider);
  }

  /// Cargar historial
  Future<void> loadHistory() async {
    state = const AsyncValue.loading();

    try {
      final history = await _repository.getWatchHistory();
      state = AsyncValue.data(history);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Actualizar progreso de video
  Future<void> updateProgress({
    required int videoId,
    required int position,
    required int duration,
  }) async {
    try {
      await _repository.updateWatchProgress(
        videoId: videoId,
        position: position,
        duration: duration,
      );

      // Actualizar historial local si está cargado
      final currentState = state;
      if (currentState is AsyncData<List<VideoHistory>>) {
        final updatedHistory = currentState.value.map((item) {
          if (item.videoId == videoId) {
            return VideoHistory(
              id: item.id,
              userId: item.userId,
              videoId: videoId,
              watchedDuration: duration,
              lastPosition: position,
              completed: position >= duration * 0.9, // 90% para marcar como completado
              watchedAt: DateTime.now(),
              video: item.video,
            );
          }
          return item;
        }).toList();

        state = AsyncValue.data(updatedHistory);
      }
    } catch (error) {
      // Ignorar errores de actualización
    }
  }

  /// Limpiar historial
  Future<void> clearHistory() async {
    try {
      await _repository.clearHistory();
      state = const AsyncValue.data([]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider de videos relacionados
final relatedVideosProvider = FutureProvider.family<List<VideoModel>, int>((ref, videoId) async {
  final repository = ref.read(videoRepositoryProvider);
  return repository.getRelatedVideos(videoId);
});

/// Provider de categorías de videos
final videoCategoriesProvider = Provider<List<VideoCategory>>((ref) {
  return VideoCategory.categories;
});

/// Provider del estado de reproducción
final videoPlayerStateProvider = StateNotifierProvider<VideoPlayerNotifier, VideoPlayerState>((ref) {
  return VideoPlayerNotifier();
});

/// Estado del reproductor de video
class VideoPlayerState {
  final bool isPlaying;
  final bool isFullscreen;
  final int position; // en segundos
  final int duration; // en segundos
  final double playbackSpeed;
  final double volume;
  final bool showControls;

  const VideoPlayerState({
    this.isPlaying = false,
    this.isFullscreen = false,
    this.position = 0,
    this.duration = 0,
    this.playbackSpeed = 1.0,
    this.volume = 1.0,
    this.showControls = true,
  });

  double get progress => duration > 0 ? position / duration : 0;

  VideoPlayerState copyWith({
    bool? isPlaying,
    bool? isFullscreen,
    int? position,
    int? duration,
    double? playbackSpeed,
    double? volume,
    bool? showControls,
  }) {
    return VideoPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      isFullscreen: isFullscreen ?? this.isFullscreen,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      volume: volume ?? this.volume,
      showControls: showControls ?? this.showControls,
    );
  }
}

/// Notifier para el reproductor de video
class VideoPlayerNotifier extends StateNotifier<VideoPlayerState> {
  VideoPlayerNotifier() : super(const VideoPlayerState());

  void play() {
    state = state.copyWith(isPlaying: true);
  }

  void pause() {
    state = state.copyWith(isPlaying: false);
  }

  void togglePlayPause() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void setPosition(int position) {
    state = state.copyWith(position: position);
  }

  void setDuration(int duration) {
    state = state.copyWith(duration: duration);
  }

  void setFullscreen(bool fullscreen) {
    state = state.copyWith(isFullscreen: fullscreen);
  }

  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  void setPlaybackSpeed(double speed) {
    state = state.copyWith(playbackSpeed: speed);
  }

  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  void toggleControls() {
    state = state.copyWith(showControls: !state.showControls);
  }

  void reset() {
    state = const VideoPlayerState();
  }
}

/// Provider para sincronizar videos con YouTube
final syncVideosProvider = FutureProvider<void>((ref) async {
  final repository = ref.read(videoRepositoryProvider);
  await repository.syncWithYouTube();
});