import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'bible_models.dart';

part 'daily_verse_model.g.dart';

// ============= DAILY VERSE MODEL =============

@JsonSerializable()
class DailyVerseModel extends Equatable {
  final int id;
  final String userId;
  final int verseId;
  final String? reason;
  final double? aiScore;
  final DateTime shownDate;
  final bool wasRead;
  final bool wasShared;
  final int? userRating;
  final BibleVerse? verse;

  const DailyVerseModel({
    required this.id,
    required this.userId,
    required this.verseId,
    this.reason,
    this.aiScore,
    required this.shownDate,
    this.wasRead = false,
    this.wasShared = false,
    this.userRating,
    this.verse,
  });

  factory DailyVerseModel.fromJson(Map<String, dynamic> json) =>
      _$DailyVerseModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyVerseModelToJson(this);

  /// Obtiene el texto del versículo
  String get verseText => verse?.text ?? '';

  /// Obtiene la referencia del versículo
  String get verseReference => verse?.reference ?? '';

  /// Obtiene el libro del versículo
  String get bookName => verse?.book?.name ?? '';

  /// Obtiene el capítulo
  int get chapter => verse?.chapter ?? 0;

  /// Obtiene el número del versículo
  int get verseNumber => verse?.verse ?? 0;

  /// Verifica si el versículo fue calificado
  bool get wasRated => userRating != null && userRating! > 0;

  /// Obtiene la razón formateada
  String get formattedReason {
    if (reason == null || reason!.isEmpty) {
      return 'Seleccionado especialmente para ti';
    }
    return reason!;
  }

  /// Obtiene la fecha formateada
  String get formattedDate {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    final day = shownDate.day;
    final month = months[shownDate.month - 1];
    final year = shownDate.year;

    return '$day de $month, $year';
  }

  /// Verifica si es el versículo de hoy
  bool get isToday {
    final now = DateTime.now();
    return shownDate.year == now.year &&
           shownDate.month == now.month &&
           shownDate.day == now.day;
  }

  /// Obtiene el mensaje para compartir
  String get shareMessage {
    return '''
$verseText

$verseReference

📱 Enfocados en Dios TV App
Descárgala en: https://enfocadosendiostv.com/app
    '''.trim();
  }

  DailyVerseModel copyWith({
    int? id,
    String? userId,
    int? verseId,
    String? reason,
    double? aiScore,
    DateTime? shownDate,
    bool? wasRead,
    bool? wasShared,
    int? userRating,
    BibleVerse? verse,
  }) {
    return DailyVerseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      verseId: verseId ?? this.verseId,
      reason: reason ?? this.reason,
      aiScore: aiScore ?? this.aiScore,
      shownDate: shownDate ?? this.shownDate,
      wasRead: wasRead ?? this.wasRead,
      wasShared: wasShared ?? this.wasShared,
      userRating: userRating ?? this.userRating,
      verse: verse ?? this.verse,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        verseId,
        reason,
        aiScore,
        shownDate,
        wasRead,
        wasShared,
        userRating,
        verse,
      ];
}

// ============= DAILY VERSE RESPONSE =============

@JsonSerializable()
class DailyVerseResponse extends Equatable {
  final DailyVerseModel dailyVerse;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  const DailyVerseResponse({
    required this.dailyVerse,
    this.imageUrl,
    this.metadata,
  });

  factory DailyVerseResponse.fromJson(Map<String, dynamic> json) =>
      _$DailyVerseResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DailyVerseResponseToJson(this);

  @override
  List<Object?> get props => [dailyVerse, imageUrl, metadata];
}

// ============= DAILY VERSE HISTORY =============

@JsonSerializable()
class DailyVerseHistory extends Equatable {
  final List<DailyVerseModel> verses;
  final int total;
  final Map<String, int> statistics;

  const DailyVerseHistory({
    required this.verses,
    required this.total,
    required this.statistics,
  });

