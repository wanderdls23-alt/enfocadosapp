import 'package:equatable/equatable.dart';

/// Modelo de testimonio
class Testimony extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String title;
  final String content;
  final String? category;
  final String? imageUrl;
  final String? videoUrl;
  final List<String>? tags;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final int sharesCount;
  final bool isVerified;
  final bool isFeatured;
  final bool? hasLiked;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? bibleReference;
  final List<String>? beforeImages;
  final List<String>? afterImages;

  const Testimony({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.title,
    required this.content,
    this.category,
    this.imageUrl,
    this.videoUrl,
    this.tags,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.sharesCount = 0,
    this.isVerified = false,
    this.isFeatured = false,
    this.hasLiked,
    required this.createdAt,
    this.updatedAt,
    this.bibleReference,
    this.beforeImages,
    this.afterImages,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userAvatar,
        title,
        content,
        category,
        imageUrl,
        videoUrl,
        tags,
        likesCount,
        commentsCount,
        viewsCount,
        sharesCount,
        isVerified,
        isFeatured,
        hasLiked,
        createdAt,
        updatedAt,
        bibleReference,
        beforeImages,
        afterImages,
      ];

  factory Testimony.fromJson(Map<String, dynamic> json) {
    return Testimony(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      viewsCount: json['viewsCount'] as int? ?? 0,
      sharesCount: json['sharesCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      hasLiked: json['hasLiked'] as bool?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      bibleReference: json['bibleReference'] as String?,
      beforeImages: (json['beforeImages'] as List<dynamic>?)?.cast<String>(),
      afterImages: (json['afterImages'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'title': title,
      'content': content,
      'category': category,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'tags': tags,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'viewsCount': viewsCount,
      'sharesCount': sharesCount,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'hasLiked': hasLiked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'bibleReference': bibleReference,
      'beforeImages': beforeImages,
      'afterImages': afterImages,
    };
  }

  Testimony copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? title,
    String? content,
    String? category,
    String? imageUrl,
    String? videoUrl,
    List<String>? tags,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    int? sharesCount,
    bool? isVerified,
    bool? isFeatured,
    bool? hasLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bibleReference,
    List<String>? beforeImages,
    List<String>? afterImages,
  }) {
    return Testimony(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isVerified: isVerified ?? this.isVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      hasLiked: hasLiked ?? this.hasLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bibleReference: bibleReference ?? this.bibleReference,
      beforeImages: beforeImages ?? this.beforeImages,
      afterImages: afterImages ?? this.afterImages,
    );
  }
}

/// Categorías de testimonios
enum TestimonyCategory {
  healing('Sanidad'),
  salvation('Salvación'),
  provision('Provisión'),
  restoration('Restauración'),
  deliverance('Liberación'),
  miracle('Milagro'),
  answered_prayer('Oración Contestada'),
  transformation('Transformación'),
  protection('Protección'),
  guidance('Dirección'),
  other('Otro');

  final String displayName;
  const TestimonyCategory(this.displayName);
}

/// Comentario en un testimonio
class TestimonyComment {
  final String id;
  final String testimonyId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final bool? hasLiked;
  final String? parentId; // Para respuestas a comentarios

  const TestimonyComment({
    required this.id,
    required this.testimonyId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.hasLiked,
    this.parentId,
  });

  factory TestimonyComment.fromJson(Map<String, dynamic> json) {
    return TestimonyComment(
      id: json['id'] as String,
      testimonyId: json['testimonyId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likesCount: json['likesCount'] as int? ?? 0,
      hasLiked: json['hasLiked'] as bool?,
      parentId: json['parentId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testimonyId': testimonyId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'likesCount': likesCount,
      'hasLiked': hasLiked,
      'parentId': parentId,
    };
  }
}

/// Estadísticas de testimonios
class TestimonyStatistics {
  final int totalTestimonies;
  final int totalViews;
  final int totalLikes;
  final int totalShares;
  final Map<String, int> categoriesCount;
  final List<Testimony> featuredTestimonies;
  final List<Testimony> recentTestimonies;
  final List<Testimony> popularTestimonies;

  const TestimonyStatistics({
    required this.totalTestimonies,
    required this.totalViews,
    required this.totalLikes,
    required this.totalShares,
    required this.categoriesCount,
    required this.featuredTestimonies,
    required this.recentTestimonies,
    required this.popularTestimonies,
  });

  factory TestimonyStatistics.fromJson(Map<String, dynamic> json) {
    return TestimonyStatistics(
      totalTestimonies: json['totalTestimonies'] as int,
      totalViews: json['totalViews'] as int,
      totalLikes: json['totalLikes'] as int,
      totalShares: json['totalShares'] as int,
      categoriesCount: Map<String, int>.from(json['categoriesCount'] as Map),
      featuredTestimonies: (json['featuredTestimonies'] as List<dynamic>)
          .map((e) => Testimony.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentTestimonies: (json['recentTestimonies'] as List<dynamic>)
          .map((e) => Testimony.fromJson(e as Map<String, dynamic>))
          .toList(),
      popularTestimonies: (json['popularTestimonies'] as List<dynamic>)
          .map((e) => Testimony.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}