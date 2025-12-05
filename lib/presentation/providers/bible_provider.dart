import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/bible_models.dart';
import '../../data/repositories/bible_repository.dart';

/// Provider del repositorio de la Biblia
final bibleRepositoryProvider = Provider<BibleRepository>((ref) {
  return BibleRepository();
});

/// Provider de versiones de la Biblia
final bibleVersionsProvider = StateNotifierProvider<BibleVersionsNotifier, AsyncValue<List<BibleVersion>>>((ref) {
  return BibleVersionsNotifier(ref);
});

/// Notifier para las versiones de la Biblia
class BibleVersionsNotifier extends StateNotifier<AsyncValue<List<BibleVersion>>> {
  final Ref _ref;
  late final BibleRepository _repository;

  BibleVersionsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(bibleRepositoryProvider);
  }

  Future<void> loadVersions() async {
    state = const AsyncValue.loading();

    try {
      final versions = await _repository.getVersions();
      state = AsyncValue.data(versions);

      // Establecer versión por defecto
      if (versions.isNotEmpty) {
        final defaultVersion = versions.firstWhere(
          (v) => v.isDefault,
          orElse: () => versions.first,
        );
        _ref.read(selectedVersionProvider.notifier).state = defaultVersion;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider de la versión seleccionada
final selectedVersionProvider = StateProvider<BibleVersion?>((ref) => null);

/// Provider de libros de la Biblia
final bibleBooksProvider = StateNotifierProvider<BibleBooksNotifier, AsyncValue<List<BibleBook>>>((ref) {
  return BibleBooksNotifier(ref);
});

/// Notifier para los libros de la Biblia
class BibleBooksNotifier extends StateNotifier<AsyncValue<List<BibleBook>>> {
  final Ref _ref;
  late final BibleRepository _repository;

  BibleBooksNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(bibleRepositoryProvider);
  }

  Future<void> loadBooks() async {
    state = const AsyncValue.loading();

    try {
      final books = await _repository.getBooks();
      state = AsyncValue.data(books);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider de un capítulo específico
final chapterProvider = FutureProvider.family<ChapterData, ChapterRequest>((ref, request) async {
  final repository = ref.read(bibleRepositoryProvider);
  return repository.getChapter(
    versionId: request.versionId,
    bookId: request.bookId,
    chapter: request.chapter,
  );
});

/// Modelo para solicitud de capítulo
class ChapterRequest {
  final int versionId;
  final int bookId;
  final int chapter;

  const ChapterRequest({
    required this.versionId,
    required this.bookId,
    required this.chapter,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChapterRequest &&
          runtimeType == other.runtimeType &&
          versionId == other.versionId &&
          bookId == other.bookId &&
          chapter == other.chapter;

  @override
  int get hashCode => versionId.hashCode ^ bookId.hashCode ^ chapter.hashCode;
}

/// Provider de búsqueda en la Biblia
final bibleSearchProvider = StateNotifierProvider<BibleSearchNotifier, AsyncValue<BibleSearchResult?>>((ref) {
  return BibleSearchNotifier(ref);
});

/// Notifier para búsqueda en la Biblia
class BibleSearchNotifier extends StateNotifier<AsyncValue<BibleSearchResult?>> {
  final Ref _ref;
  late final BibleRepository _repository;

  BibleSearchNotifier(this._ref) : super(const AsyncValue.data(null)) {
    _repository = _ref.read(bibleRepositoryProvider);
  }

  Future<void> search({
    required String query,
    int? versionId,
    int? bookId,
    Testament? testament,
  }) async {
    state = const AsyncValue.loading();

    try {
      final result = await _repository.search(
        query: query,
        versionId: versionId ?? _ref.read(selectedVersionProvider)?.id,
        bookId: bookId,
        testament: testament,
      );
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void clearSearch() {
    state = const AsyncValue.data(null);
  }
}

/// Provider de versículos favoritos
final bibleFavoritesProvider = StateNotifierProvider<BibleFavoritesNotifier, AsyncValue<List<BibleFavorite>>>((ref) {
  return BibleFavoritesNotifier(ref);
});

/// Notifier para versículos favoritos
class BibleFavoritesNotifier extends StateNotifier<AsyncValue<List<BibleFavorite>>> {
  final Ref _ref;
  late final BibleRepository _repository;

  BibleFavoritesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(bibleRepositoryProvider);
  }

  Future<void> loadFavorites() async {
    state = const AsyncValue.loading();

    try {
      final favorites = await _repository.getFavorites();
      state = AsyncValue.data(favorites);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> toggleFavorite(int verseId, {String folder = 'General'}) async {
    try {
      final currentFavorites = state.value ?? [];
      final isFavorite = currentFavorites.any((f) => f.verseId == verseId);

      if (isFavorite) {
        await _repository.removeFavorite(verseId);

        final updatedFavorites = currentFavorites
            .where((f) => f.verseId != verseId)
            .toList();
        state = AsyncValue.data(updatedFavorites);

        return false;
      } else {
        await _repository.addFavorite(verseId, folder: folder);
        await loadFavorites(); // Recargar para obtener el favorito completo
        return true;
      }
    } catch (error) {
      return false;
    }
  }
}

/// Provider de versículos subrayados
final bibleHighlightsProvider = StateNotifierProvider<BibleHighlightsNotifier, AsyncValue<List<BibleHighlight>>>((ref) {
  return BibleHighlightsNotifier(ref);
});

/// Notifier para versículos subrayados
class BibleHighlightsNotifier extends StateNotifier<AsyncValue<List<BibleHighlight>>> {
  final Ref _ref;
  late final BibleRepository _repository;

  BibleHighlightsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(bibleRepositoryProvider);
  }

  Future<void> loadHighlights() async {
    state = const AsyncValue.loading();

    try {
      final highlights = await _repository.getHighlights();
      state = AsyncValue.data(highlights);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> highlightVerse(int verseId, String color) async {
    try {
      await _repository.highlightVerse(verseId, color);
      await loadHighlights();
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> removeHighlight(int verseId) async {
    try {
      await _repository.removeHighlight(verseId);

      final currentHighlights = state.value ?? [];
      final updatedHighlights = currentHighlights
          .where((h) => h.verseId != verseId)
          .toList();
      state = AsyncValue.data(updatedHighlights);

      return true;
    } catch (error) {
      return false;
    }
  }
}

/// Provider de notas de la Biblia
final bibleNotesProvider = StateNotifierProvider<BibleNotesNotifier, AsyncValue<List<BibleNote>>>((ref) {
  return BibleNotesNotifier(ref);
});

/// Notifier para notas de la Biblia
class BibleNotesNotifier extends StateNotifier<AsyncValue<List<BibleNote>>> {
  final Ref _ref;
  late final BibleRepository _repository;

  BibleNotesNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(bibleRepositoryProvider);
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();

    try {
      final notes = await _repository.getNotes();
      state = AsyncValue.data(notes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> addNote({
    int? verseId,
    int? bookId,
    int? chapter,
    required String text,
    bool isPrivate = true,
  }) async {
    try {
      await _repository.addNote(
        verseId: verseId,
        bookId: bookId,
        chapter: chapter,
        text: text,
        isPrivate: isPrivate,
      );
      await loadNotes();
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> updateNote(int noteId, String text) async {
    try {
      await _repository.updateNote(noteId, text);
      await loadNotes();
      return true;
    } catch (error) {
      return false;
    }
  }

  Future<bool> deleteNote(int noteId) async {
    try {
      await _repository.deleteNote(noteId);

      final currentNotes = state.value ?? [];
      final updatedNotes = currentNotes
          .where((n) => n.id != noteId)
          .toList();
      state = AsyncValue.data(updatedNotes);

      return true;
    } catch (error) {
      return false;
    }
  }
}

/// Provider de planes de lectura
final readingPlansProvider = StateNotifierProvider<ReadingPlansNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return ReadingPlansNotifier(ref);
});

/// Notifier para planes de lectura
class ReadingPlansNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref _ref;

  ReadingPlansNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> loadPlans() async {
    state = const AsyncValue.loading();

    try {
      // TODO: Implementar carga real de planes
      await Future.delayed(const Duration(seconds: 1));

      state = AsyncValue.data([
        {
          'id': 1,
          'title': 'Biblia en un año',
          'description': 'Lee toda la Biblia en 365 días',
          'progress': 0.25,
          'currentDay': 90,
          'totalDays': 365,
        },
        {
          'id': 2,
          'title': 'Nuevo Testamento en 90 días',
          'description': 'Lee todo el NT en 3 meses',
          'progress': 0.60,
          'currentDay': 54,
          'totalDays': 90,
        },
      ]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider de comentarios de versículo
final verseCommentaryProvider = FutureProvider.family<List<BibleCommentary>, int>((ref, verseId) async {
  final repository = ref.read(bibleRepositoryProvider);
  return repository.getCommentaries(
    bookId: 1, // TODO: Obtener del contexto
    chapter: 1, // TODO: Obtener del contexto
    verseStart: 1, // TODO: Obtener del contexto
  );
});

/// Provider de referencias cruzadas
final crossReferencesProvider = FutureProvider.family<List<BibleVerse>, int>((ref, verseId) async {
  final repository = ref.read(bibleRepositoryProvider);
  return repository.getCrossReferences(verseId);
});