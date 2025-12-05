import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../data/models/bible_models.dart';
import '../../../data/models/bible_parallel_models.dart';
import '../../providers/bible_parallel_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';

class ParallelVersesScreen extends ConsumerStatefulWidget {
  final int verseId;
  final BibleVerse? initialVerse;

  const ParallelVersesScreen({
    super.key,
    required this.verseId,
    this.initialVerse,
  });

  @override
  ConsumerState<ParallelVersesScreen> createState() => _ParallelVersesScreenState();
}

class _ParallelVersesScreenState extends ConsumerState<ParallelVersesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ParallelType? _selectedType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Cargar datos
    Future.microtask(() {
      ref.read(parallelVersesProvider(widget.verseId).notifier).loadParallels();
      ref.read(versionComparisonProvider(widget.verseId).notifier).loadComparison();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Versículos Paralelos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.initialVerse != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.initialVerse!.reference,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.initialVerse!.text,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.gold,
                indicatorWeight: 3,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'PARALELOS'),
                  Tab(text: 'REFERENCIAS'),
                  Tab(text: 'VERSIONES'),
                  Tab(text: 'HARMONÍA'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab de Versículos Paralelos
            _buildParallelsTab(),

            // Tab de Referencias Cruzadas
            _buildCrossReferencesTab(),

            // Tab de Comparación de Versiones
            _buildVersionComparisonTab(),

            // Tab de Harmonía
            _buildHarmonyTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildParallelsTab() {
    final parallels = ref.watch(parallelVersesProvider(widget.verseId));

    return parallels.when(
      data: (parallelList) {
        if (parallelList.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.link_off,
            title: 'Sin versículos paralelos',
            message: 'No se encontraron versículos paralelos para esta referencia',
          );
        }

        // Agrupar por tipo
        final groupedParallels = <ParallelType, List<ParallelVerse>>{};
        for (final parallel in parallelList) {
          groupedParallels.putIfAbsent(parallel.type, () => []).add(parallel);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groupedParallels.length,
          itemBuilder: (context, index) {
            final type = groupedParallels.keys.elementAt(index);
            final verses = groupedParallels[type]!;

            return _buildParallelSection(
              title: _getTypeTitle(type),
              icon: _getTypeIcon(type),
              verses: verses,
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => CustomErrorWidget(
        message: 'Error al cargar versículos paralelos',
        onRetry: () {
          ref.read(parallelVersesProvider(widget.verseId).notifier).loadParallels();
        },
      ),
    );
  }

  Widget _buildCrossReferencesTab() {
    final crossRefs = ref.watch(crossReferencesProvider(widget.verseId));

    return crossRefs.when(
      data: (references) {
        if (references.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.link_off,
            title: 'Sin referencias cruzadas',
            message: 'No se encontraron referencias cruzadas',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: references.length,
          itemBuilder: (context, index) {
            final verse = references[index];
            return _buildVerseCard(verse);
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => CustomErrorWidget(
        message: 'Error al cargar referencias',
        onRetry: () {
          ref.invalidate(crossReferencesProvider(widget.verseId));
        },
      ),
    );
  }

  Widget _buildVersionComparisonTab() {
    final comparison = ref.watch(versionComparisonProvider(widget.verseId));

    return comparison.when(
      data: (versionComparison) {
        if (versionComparison == null) {
          return const EmptyStateWidget(
            icon: Icons.translate,
            title: 'Sin comparaciones',
            message: 'No se pudo cargar la comparación de versiones',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: versionComparison.versions.length,
          itemBuilder: (context, index) {
            final version = versionComparison.versions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${version.version.name} (${version.version.code})',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (version.hasStrong)
                          Icon(
                            Icons.link,
                            size: 16,
                            color: AppColors.gold,
                          ),
                        if (version.hasFootnotes)
                          Icon(
                            Icons.note,
                            size: 16,
                            color: AppColors.info,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      version.text,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => CustomErrorWidget(
        message: 'Error al cargar comparación',
        onRetry: () {
          ref.read(versionComparisonProvider(widget.verseId).notifier).loadComparison();
        },
      ),
    );
  }

  Widget _buildHarmonyTab() {
    final harmony = ref.watch(gospelHarmonyProvider);

    return harmony.when(
      data: (harmonyList) {
        if (harmonyList.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.view_list,
            title: 'Sin harmonía',
            message: 'No se encontró harmonía para este pasaje',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: harmonyList.length,
          itemBuilder: (context, index) {
            final event = harmonyList[index];
            return _buildHarmonyCard(event);
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, _) => CustomErrorWidget(
        message: 'Error al cargar harmonía',
        onRetry: () {
          ref.invalidate(gospelHarmonyProvider);
        },
      ),
    );
  }

  Widget _buildParallelSection({
    required String title,
    required String icon,
    required List<ParallelVerse> verses,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  verses.length.toString(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...verses.map((parallel) => _buildParallelCard(parallel)),
        ],
      ),
    );
  }

  Widget _buildParallelCard(ParallelVerse parallel) {
    if (parallel.targetVerse == null) return const SizedBox();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navegar al versículo
          context.push('/bible/verse/${parallel.targetVerseId}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      parallel.targetVerse!.reference,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (parallel.relevanceScore > 0.8)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: AppColors.gold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Alta relevancia',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                parallel.targetVerse!.text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (parallel.relationship != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          parallel.relationship!,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseCard(BibleVerse verse) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push('/bible/verse/${verse.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                verse.reference,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                verse.text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHarmonyCard(GospelHarmony event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_note,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.event,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (event.period != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.period!,
                  style: TextStyle(
                    color: AppColors.info,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: event.references.map((ref) {
                final color = Color(
                  int.parse(ref.gospelColor.replaceFirst('#', '0xFF')),
                );
                return GestureDetector(
                  onTap: () {
                    // Navegar al pasaje
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${ref.gospel} ${ref.reference}',
                          style: TextStyle(
                            color: color.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (event.notes != null) ...[
              const SizedBox(height: 12),
              Text(
                event.notes!,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTypeTitle(ParallelType type) {
    switch (type) {
      case ParallelType.parallel:
        return 'Pasajes Paralelos';
      case ParallelType.crossReference:
        return 'Referencias Cruzadas';
      case ParallelType.quotation:
        return 'Citas Directas';
      case ParallelType.allusion:
        return 'Alusiones';
      case ParallelType.fulfillment:
        return 'Cumplimientos Proféticos';
      case ParallelType.typology:
        return 'Tipología';
      case ParallelType.contrast:
        return 'Contrastes';
      case ParallelType.explanation:
        return 'Explicaciones';
    }
  }

  String _getTypeIcon(ParallelType type) {
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
}