  factory DailyVerseHistory.fromJson(Map<String, dynamic> json) =>
      _$DailyVerseHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$DailyVerseHistoryToJson(this);

  /// Obtiene el número de versículos leídos
  int get readCount => statistics['read'] ?? 0;

  /// Obtiene el número de versículos compartidos
  int get sharedCount => statistics['shared'] ?? 0;

  /// Obtiene el número de versículos calificados
  int get ratedCount => statistics['rated'] ?? 0;

  /// Obtiene la calificación promedio
  double get averageRating {
    if (statistics['totalRating'] == null || statistics['ratedCount'] == null ||
        statistics['ratedCount'] == 0) {
      return 0;
    }
    return statistics['totalRating']! / statistics['ratedCount']!;
  }

  /// Obtiene los versículos favoritos (calificación 5)
  List<DailyVerseModel> get favoriteVerses {
    return verses.where((v) => v.userRating == 5).toList();
  }

  /// Obtiene los versículos más recientes (últimos 7 días)
  List<DailyVerseModel> get recentVerses {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return verses.where((v) => v.shownDate.isAfter(sevenDaysAgo)).toList();
  }

  @override
  List<Object?> get props => [verses, total, statistics];
}

// ============= AI VERSE SELECTOR DATA =============

@JsonSerializable()
class AIVerseSelectorData extends Equatable {
  final Map<String, dynamic> userPreferences;
  final Map<String, dynamic> readingHistory;
  final Map<String, dynamic> searchHistory;
  final Map<String, dynamic> interactionData;
  final Map<String, dynamic> temporalContext;

  const AIVerseSelectorData({
    required this.userPreferences,
    required this.readingHistory,
    required this.searchHistory,
    required this.interactionData,
    required this.temporalContext,
  });

  factory AIVerseSelectorData.fromJson(Map<String, dynamic> json) =>
      _$AIVerseSelectorDataFromJson(json);

  Map<String, dynamic> toJson() => _$AIVerseSelectorDataToJson(this);

  @override
  List<Object?> get props => [
        userPreferences,
        readingHistory,
        searchHistory,
        interactionData,
        temporalContext,
      ];
}

// ============= VERSE SELECTION REASON =============

class VerseSelectionReason {
  static const String basedOnReading = 'Basado en tu lectura reciente';
  static const String basedOnSearch = 'Relacionado con tus búsquedas';
  static const String basedOnInterests = 'Acorde a tus intereses';
  static const String seasonal = 'Especial para esta época del año';
  static const String encouragement = 'Para animarte hoy';
  static const String wisdom = 'Sabiduría para tu día';
  static const String faith = 'Para fortalecer tu fe';
  static const String love = 'Recordatorio del amor de Dios';
  static const String hope = 'Mensaje de esperanza';
  static const String peace = 'Para traer paz a tu corazón';
  static const String strength = 'Fortaleza para los desafíos';
  static const String guidance = 'Guía para tu camino';
  static const String gratitude = 'Motivo de gratitud';
  static const String prayer = 'Inspiración para la oración';
  static const String promise = 'Promesa de Dios para ti';

  static String getReasonByContext(Map<String, dynamic> context) {
    // Lógica para determinar la razón basada en el contexto
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 9) {
      return encouragement;
    } else if (hour >= 9 && hour < 12) {
      return wisdom;
    } else if (hour >= 12 && hour < 15) {
      return strength;
    } else if (hour >= 15 && hour < 18) {
      return guidance;
    } else if (hour >= 18 && hour < 21) {
      return gratitude;
    } else {
      return peace;
    }
  }

  static List<String> getAllReasons() {
    return [
      basedOnReading,
      basedOnSearch,
      basedOnInterests,
      seasonal,
      encouragement,
      wisdom,
      faith,
      love,
      hope,
      peace,
      strength,
      guidance,
      gratitude,
      prayer,
      promise,
    ];
  }
}