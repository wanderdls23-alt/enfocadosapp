import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bible_models.g.dart';

// ============= BIBLE VERSION =============

@JsonSerializable()
class BibleVersion extends Equatable {
  final int id;
  final String code;
  final String name;
  final String language;
  final String? description;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;

  const BibleVersion({
    required this.id,
    required this.code,
    required this.name,
    required this.language,
    this.description,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
  });

  factory BibleVersion.fromJson(Map<String, dynamic> json) =>
      _$BibleVersionFromJson(json);

  Map<String, dynamic> toJson() => _$BibleVersionToJson(this);

  @override
  List<Object?> get props => [id, code, name, language, description, isDefault, isActive, createdAt];
}

// ============= BIBLE BOOK =============

@JsonSerializable()
class BibleBook extends Equatable {
  final int id;
  final Testament testament;
  final int position;
  final String name;
  final String nameEnglish;
  final String abbreviation;
  final int chapters;

  const BibleBook({
    required this.id,
    required this.testament,
    required this.position,
    required this.name,
    required this.nameEnglish,
    required this.abbreviation,
    required this.chapters,
  });

  factory BibleBook.fromJson(Map<String, dynamic> json) =>
      _$BibleBookFromJson(json);

  Map<String, dynamic> toJson() => _$BibleBookToJson(this);

  /// Obtiene el nombre completo con el testamento
  String get fullName => '${testament.displayName} - $name';

  /// Verifica si es del Antiguo Testamento
  bool get isOldTestament => testament == Testament.old;

  /// Verifica si es del Nuevo Testamento
  bool get isNewTestament => testament == Testament.newT;

  @override
  List<Object?> get props => [id, testament, position, name, nameEnglish, abbreviation, chapters];
}

enum Testament {
  @JsonValue('OLD')
  old,
  @JsonValue('NEW')
  newT,
}

extension TestamentExtension on Testament {
  String get displayName {
    switch (this) {
      case Testament.old:
        return 'Antiguo Testamento';
      case Testament.newT:
        return 'Nuevo Testamento';
    }
  }

  String get abbreviation {
    switch (this) {
      case Testament.old:
        return 'AT';
      case Testament.newT:
        return 'NT';
    }
  }
}

// ============= BIBLE VERSE =============

@JsonSerializable()
class BibleVerse extends Equatable {
  final int id;
  final int versionId;
  final int bookId;
  final int chapter;
  final int verse;
  final String text;
  final bool textRed; // Palabras en rojo (Jesús/Dios)
  final BibleBook? book;
  final BibleVersion? version;
  final List<BibleVerseStrong>? strongRefs;
  final BibleHighlight? highlight;
  final BibleNote? note;
  final bool? isFavorite;

  const BibleVerse({
    required this.id,
    required this.versionId,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    this.textRed = false,
    this.book,
    this.version,
    this.strongRefs,
    this.highlight,
    this.note,
    this.isFavorite,
  });

  factory BibleVerse.fromJson(Map<String, dynamic> json) =>
      _$BibleVerseFromJson(json);

  Map<String, dynamic> toJson() => _$BibleVerseToJson(this);

  /// Obtiene la referencia completa del versículo
  String get reference {
    final bookName = book?.name ?? 'Libro';
    return '$bookName $chapter:$verse';
  }

  /// Obtiene la referencia corta
  String get shortReference => '$chapter:$verse';

  /// Verifica si tiene referencias Strong
  bool get hasStrong => strongRefs != null && strongRefs!.isNotEmpty;

  /// Verifica si está subrayado
  bool get isHighlighted => highlight != null;

  /// Verifica si tiene notas
  bool get hasNote => note != null;

  @override
  List<Object?> get props => [
        id,
        versionId,
        bookId,
        chapter,
        verse,
        text,
        textRed,
        book,
        version,
        strongRefs,
        highlight,
        note,
        isFavorite,
      ];
}

// ============= STRONG'S CONCORDANCE =============

@JsonSerializable()
class BibleStrong extends Equatable {
  final int id;
  final String strongNumber;
  final StrongLanguage language;
  final String originalWord;
  final String? transliteration;
  final String? pronunciation;
  final String definition;
  final String? usageNotes;

  const BibleStrong({
    required this.id,
    required this.strongNumber,
    required this.language,
    required this.originalWord,
    this.transliteration,
    this.pronunciation,
    required this.definition,
    this.usageNotes,
  });

  factory BibleStrong.fromJson(Map<String, dynamic> json) =>
      _$BibleStrongFromJson(json);

  Map<String, dynamic> toJson() => _$BibleStrongToJson(this);

  /// Verifica si es hebreo
  bool get isHebrew => language == StrongLanguage.hebrew;

  /// Verifica si es griego
  bool get isGreek => language == StrongLanguage.greek;

  @override
  List<Object?> get props => [
        id,
        strongNumber,
        language,
        originalWord,
        transliteration,
        pronunciation,
        definition,
        usageNotes,
      ];
}

enum StrongLanguage {
  @JsonValue('HEBREW')
  hebrew,
  @JsonValue('GREEK')
  greek,
}

// ============= BIBLE VERSE STRONG =============

@JsonSerializable()
class BibleVerseStrong extends Equatable {
  final int id;
  final int verseId;
  final int strongId;
  final int wordPosition;
  final String? wordText;
  final BibleStrong? strong;

  const BibleVerseStrong({
    required this.id,
    required this.verseId,
    required this.strongId,
    required this.wordPosition,
    this.wordText,
    this.strong,
  });

  factory BibleVerseStrong.fromJson(Map<String, dynamic> json) =>
      _$BibleVerseStrongFromJson(json);

  Map<String, dynamic> toJson() => _$BibleVerseStrongToJson(this);

