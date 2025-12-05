import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bible_models.dart';
import '../../data/models/bible_parallel_models.dart';
import '../../data/repositories/bible_parallel_repository.dart';

/// Provider para el repositorio de versículos paralelos
final bibleParallelRepositoryProvider = Provider<BibleParallelRepository>((ref) {
  return BibleParallelRepository();
});

/// Provider para versículos paralelos de un versículo específico
final parallelVersesProvider = FutureProvider.family<List<ParallelVerse>, int>(
  (ref, verseId) async {
    final repository = ref.watch(bibleParallelRepositoryProvider);
    return repository.getParallelVerses(verseId);
  },
);

/// Provider para versículos paralelos filtrados por tipo
final parallelVersesByTypeProvider = FutureProvider.family<List<ParallelVerse>, ParallelVersesParams>(
  (ref, params) async {
    final repository = ref.watch(bibleParallelRepositoryProvider);
    return repository.getParallelVerses(
      params.verseId,
      type: params.type,
    );
  },
);

/// Provider para referencias cruzadas de un capítulo
final crossReferencesProvider = FutureProvider.family<List<CrossReference>, ChapterParams>(
  (ref, params) async {
    final repository = ref.watch(bibleParallelRepositoryProvider);
    return repository.getCrossReferences(
      params.bookId,
      params.chapter,
    );
  },
);

/// Provider para comparación de versiones
final versionComparisonProvider = FutureProvider.family<List<VersionComparison>, VersionComparisonParams>(
  (ref, params) async {
    final repository = ref.watch(bibleParallelRepositoryProvider);
    return repository.compareVersions(
      params.verseId,
      params.versionIds,
    );
  },
);

/// Provider para armonía de los evangelios
final gospelHarmonyProvider = FutureProvider.family<List<GospelHarmony>, String>(
  (ref, event) async {
    final repository = ref.watch(bibleParallelRepositoryProvider);
    return repository.getGospelHarmony(event);
  },
);

/// Provider para grupos de paralelos
final parallelGroupsProvider = FutureProvider.family<List<ParallelGroup>, int>(
  (ref, verseId) async {
    final repository = ref.watch(bibleParallelRepositoryProvider);
    return repository.getParallelGroups(verseId);
  },
);

/// Provider para versículos relacionados temáticamente
final thematicVersesProvider = FutureProvider.family<List<BibleVerse>, ThematicSearchParams>(
  (ref, params) async {
    final repository = ref.watch(bibleParallelRepositoryProvider);
    return repository.getThematicVerses(
      params.theme,
      limit: params.limit,
    );
  },
);

/// Estado para el tipo de paralelo seleccionado
final selectedParallelTypeProvider = StateProvider<ParallelType?>((ref) => null);

/// Estado para la pestaña activa en la pantalla de paralelos
final parallelTabIndexProvider = StateProvider<int>((ref) => 0);

/// Estado para las versiones seleccionadas para comparación
final selectedVersionsProvider = StateProvider<List<String>>((ref) => ['RVR1960', 'NVI', 'LBLA']);

/// Provider para estadísticas de paralelos
final parallelStatisticsProvider = FutureProvider.family<ParallelStatistics, int>(
  (ref, verseId) async {
    final parallels = await ref.watch(parallelVersesProvider(verseId).future);

    final typeCount = <ParallelType, int>{};
    for (final parallel in parallels) {
      typeCount[parallel.type] = (typeCount[parallel.type] ?? 0) + 1;
    }

    return ParallelStatistics(
      totalParallels: parallels.length,
      typeDistribution: typeCount,
      averageRelevance: parallels.isEmpty
        ? 0.0
        : parallels.map((p) => p.relevanceScore).reduce((a, b) => a + b) / parallels.length,
    );
  },
);

/// Provider para sugerencias de paralelos basadas en IA
final aiParallelSuggestionsProvider = FutureProvider.family<List<ParallelSuggestion>, int>(
  (ref, verseId) async {
    final repository = ref.watch(bibleParallelRepositoryProvider);

    // Obtener paralelos existentes
    final existingParallels = await repository.getParallelVerses(verseId);

    // Analizar patrones y generar sugerencias
    final suggestions = <ParallelSuggestion>[];

    // Buscar versículos con palabras clave similares
    // Buscar versículos del mismo autor
    // Buscar temas relacionados

    return suggestions;
  },
);

