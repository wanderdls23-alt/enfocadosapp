import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/services/storage_service.dart';
import '../models/bible_models.dart';

/// Repositorio para manejar todas las operaciones relacionadas con la Biblia
class BibleRepository {
  final ApiClient _apiClient = ApiClient.instance;
  final StorageService _storage = StorageService.instance;

  // ============= VERSIONES DE LA BIBLIA =============

  /// Obtener todas las versiones disponibles
  Future<List<BibleVersion>> getVersions() async {
    try {
      // Intentar obtener del caché primero
      final cachedData = _storage.getFromCache(
        'bible_versions',
        maxAge: const Duration(days: 7),
      );

      if (cachedData != null) {
        final List<dynamic> data = cachedData['versions'];
        return data.map((json) => BibleVersion.fromJson(json)).toList();
      }

      // Si no hay caché, obtener del servidor
      final response = await _apiClient.get(
        '/bible/versions',
        useCache: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        final versions = data.map((json) => BibleVersion.fromJson(json)).toList();

        // Guardar en caché
        await _storage.saveToCache('bible_versions', {'versions': data});

        return versions;
      } else {
        throw ApiException('Error al obtener versiones de la Biblia');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener versiones');
    }
  }

  // ============= LIBROS DE LA BIBLIA =============

  /// Obtener todos los libros
  Future<List<BibleBook>> getBooks({Testament? testament}) async {
    try {
      final cacheKey = testament != null
        ? 'bible_books_${testament.name}'
        : 'bible_books_all';

      // Intentar obtener del caché
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(days: 30),
      );

      if (cachedData != null) {
        final List<dynamic> data = cachedData['books'];
        return data.map((json) => BibleBook.fromJson(json)).toList();
      }

      // Obtener del servidor
      final response = await _apiClient.get(
        '/bible/books',
        queryParameters: testament != null
          ? {'testament': testament.name.toUpperCase()}
          : null,
        useCache: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        final books = data.map((json) => BibleBook.fromJson(json)).toList();

        // Guardar en caché
        await _storage.saveToCache(cacheKey, {'books': data});

        return books;
      } else {
        throw ApiException('Error al obtener libros de la Biblia');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener libros');
    }
  }

  // ============= VERSÍCULOS =============

  /// Obtener versículos de un capítulo
  Future<ChapterData> getChapter({
    required int versionId,
    required int bookId,
    required int chapter,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/verses',
        queryParameters: {
          'versionId': versionId,
          'bookId': bookId,
          'chapter': chapter,
        },
        useCache: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        return ChapterData.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al obtener capítulo');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener capítulo');
    }
  }

  /// Obtener un versículo específico
  Future<BibleVerse> getVerse({
    required int versionId,
    required int bookId,
    required int chapter,
    required int verse,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/verses',
        queryParameters: {
          'versionId': versionId,
          'bookId': bookId,
          'chapter': chapter,
          'verseStart': verse,
          'verseEnd': verse,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final verses = response.data['data']['verses'] as List;
        if (verses.isNotEmpty) {
          return BibleVerse.fromJson(verses.first);
        }
      }
      throw NotFoundException('Versículo no encontrado');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al obtener versículo');
    }
  }

