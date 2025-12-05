import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'bible_models.dart';

part 'bible_parallel_models.g.dart';

/// Modelo para versículos paralelos y referencias cruzadas
@JsonSerializable()
class ParallelVerse extends Equatable {
  final int id;
  final int sourceVerseId;
  final int targetVerseId;
  final ParallelType type;
  final double relevanceScore;
  final String? relationship;
  final BibleVerse? targetVerse;

  const ParallelVerse({
    required this.id,
    required this.sourceVerseId,
    required this.targetVerseId,
    required this.type,
    this.relevanceScore = 1.0,
    this.relationship,
    this.targetVerse,
  });

  factory ParallelVerse.fromJson(Map<String, dynamic> json) =>
      _$ParallelVerseFromJson(json);

  Map<String, dynamic> toJson() => _$ParallelVerseToJson(this);

  /// Obtiene el tipo de relación en español
  String get relationshipText {
    switch (type) {
      case ParallelType.parallel:
        return 'Pasaje Paralelo';
      case ParallelType.crossReference:
        return 'Referencia Cruzada';
      case ParallelType.quotation:
        return 'Cita';
      case ParallelType.allusion:
        return 'Alusión';
      case ParallelType.fulfillment:
        return 'Cumplimiento Profético';
      case ParallelType.typology:
        return 'Tipología';
      case ParallelType.contrast:
        return 'Contraste';
      case ParallelType.explanation:
        return 'Explicación';
    }
  }

  /// Obtiene el icono según el tipo
  String get typeIcon {
    switch (type) {
      case ParallelType.parallel:
        return '🔄';
      case ParallelType.crossReference:
        return '↔️';
      case ParallelType.quotation:
        return '💬';
      case ParallelType.allusion:
        return '💭';
      case ParallelType.fulfillment:
        return '✨';
      case ParallelType.typology:
        return '🎭';
      case ParallelType.contrast:
        return '⚖️';
      case ParallelType.explanation:
        return '💡';
    }
  }

  @override
  List<Object?> get props => [
        id,
        sourceVerseId,
        targetVerseId,
        type,
        relevanceScore,
        relationship,
        targetVerse,
      ];
}

/// Tipos de referencias paralelas
enum ParallelType {
  @JsonValue('PARALLEL')
  parallel, // Pasaje paralelo (ej: evangelios sinópticos)

  @JsonValue('CROSS_REFERENCE')
  crossReference, // Referencia cruzada general

  @JsonValue('QUOTATION')
  quotation, // Cita directa (ej: NT citando AT)

  @JsonValue('ALLUSION')
  allusion, // Alusión indirecta

  @JsonValue('FULFILLMENT')
  fulfillment, // Cumplimiento profético

  @JsonValue('TYPOLOGY')
  typology, // Tipo y antitipo

  @JsonValue('CONTRAST')
  contrast, // Contraste o comparación

  @JsonValue('EXPLANATION')
  explanation, // Explicación o ampliación
}

/// Grupo de versículos paralelos
@JsonSerializable()
class ParallelGroup extends Equatable {
  final int id;
  final String title;
  final String? description;
  final ParallelGroupType groupType;
  final List<BibleVerse> verses;
  final Map<String, dynamic>? metadata;

  const ParallelGroup({
    required this.id,
    required this.title,
    this.description,
    required this.groupType,
    required this.verses,
    this.metadata,
  });

  factory ParallelGroup.fromJson(Map<String, dynamic> json) =>
      _$ParallelGroupFromJson(json);

  Map<String, dynamic> toJson() => _$ParallelGroupToJson(this);

  /// Obtiene el icono del grupo
  String get icon {
    switch (groupType) {
      case ParallelGroupType.synoptic:
        return '📚';
      case ParallelGroupType.prophecy:
        return '🔮';
      case ParallelGroupType.psalm:
        return '🎵';
      case ParallelGroupType.genealogy:
        return '👥';
      case ParallelGroupType.miracle:
        return '✨';
      case ParallelGroupType.parable:
        return '🌱';
      case ParallelGroupType.teaching:
        return '📖';
      case ParallelGroupType.narrative:
        return '📜';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        groupType,
        verses,
        metadata,
      ];
}

/// Tipos de grupos paralelos
enum ParallelGroupType {
  @JsonValue('SYNOPTIC')
  synoptic, // Evangelios sinópticos

  @JsonValue('PROPHECY')
  prophecy, // Profecía y cumplimiento

  @JsonValue('PSALM')
  psalm, // Salmos paralelos

  @JsonValue('GENEALOGY')
  genealogy, // Genealogías

  @JsonValue('MIRACLE')
  miracle, // Milagros paralelos

  @JsonValue('PARABLE')
  parable, // Parábolas

  @JsonValue('TEACHING')
  teaching, // Enseñanzas paralelas

  @JsonValue('NARRATIVE')
  narrative, // Narrativas paralelas
}

/// Comparación de versículos en diferentes versiones
@JsonSerializable()
class VersionComparison extends Equatable {
  final int verseId;
  final BibleBook book;
  final int chapter;
  final int verse;
  final List<VersionText> versions;

  const VersionComparison({
    required this.verseId,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.versions,
  });

