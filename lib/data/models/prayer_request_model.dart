import 'package:equatable/equatable.dart';

/// Modelo de petición de oración
class PrayerRequest extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? title;
  final String content;
  final String? category;
  final bool isAnonymous;
  final bool isUrgent;
  final int prayerCount;
  final int commentCount;
  final bool? hasPrayed;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? tags;
  final String? bibleReference;

  const PrayerRequest({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.title,
    required this.content,
    this.category,
    this.isAnonymous = false,
    this.isUrgent = false,
    this.prayerCount = 0,
    this.commentCount = 0,
    this.hasPrayed,
    required this.createdAt,
    this.updatedAt,
    this.tags,
    this.bibleReference,
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
        isAnonymous,
        isUrgent,
        prayerCount,
        commentCount,
        hasPrayed,
        createdAt,
        updatedAt,
        tags,
        bibleReference,
      ];

  factory PrayerRequest.fromJson(Map<String, dynamic> json) {
    return PrayerRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String,
      category: json['category'] as String?,
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      isUrgent: json['isUrgent'] as bool? ?? false,
      prayerCount: json['prayerCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      hasPrayed: json['hasPrayed'] as bool?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      bibleReference: json['bibleReference'] as String?,
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
      'isAnonymous': isAnonymous,
      'isUrgent': isUrgent,
      'prayerCount': prayerCount,
      'commentCount': commentCount,
      'hasPrayed': hasPrayed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'tags': tags,
      'bibleReference': bibleReference,
    };
  }

  PrayerRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? title,
    String? content,
    String? category,
    bool? isAnonymous,
    bool? isUrgent,
    int? prayerCount,
    int? commentCount,
    bool? hasPrayed,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? bibleReference,
  }) {
    return PrayerRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isUrgent: isUrgent ?? this.isUrgent,
      prayerCount: prayerCount ?? this.prayerCount,
      commentCount: commentCount ?? this.commentCount,
      hasPrayed: hasPrayed ?? this.hasPrayed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      bibleReference: bibleReference ?? this.bibleReference,
    );
  }
}

/// Categorías de peticiones de oración
enum PrayerCategory {
  health('Salud'),
  family('Familia'),
  work('Trabajo'),
  spiritual('Espiritual'),
  financial('Finanzas'),
  relationships('Relaciones'),
  studies('Estudios'),
  ministry('Ministerio'),
  guidance('Dirección'),
  other('Otro');

  final String displayName;
  const PrayerCategory(this.displayName);
}

/// Comentario en una petición de oración
class PrayerComment {
  final String id;
  final String requestId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;
  final bool isPrayer;
  final String? bibleVerse;

  const PrayerComment({
    required this.id,
    required this.requestId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
    this.isPrayer = false,
    this.bibleVerse,
  });

  factory PrayerComment.fromJson(Map<String, dynamic> json) {
    return PrayerComment(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPrayer: json['isPrayer'] as bool? ?? false,
      bibleVerse: json['bibleVerse'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isPrayer': isPrayer,
      'bibleVerse': bibleVerse,
    };
  }
}

/// Registro de oración
class PrayerLog {
  final String id;
  final String requestId;
  final String userId;
  final DateTime prayedAt;
  final int duration; // En segundos
  final String? note;

  const PrayerLog({
    required this.id,
    required this.requestId,
    required this.userId,
    required this.prayedAt,
    this.duration = 0,
    this.note,
  });

  factory PrayerLog.fromJson(Map<String, dynamic> json) {
    return PrayerLog(
      id: json['id'] as String,
      requestId: json['requestId'] as String,
      userId: json['userId'] as String,
      prayedAt: DateTime.parse(json['prayedAt'] as String),
      duration: json['duration'] as int? ?? 0,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'userId': userId,
      'prayedAt': prayedAt.toIso8601String(),
      'duration': duration,
      'note': note,
    };
  }
}