  @override
  List<Object?> get props => [id, verseId, strongId, wordPosition, wordText, strong];
}

// ============= BIBLE COMMENTARY =============

@JsonSerializable()
class BibleCommentary extends Equatable {
  final int id;
  final int bookId;
  final int chapter;
  final int verseStart;
  final int? verseEnd;
  final String text;
  final String? author;
  final String? source;

  const BibleCommentary({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.verseStart,
    this.verseEnd,
    required this.text,
    this.author,
    this.source,
  });

  factory BibleCommentary.fromJson(Map<String, dynamic> json) =>
      _$BibleCommentaryFromJson(json);

  Map<String, dynamic> toJson() => _$BibleCommentaryToJson(this);

  /// Obtiene el rango de versículos
  String get verseRange {
    if (verseEnd != null && verseEnd != verseStart) {
      return '$verseStart-$verseEnd';
    }
    return verseStart.toString();
  }

  @override
  List<Object?> get props => [id, bookId, chapter, verseStart, verseEnd, text, author, source];
}

// ============= BIBLE APPLICATION =============

@JsonSerializable()
class BibleApplication extends Equatable {
  final int id;
  final int bookId;
  final int chapter;
  final int verse;
  final String text;
  final String? category;

  const BibleApplication({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    this.category,
  });

  factory BibleApplication.fromJson(Map<String, dynamic> json) =>
      _$BibleApplicationFromJson(json);

  Map<String, dynamic> toJson() => _$BibleApplicationToJson(this);

  @override
  List<Object?> get props => [id, bookId, chapter, verse, text, category];
}

// ============= BIBLE HIGHLIGHT =============

@JsonSerializable()
class BibleHighlight extends Equatable {
  final int id;
  final String userId;
  final int verseId;
  final String color;
  final DateTime createdAt;

  const BibleHighlight({
    required this.id,
    required this.userId,
    required this.verseId,
    required this.color,
    required this.createdAt,
  });

  factory BibleHighlight.fromJson(Map<String, dynamic> json) =>
      _$BibleHighlightFromJson(json);

  Map<String, dynamic> toJson() => _$BibleHighlightToJson(this);

  @override
  List<Object?> get props => [id, userId, verseId, color, createdAt];
}

// ============= BIBLE NOTE =============

@JsonSerializable()
class BibleNote extends Equatable {
  final int id;
  final String userId;
  final int? verseId;
  final int? bookId;
  final int? chapter;
  final int? verse;
  final String text;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BibleNote({
    required this.id,
    required this.userId,
    this.verseId,
    this.bookId,
    this.chapter,
    this.verse,
    required this.text,
    this.isPrivate = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BibleNote.fromJson(Map<String, dynamic> json) =>
      _$BibleNoteFromJson(json);

  Map<String, dynamic> toJson() => _$BibleNoteToJson(this);

  @override
  List<Object?> get props => [
        id,
        userId,
        verseId,
        bookId,
        chapter,
        verse,
        text,
        isPrivate,
        createdAt,
        updatedAt,
      ];
}

// ============= BIBLE FAVORITE =============

@JsonSerializable()
class BibleFavorite extends Equatable {
  final int id;
  final String userId;
  final int verseId;
  final String folder;
  final DateTime createdAt;
  final BibleVerse? verse;

  const BibleFavorite({
    required this.id,
    required this.userId,
    required this.verseId,
    this.folder = 'General',
    required this.createdAt,
    this.verse,
  });

  factory BibleFavorite.fromJson(Map<String, dynamic> json) =>
      _$BibleFavoriteFromJson(json);

  Map<String, dynamic> toJson() => _$BibleFavoriteToJson(this);

  @override
  List<Object?> get props => [id, userId, verseId, folder, createdAt, verse];
}

// ============= CHAPTER DATA =============

@JsonSerializable()
class ChapterData extends Equatable {
  final List<BibleVerse> verses;
  final BibleBook book;
  final int chapter;
  final ChapterNavigation? previousChapter;
  final ChapterNavigation? nextChapter;

  const ChapterData({
    required this.verses,
    required this.book,
    required this.chapter,
    this.previousChapter,
    this.nextChapter,
  });

  factory ChapterData.fromJson(Map<String, dynamic> json) =>
      _$ChapterDataFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterDataToJson(this);

  /// Obtiene el título del capítulo
  String get title => '${book.name} $chapter';

  /// Verifica si hay capítulo anterior
  bool get hasPrevious => previousChapter != null;

  /// Verifica si hay capítulo siguiente
  bool get hasNext => nextChapter != null;

  /// Obtiene el total de versículos
  int get totalVerses => verses.length;

  @override
  List<Object?> get props => [verses, book, chapter, previousChapter, nextChapter];
}

// ============= CHAPTER NAVIGATION =============

@JsonSerializable()
class ChapterNavigation extends Equatable {
  final int bookId;
  final int chapter;

  const ChapterNavigation({
    required this.bookId,
    required this.chapter,
  });

  factory ChapterNavigation.fromJson(Map<String, dynamic> json) =>
      _$ChapterNavigationFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterNavigationToJson(this);

  @override
  List<Object?> get props => [bookId, chapter];
}

// ============= SEARCH RESULT =============

@JsonSerializable()
class BibleSearchResult extends Equatable {
  final List<BibleVerse> results;
  final int total;
  final bool hasMore;
  final String query;

  const BibleSearchResult({
    required this.results,
    required this.total,
    required this.hasMore,
    required this.query,
  });

  factory BibleSearchResult.fromJson(Map<String, dynamic> json) =>
      _$BibleSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$BibleSearchResultToJson(this);

  @override
  List<Object?> get props => [results, total, hasMore, query];
}