/// Clase para parámetros de versículos paralelos
class ParallelVersesParams {
  final int verseId;
  final ParallelType? type;

  const ParallelVersesParams({
    required this.verseId,
    this.type,
  });
}

/// Clase para parámetros de capítulo
class ChapterParams {
  final int bookId;
  final int chapter;

  const ChapterParams({
    required this.bookId,
    required this.chapter,
  });
}

/// Clase para parámetros de comparación de versiones
class VersionComparisonParams {
  final int verseId;
  final List<String> versionIds;

  const VersionComparisonParams({
    required this.verseId,
    required this.versionIds,
  });
}

/// Clase para parámetros de búsqueda temática
class ThematicSearchParams {
  final String theme;
  final int limit;

  const ThematicSearchParams({
    required this.theme,
    this.limit = 20,
  });
}

/// Clase para estadísticas de paralelos
class ParallelStatistics {
  final int totalParallels;
  final Map<ParallelType, int> typeDistribution;
  final double averageRelevance;

  const ParallelStatistics({
    required this.totalParallels,
    required this.typeDistribution,
    required this.averageRelevance,
  });
}

/// Clase para sugerencias de paralelos
class ParallelSuggestion {
  final int verseId;
  final String reason;
  final double confidence;
  final ParallelType suggestedType;

  const ParallelSuggestion({
    required this.verseId,
    required this.reason,
    required this.confidence,
    required this.suggestedType,
  });
}

/// Extension para BibleParallelRepository
extension BibleParallelRepositoryExtension on BibleParallelRepository {
  /// Obtener grupos de paralelos
  Future<List<ParallelGroup>> getParallelGroups(int verseId) async {
    final parallels = await getParallelVerses(verseId);

    // Agrupar por tipo
    final groups = <ParallelType, List<ParallelVerse>>{};
    for (final parallel in parallels) {
      groups[parallel.type] ??= [];
      groups[parallel.type]!.add(parallel);
    }

    // Crear objetos ParallelGroup
    return groups.entries.map((entry) => ParallelGroup(
      id: entry.key.index,
      name: _getParallelTypeName(entry.key),
      description: _getParallelTypeDescription(entry.key),
      parallels: entry.value,
      color: _getParallelTypeColor(entry.key),
    )).toList();
  }

  /// Obtener versículos temáticos
  Future<List<BibleVerse>> getThematicVerses(String theme, {int limit = 20}) async {
    // Implementar búsqueda temática
    // Por ahora retornamos lista vacía
    return [];
  }

  String _getParallelTypeName(ParallelType type) {
    switch (type) {
      case ParallelType.parallel:
        return 'Pasajes Paralelos';
      case ParallelType.crossReference:
        return 'Referencias Cruzadas';
      case ParallelType.quotation:
        return 'Citas';
      case ParallelType.allusion:
        return 'Alusiones';
      case ParallelType.fulfillment:
        return 'Cumplimientos';
      case ParallelType.typology:
        return 'Tipología';
      case ParallelType.contrast:
        return 'Contrastes';
      case ParallelType.explanation:
        return 'Explicaciones';
    }
  }

  String _getParallelTypeDescription(ParallelType type) {
    switch (type) {
      case ParallelType.parallel:
        return 'Pasajes que narran el mismo evento o enseñanza';
      case ParallelType.crossReference:
        return 'Versículos relacionados temáticamente';
      case ParallelType.quotation:
        return 'Citas directas del Antiguo Testamento';
      case ParallelType.allusion:
        return 'Referencias indirectas a otros pasajes';
      case ParallelType.fulfillment:
        return 'Profecías cumplidas';
      case ParallelType.typology:
        return 'Tipos y sombras proféticas';
      case ParallelType.contrast:
        return 'Pasajes que presentan contrastes';
      case ParallelType.explanation:
        return 'Versículos que explican o amplían';
    }
  }

  String _getParallelTypeColor(ParallelType type) {
    switch (type) {
      case ParallelType.parallel:
        return '#4CAF50';
      case ParallelType.crossReference:
        return '#2196F3';
      case ParallelType.quotation:
        return '#FF9800';
      case ParallelType.allusion:
        return '#9C27B0';
      case ParallelType.fulfillment:
        return '#F44336';
      case ParallelType.typology:
        return '#00BCD4';
      case ParallelType.contrast:
        return '#795548';
      case ParallelType.explanation:
        return '#607D8B';
    }
  }
}