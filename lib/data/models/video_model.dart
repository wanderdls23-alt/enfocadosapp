import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'video_model.g.dart';

@JsonSerializable()
class VideoModel extends Equatable {
  final int id;
  final String youtubeId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int? duration; // en segundos
  final String? category;
  final List<String>? tags;
  final int viewsCount;
  final int likesCount;
  final DateTime? publishedAt;
  final DateTime syncedAt;

  const VideoModel({
    required this.id,
    required this.youtubeId,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.duration,
    this.category,
    this.tags,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.publishedAt,
    required this.syncedAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) =>
      _$VideoModelFromJson(json);

  Map<String, dynamic> toJson() => _$VideoModelToJson(this);

  /// Obtiene la URL completa del video en YouTube
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$youtubeId';

  /// Obtiene la URL del thumbnail en alta calidad
  String get highQualityThumbnail =>
      thumbnailUrl ?? 'https://img.youtube.com/vi/$youtubeId/maxresdefault.jpg';

  /// Obtiene la URL del thumbnail en calidad media
  String get mediumQualityThumbnail =>
      thumbnailUrl ?? 'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg';

  /// Obtiene la duración formateada (HH:MM:SS o MM:SS)
  String get formattedDuration {
    if (duration == null) return '';

    final hours = duration! ~/ 3600;
    final minutes = (duration! % 3600) ~/ 60;
    final seconds = duration! % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  /// Obtiene el tiempo publicado en formato relativo
  String get publishedTimeAgo {
    if (publishedAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(publishedAt!);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Hace $years ${years == 1 ? 'año' : 'años'}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Hace $months ${months == 1 ? 'mes' : 'meses'}';
    } else if (difference.inDays > 7) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    } else if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} ${difference.inDays == 1 ? 'día' : 'días'}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} ${difference.inHours == 1 ? 'hora' : 'horas'}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} ${difference.inMinutes == 1 ? 'minuto' : 'minutos'}';
    } else {
      return 'Hace un momento';
    }
  }

  /// Formatea el número de vistas
  String get formattedViews {
    if (viewsCount < 1000) {
      return '$viewsCount vistas';
    } else if (viewsCount < 1000000) {
      final k = (viewsCount / 1000).toStringAsFixed(1);
      return '${k}K vistas';
    } else {
      final m = (viewsCount / 1000000).toStringAsFixed(1);
      return '${m}M vistas';
    }
  }

  /// Formatea el número de likes
  String get formattedLikes {
    if (likesCount < 1000) {
      return likesCount.toString();
    } else if (likesCount < 1000000) {
      final k = (likesCount / 1000).toStringAsFixed(1);
      return '${k}K';
    } else {
      final m = (likesCount / 1000000).toStringAsFixed(1);
      return '${m}M';
    }
  }

  VideoModel copyWith({
    int? id,
    String? youtubeId,
    String? title,
    String? description,
    String? thumbnailUrl,
    int? duration,
    String? category,
    List<String>? tags,
    int? viewsCount,
    int? likesCount,
    DateTime? publishedAt,
    DateTime? syncedAt,
  }) {
    return VideoModel(
      id: id ?? this.id,
      youtubeId: youtubeId ?? this.youtubeId,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      publishedAt: publishedAt ?? this.publishedAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        youtubeId,
        title,
        description,
        thumbnailUrl,
        duration,
        category,
        tags,
        viewsCount,
        likesCount,
        publishedAt,
        syncedAt,
      ];
}

// ============= VIDEO HISTORY =============

@JsonSerializable()
class VideoHistory extends Equatable {
  final int id;
  final String userId;
  final int videoId;
  final int watchedDuration; // en segundos
  final int lastPosition; // último segundo visto
  final bool completed;
  final DateTime watchedAt;
  final VideoModel? video;

  const VideoHistory({
    required this.id,
    required this.userId,
    required this.videoId,
    this.watchedDuration = 0,
    this.lastPosition = 0,
    this.completed = false,
    required this.watchedAt,
    this.video,
  });

  factory VideoHistory.fromJson(Map<String, dynamic> json) =>
      _$VideoHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$VideoHistoryToJson(this);

  /// Obtiene el progreso como porcentaje
  double get progressPercentage {
    if (video == null || video!.duration == null || video!.duration == 0) {
      return 0;
    }
    return (watchedDuration / video!.duration!) * 100;
  }

  /// Verifica si el video fue visto recientemente (últimas 24 horas)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(watchedAt);
    return difference.inHours < 24;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        videoId,
        watchedDuration,
        lastPosition,
        completed,
        watchedAt,
        video,
      ];
}

// ============= VIDEO CATEGORY =============

class VideoCategory {
  final String id;
  final String name;
  final String icon;
  final String color;

  const VideoCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<VideoCategory> categories = [
    VideoCategory(
      id: 'todos',
      name: 'Todos',
      icon: '📺',
      color: '#CC0000',
    ),
    VideoCategory(
      id: 'debates',
      name: 'Debates',
      icon: '💬',
      color: '#9C27B0',
    ),
    VideoCategory(
      id: 'predicas',
      name: 'Prédicas',
      icon: '🎤',
      color: '#3F51B5',
    ),
    VideoCategory(
      id: 'entrevistas',
      name: 'Entrevistas',
      icon: '🎙️',
      color: '#009688',
    ),
    VideoCategory(
      id: 'cursos',
      name: 'Cursos',
      icon: '📚',
      color: '#FF5722',
    ),
    VideoCategory(
      id: 'testimonios',
      name: 'Testimonios',
      icon: '🙏',
      color: '#795548',
    ),
  ];

  static VideoCategory? getCategoryById(String id) {
    try {
      return categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  static VideoCategory? getCategoryByName(String name) {
    try {
      return categories.firstWhere(
        (cat) => cat.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}

// ============= VIDEO LIST RESPONSE =============

@JsonSerializable()
class VideoListResponse extends Equatable {
  final List<VideoModel> videos;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const VideoListResponse({
    required this.videos,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory VideoListResponse.fromJson(Map<String, dynamic> json) =>
      _$VideoListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$VideoListResponseToJson(this);

  /// Obtiene el número total de páginas
  int get totalPages => (total / pageSize).ceil();

  /// Verifica si es la primera página
  bool get isFirstPage => page == 1;

  /// Verifica si es la última página
  bool get isLastPage => !hasMore;

  @override
  List<Object?> get props => [videos, total, page, pageSize, hasMore];
}