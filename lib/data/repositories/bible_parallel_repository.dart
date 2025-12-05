import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/services/storage_service.dart';
import '../models/bible_models.dart';
import '../models/bible_parallel_models.dart';

/// Repositorio para versículos paralelos y referencias cruzadas
class BibleParallelRepository {
  final ApiClient _apiClient = ApiClient.instance;
  final StorageService _storage = StorageService.instance;

  // ============= VERSÍCULOS PARALELOS =============

  /// Obtener versículos paralelos para un versículo específico
  Future<List<ParallelVerse>> getParallelVerses(
    int verseId, {
    ParallelType? type,
  }) async {
    try {
      final cacheKey = 'parallel_verses_$verseId${type != null ? '_$type' : ''}';

      // Verificar cache
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(days: 7),
      );

      if (cachedData != null) {
        final List<dynamic> data = cachedData;
        return data.map((json) => ParallelVerse.fromJson(json)).toList();
      }

      // Obtener del servidor
      final response = await _apiClient.get(
        '/bible/verses/$verseId/parallels',
        queryParameters: {
          if (type != null) 'type': type.toString().split('.').last.toUpperCase(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        final parallels = data.map((json) => ParallelVerse.fromJson(json)).toList();

        // Guardar en cache
        await _storage.saveToCache(cacheKey, data);

        return parallels;
      } else {
        throw ApiException('Error al obtener versículos paralelos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener versículos paralelos');
    }
  }

  /// Obtener grupos paralelos (ej: evangelios sinópticos)
  Future<List<ParallelGroup>> getParallelGroups({
    int? bookId,
    int? chapter,
    ParallelGroupType? groupType,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/parallel-groups',
        queryParameters: {
          if (bookId != null) 'bookId': bookId,
          if (chapter != null) 'chapter': chapter,
          if (groupType != null) 'type': groupType.toString().split('.').last.toUpperCase(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ParallelGroup.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener grupos paralelos');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener grupos paralelos');
    }
  }

  // ============= COMPARACIÓN DE VERSIONES =============

  /// Comparar versículo en múltiples versiones
  Future<VersionComparison> compareVersions(
    int verseId, {
    List<int>? versionIds,
  }) async {
    try {
      final cacheKey = 'version_comparison_$verseId';

      // Verificar cache
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(hours: 24),
      );

      if (cachedData != null) {
        return VersionComparison.fromJson(cachedData);
      }

      final response = await _apiClient.get(
        '/bible/verses/$verseId/compare',
        queryParameters: {
          if (versionIds != null) 'versions': versionIds.join(','),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final comparison = VersionComparison.fromJson(response.data['data']);

        // Guardar en cache
        await _storage.saveToCache(cacheKey, response.data['data']);

        return comparison;
      } else {
        throw ApiException('Error al comparar versiones');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al comparar versiones');
    }
  }

  /// Comparar capítulo completo en múltiples versiones
  Future<List<VersionComparison>> compareChapter({
    required int bookId,
    required int chapter,
    List<int>? versionIds,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/chapters/compare',
        queryParameters: {
          'bookId': bookId,
          'chapter': chapter,
          if (versionIds != null) 'versions': versionIds.join(','),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => VersionComparison.fromJson(json)).toList();
      } else {
        throw ApiException('Error al comparar capítulo');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al comparar capítulo');
    }
  }

  // ============= HARMONÍA DE LOS EVANGELIOS =============

  /// Obtener harmonía de los evangelios
  Future<List<GospelHarmony>> getGospelHarmony({
    String? period,
    String? gospel,
  }) async {
    try {
      final cacheKey = 'gospel_harmony${period != null ? '_$period' : ''}';

      // Verificar cache
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(days: 30),
      );

      if (cachedData != null) {
        final List<dynamic> data = cachedData;
        return data.map((json) => GospelHarmony.fromJson(json)).toList();
      }

      final response = await _apiClient.get(
        '/bible/gospel-harmony',
        queryParameters: {
          if (period != null) 'period': period,
          if (gospel != null) 'gospel': gospel,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        final harmony = data.map((json) => GospelHarmony.fromJson(json)).toList();

        // Guardar en cache
        await _storage.saveToCache(cacheKey, data);

        return harmony;
      } else {
        throw ApiException('Error al obtener harmonía');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener harmonía');
    }
  }

  /// Buscar evento en la harmonía
  Future<GospelHarmony?> findHarmonyEvent(String event) async {
    try {
      final response = await _apiClient.get(
        '/bible/gospel-harmony/search',
        queryParameters: {'q': event},
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data['data'] != null) {
          return GospelHarmony.fromJson(response.data['data']);
        }
      }
      return null;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error al buscar evento');
    }
  }

  // ============= CADENAS TEMÁTICAS =============

  /// Obtener cadenas temáticas
  Future<List<ThematicChain>> getThematicChains({
    String? category,
    String? theme,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/thematic-chains',
        queryParameters: {
          if (category != null) 'category': category,
          if (theme != null) 'theme': theme,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ThematicChain.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener cadenas temáticas');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener cadenas temáticas');
    }
  }

  /// Obtener cadena temática específica
  Future<ThematicChain> getThematicChain(int chainId) async {
    try {
      final cacheKey = 'thematic_chain_$chainId';

      // Verificar cache
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(days: 7),
      );

      if (cachedData != null) {
        return ThematicChain.fromJson(cachedData);
      }

      final response = await _apiClient.get('/bible/thematic-chains/$chainId');

      if (response.statusCode == 200 && response.data != null) {
        final chain = ThematicChain.fromJson(response.data['data']);

        // Guardar en cache
        await _storage.saveToCache(cacheKey, response.data['data']);

        return chain;
      } else {
        throw ApiException('Error al obtener cadena temática');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener cadena temática');
    }
  }

  // ============= SUGERENCIAS INTELIGENTES =============

  /// Obtener versículos relacionados usando IA
  Future<List<BibleVerse>> getSuggestedVerses({
    required int verseId,
    int limit = 10,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/verses/$verseId/suggestions',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => BibleVerse.fromJson(json)).toList();
      } else {
        throw ApiException('Error al obtener sugerencias');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener sugerencias');
    }
  }

  /// Buscar versículos por tema
  Future<List<BibleVerse>> searchByTheme({
    required String theme,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/bible/search/theme',
        queryParameters: {
          'theme': theme,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => BibleVerse.fromJson(json)).toList();
      } else {
        throw ApiException('Error al buscar por tema');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al buscar por tema');
    }
  }

  // ============= CATEGORÍAS Y TEMAS =============

  /// Obtener categorías de temas
  Future<List<String>> getThemeCategories() async {
    try {
      final cacheKey = 'theme_categories';

      // Verificar cache
      final cachedData = _storage.getFromCache(
        cacheKey,
        maxAge: const Duration(days: 30),
      );

      if (cachedData != null) {
        return List<String>.from(cachedData);
      }

      final response = await _apiClient.get('/bible/themes/categories');

      if (response.statusCode == 200 && response.data != null) {
        final categories = List<String>.from(response.data['data']);

        // Guardar en cache
        await _storage.saveToCache(cacheKey, categories);

        return categories;
      } else {
        throw ApiException('Error al obtener categorías');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener categorías');
    }
  }

  /// Obtener temas populares
  Future<List<Map<String, dynamic>>> getPopularThemes({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/bible/themes/popular',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        throw ApiException('Error al obtener temas populares');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado al obtener temas populares');
    }
  }
}