  factory VersionComparison.fromJson(Map<String, dynamic> json) =>
      _$VersionComparisonFromJson(json);

  Map<String, dynamic> toJson() => _$VersionComparisonToJson(this);

  /// Obtiene la referencia del versículo
  String get reference => '${book.name} $chapter:$verse';

  @override
  List<Object?> get props => [
        verseId,
        book,
        chapter,
        verse,
        versions,
      ];
}

/// Texto del versículo en una versión específica
@JsonSerializable()
class VersionText extends Equatable {
  final BibleVersion version;
  final String text;
  final bool hasStrong;
  final bool hasFootnotes;

  const VersionText({
    required this.version,
    required this.text,
    this.hasStrong = false,
    this.hasFootnotes = false,
  });

  factory VersionText.fromJson(Map<String, dynamic> json) =>
      _$VersionTextFromJson(json);

  Map<String, dynamic> toJson() => _$VersionTextToJson(this);

  @override
  List<Object?> get props => [
        version,
        text,
        hasStrong,
        hasFootnotes,
      ];
}

/// Harmonía de los evangelios
@JsonSerializable()
class GospelHarmony extends Equatable {
  final int id;
  final String event;
  final String? period;
  final int? sequence;
  final List<HarmonyReference> references;
  final String? notes;

  const GospelHarmony({
    required this.id,
    required this.event,
    this.period,
    this.sequence,
    required this.references,
    this.notes,
  });

  factory GospelHarmony.fromJson(Map<String, dynamic> json) =>
      _$GospelHarmonyFromJson(json);

  Map<String, dynamic> toJson() => _$GospelHarmonyToJson(this);

  /// Obtiene los evangelios que contienen este evento
  List<String> get gospels {
    return references
        .map((ref) => ref.gospel)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  List<Object?> get props => [
        id,
        event,
        period,
        sequence,
        references,
        notes,
      ];
}

/// Referencia en la harmonía de los evangelios
@JsonSerializable()
class HarmonyReference extends Equatable {
  final String gospel; // Mateo, Marcos, Lucas, Juan
  final String reference; // ej: "5:1-12"
  final int? startVerse;
  final int? endVerse;
  final int chapter;

  const HarmonyReference({
    required this.gospel,
    required this.reference,
    this.startVerse,
    this.endVerse,
    required this.chapter,
  });

  factory HarmonyReference.fromJson(Map<String, dynamic> json) =>
      _$HarmonyReferenceFromJson(json);

  Map<String, dynamic> toJson() => _$HarmonyReferenceToJson(this);

  /// Obtiene el color asociado al evangelio
  String get gospelColor {
    switch (gospel.toLowerCase()) {
      case 'mateo':
      case 'matthew':
        return '#8B4513'; // Marrón
      case 'marcos':
      case 'mark':
        return '#FF6B6B'; // Rojo
      case 'lucas':
      case 'luke':
        return '#4ECDC4'; // Turquesa
      case 'juan':
      case 'john':
        return '#6C5CE7'; // Púrpura
      default:
        return '#95A5A6'; // Gris
    }
  }

  @override
  List<Object?> get props => [
        gospel,
        reference,
        startVerse,
        endVerse,
        chapter,
      ];
}

/// Cadena temática de versículos
@JsonSerializable()
class ThematicChain extends Equatable {
  final int id;
  final String theme;
  final String? description;
  final String category;
  final List<ChainLink> links;
  final Map<String, dynamic>? metadata;

  const ThematicChain({
    required this.id,
    required this.theme,
    this.description,
    required this.category,
    required this.links,
    this.metadata,
  });

  factory ThematicChain.fromJson(Map<String, dynamic> json) =>
      _$ThematicChainFromJson(json);

  Map<String, dynamic> toJson() => _$ThematicChainToJson(this);

  /// Obtiene el total de versículos en la cadena
  int get totalVerses => links.length;

  /// Obtiene los libros únicos en la cadena
  List<String> get uniqueBooks {
    return links
        .map((link) => link.bookName)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  List<Object?> get props => [
        id,
        theme,
        description,
        category,
        links,
        metadata,
      ];
}

/// Eslabón en una cadena temática
@JsonSerializable()
class ChainLink extends Equatable {
  final int sequence;
  final int verseId;
  final String bookName;
  final String reference;
  final String? text;
  final String? explanation;
  final LinkType linkType;

  const ChainLink({
    required this.sequence,
    required this.verseId,
    required this.bookName,
    required this.reference,
    this.text,
    this.explanation,
    this.linkType = LinkType.continuation,
  });

  factory ChainLink.fromJson(Map<String, dynamic> json) =>
      _$ChainLinkFromJson(json);

  Map<String, dynamic> toJson() => _$ChainLinkToJson(this);

  @override
  List<Object?> get props => [
        sequence,
        verseId,
        bookName,
        reference,
        text,
        explanation,
        linkType,
      ];
}

/// Tipo de enlace en la cadena
enum LinkType {
  @JsonValue('START')
  start,

  @JsonValue('CONTINUATION')
  continuation,

  @JsonValue('CLIMAX')
  climax,

  @JsonValue('CONCLUSION')
  conclusion,

  @JsonValue('KEY')
  key,
}