  /// Obtener rango de versículos
  Future<List<BibleVerse>> getVerseRange({
    required int versionId,
    required int bookId,
    required int chapter,
    required int verseStart,
    required int verseEnd,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/verses',
        queryParameters: {
          'versionId': versionId,
          'bookId': bookId,
          'chapter': chapter,
          'verseStart': verseStart,
          'verseEnd': verseEnd,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> verses = response.data['data']['verses'];
        return verses.map((json) => BibleVerse.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener versículos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener versículos');
    }
  }

  // ============= BÚSQUEDA =============

  /// Buscar en la Biblia
  Future<BibleSearchResult> searchBible({
    required String query,
    int? versionId,
    Testament? testament,
    int? bookId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/search',
        queryParameters: {
          'query': query,
          if (versionId != null) 'versionId': versionId,
          if (testament != null) 'testament': testament.name.toUpperCase(),
          if (bookId != null) 'bookId': bookId,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return BibleSearchResult.fromJson(response.data['data']);
      } else {
        throw ApiException('Error en la búsqueda');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado en la búsqueda');
    }
  }

  // ============= STRONG'S CONCORDANCE =============

  /// Obtener definición Strong
  Future<BibleStrong> getStrongDefinition(String strongNumber) async {
    try {
      // Usar caché para definiciones Strong
      final cacheKey = 'strong_$strongNumber';
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(days: 90),
      );

      if (cachedData != null) {
        return BibleStrong.fromJson(cachedData);
      }

      final response = await _apiClient.get(
        '/bible/strong/$strongNumber',
        useCache: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        final strong = BibleStrong.fromJson(response.data['data']);

        // Guardar en caché
        await _storage.saveToCache(cacheKey, response.data['data']);

        return strong;
      } else {
        throw ApiException('Definición Strong no encontrada');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al obtener definición Strong');
    }
  }

  /// Buscar palabras Strong
  Future<List<BibleStrong>> searchStrong({
    required String query,
    StrongLanguage? language,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/strong/search',
        queryParameters: {
          'query': query,
          if (language != null) 'language': language.name.toUpperCase(),
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => BibleStrong.fromJson(json)).toList();
      } else {
        throw ApiException('Error en búsqueda Strong');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado en búsqueda Strong');
    }
  }

  // ============= COMENTARIOS =============

  /// Obtener comentarios de un versículo
  Future<List<BibleCommentary>> getCommentaries({
    required int bookId,
    required int chapter,
    required int verse,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/commentary',
        queryParameters: {
          'bookId': bookId,
          'chapter': chapter,
          'verse': verse,
        },
        useCache: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => BibleCommentary.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener comentarios');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener comentarios');
    }
  }

  // ============= APLICACIONES PRÁCTICAS =============

  /// Obtener aplicaciones prácticas
  Future<List<BibleApplication>> getApplications({
    required int bookId,
    required int chapter,
    required int verse,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/applications',
        queryParameters: {
          'bookId': bookId,
          'chapter': chapter,
          'verse': verse,
        },
        useCache: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => BibleApplication.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener aplicaciones');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener aplicaciones');
    }
  }

  // ============= HIGHLIGHTS (SUBRAYADOS) =============

  /// Agregar subrayado
  Future<BibleHighlight> addHighlight({
    required int verseId,
    required String color,
  }) async {
    try {
      final response = await _apiClient.post(
        '/bible/highlights',
        data: {
          'verseId': verseId,
          'color': color,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        return BibleHighlight.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al agregar subrayado');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al agregar subrayado');
    }
  }

  /// Eliminar subrayado
  Future<void> removeHighlight(int highlightId) async {
    try {
      final response = await _apiClient.delete('/bible/highlights/$highlightId');

      if (response.statusCode != 200) {
        throw ApiException('Error al eliminar subrayado');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al eliminar subrayado');
    }
  }

  /// Obtener subrayados del usuario
  Future<List<BibleHighlight>> getUserHighlights({
    int? bookId,
    int? chapter,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/highlights',
        queryParameters: {
          if (bookId != null) 'bookId': bookId,
          if (chapter != null) 'chapter': chapter,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => BibleHighlight.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener subrayados');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener subrayados');
    }
  }

  // ============= NOTAS =============

  /// Agregar nota
  Future<BibleNote> addNote({
    int? verseId,
    int? bookId,
    int? chapter,
    int? verse,
    required String text,
    bool isPrivate = true,
  }) async {
    try {
      final response = await _apiClient.post(
        '/bible/notes',
        data: {
          if (verseId != null) 'verseId': verseId,
          if (bookId != null) 'bookId': bookId,
          if (chapter != null) 'chapter': chapter,
          if (verse != null) 'verse': verse,
          'text': text,
          'isPrivate': isPrivate,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        return BibleNote.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al agregar nota');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al agregar nota');
    }
  }

  /// Actualizar nota
  Future<BibleNote> updateNote({
    required int noteId,
    required String text,
    bool? isPrivate,
  }) async {
    try {
      final response = await _apiClient.put(
        '/bible/notes/$noteId',
        data: {
          'text': text,
          if (isPrivate != null) 'isPrivate': isPrivate,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return BibleNote.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al actualizar nota');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al actualizar nota');
    }
  }

  /// Eliminar nota
  Future<void> deleteNote(int noteId) async {
    try {
      final response = await _apiClient.delete('/bible/notes/$noteId');

      if (response.statusCode != 200) {
        throw ApiException('Error al eliminar nota');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al eliminar nota');
    }
  }

  /// Obtener notas del usuario
  Future<List<BibleNote>> getUserNotes({
    int? bookId,
    int? chapter,
    int? verse,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/notes',
        queryParameters: {
          if (bookId != null) 'bookId': bookId,
          if (chapter != null) 'chapter': chapter,
          if (verse != null) 'verse': verse,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => BibleNote.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener notas');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener notas');
    }
  }

  // ============= FAVORITOS =============

  /// Agregar a favoritos
  Future<BibleFavorite> addFavorite({
    required int verseId,
    String folder = 'General',
  }) async {
    try {
      final response = await _apiClient.post(
        '/bible/favorites',
        data: {
          'verseId': verseId,
          'folder': folder,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        return BibleFavorite.fromJson(response.data['data']);
      } else {
        throw ApiException('Error al agregar a favoritos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al agregar a favoritos');
    }
  }

  /// Eliminar de favoritos
  Future<void> removeFavorite(int favoriteId) async {
    try {
      final response = await _apiClient.delete('/bible/favorites/$favoriteId');

      if (response.statusCode != 200) {
        throw ApiException('Error al eliminar de favoritos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al eliminar de favoritos');
    }
  }

  /// Obtener favoritos del usuario
  Future<List<BibleFavorite>> getUserFavorites({String? folder}) async {
    try {
      final response = await _apiClient.get(
        '/bible/favorites',
        queryParameters: {
          if (folder != null) 'folder': folder,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => BibleFavorite.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener favoritos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener favoritos');
    }
  }

  /// Obtener carpetas de favoritos
  Future<List<String>> getFavoriteFolders() async {
    try {
      final response = await _apiClient.get('/bible/favorites/folders');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.cast<String>();
      } else {
        throw ApiException('Error al obtener carpetas');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener carpetas');
    }
  }

  // ============= COMPARACIÓN DE VERSIONES =============

  /// Obtener versículo en múltiples versiones
  Future<List<BibleVerse>> compareVersions({
    required int bookId,
    required int chapter,
    required int verse,
    required List<int> versionIds,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/compare',
        queryParameters: {
          'bookId': bookId,
          'chapter': chapter,
          'verse': verse,
          'versionIds': versionIds.join(','),
        },
        useCache: true,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => BibleVerse.fromJson(json)).toList();
      } else {
        throw ApiException('Error al comparar versiones');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al comparar versiones');
    }
  }
}