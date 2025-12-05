import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/bible_parallel_models.dart';

/// Widget para comparar diferentes versiones de la Biblia
class VersionComparisonWidget extends StatefulWidget {
  final List<VersionComparison> comparisons;
  final Function(String versionId)? onVersionTap;
  final bool showDifferences;

  const VersionComparisonWidget({
    Key? key,
    required this.comparisons,
    this.onVersionTap,
    this.showDifferences = true,
  }) : super(key: key);

  @override
  State<VersionComparisonWidget> createState() => _VersionComparisonWidgetState();
}

class _VersionComparisonWidgetState extends State<VersionComparisonWidget> {
  int _selectedIndex = 0;
  bool _showSideBySide = false;

  @override
  Widget build(BuildContext context) {
    if (widget.comparisons.isEmpty) {
      return const Center(
        child: Text('No hay versiones disponibles para comparar'),
      );
    }

    return Column(
      children: [
        // Controles de visualización
        _buildViewControls(),

        const SizedBox(height: 16),

        // Contenido según modo de visualización
        Expanded(
          child: _showSideBySide
              ? _buildSideBySideView()
              : _buildTabbedView(),
        ),
      ],
    );
  }

  Widget _buildViewControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Selector de vista
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.tab),
                label: Text('Pestañas'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.view_column),
                label: Text('Lado a lado'),
              ),
            ],
            selected: {_showSideBySide},
            onSelectionChanged: (value) {
              setState(() {
                _showSideBySide = value.first;
              });
            },
          ),

          // Indicador de diferencias
          if (widget.showDifferences)
            IconButton(
              icon: const Icon(Icons.difference),
              onPressed: _showDifferencesDialog,
              tooltip: 'Ver diferencias',
            ),
        ],
      ),
    );
  }

  Widget _buildTabbedView() {
    return Column(
      children: [
        // Tabs de versiones
        Container(
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.comparisons.length,
            itemBuilder: (context, index) {
              final comparison = widget.comparisons[index];
              final isSelected = index == _selectedIndex;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  widget.onVersionTap?.call(comparison.versionId);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        comparison.versionName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (comparison.language != null)
                        Text(
                          comparison.language!,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white.withOpacity(0.8)
                                : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Contenido del versículo seleccionado
        Expanded(
          child: _buildVersionCard(widget.comparisons[_selectedIndex]),
        ),
      ],
    );
  }

  Widget _buildSideBySideView() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: widget.comparisons.length,
      itemBuilder: (context, index) {
        return Container(
          width: MediaQuery.of(context).size.width * 0.8,
          margin: const EdgeInsets.only(right: 16),
          child: _buildVersionCard(widget.comparisons[index]),
        );
      },
    );
  }

  Widget _buildVersionCard(VersionComparison comparison) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => widget.onVersionTap?.call(comparison.versionId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con versión e información
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comparison.versionName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (comparison.language != null)
                        Text(
                          comparison.language!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  if (comparison.year != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        comparison.year.toString(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Texto del versículo
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (comparison.verseText != null)
                        SelectableText(
                          comparison.verseText!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            fontSize: 16,
                          ),
                        ),

                      // Diferencias destacadas
                      if (widget.showDifferences && comparison.differences != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.difference,
                                    size: 16,
                                    color: Colors.amber[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Diferencias principales',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...comparison.differences!.map((diff) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• '),
                                        Expanded(
                                          child: Text(
                                            diff,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ],

                      // Notas de traducción
                      if (comparison.translationNotes != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notes,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Notas de traducción',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                comparison.translationNotes!,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDifferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Análisis de Diferencias'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.comparisons.length - 1,
            itemBuilder: (context, index) {
              final current = widget.comparisons[index];
              final next = widget.comparisons[index + 1];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${current.versionName} vs ${next.versionName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _calculateDifference(
                          current.verseText ?? '',
                          next.verseText ?? '',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _calculateDifference(String text1, String text2) {
    final words1 = text1.toLowerCase().split(' ');
    final words2 = text2.toLowerCase().split(' ');
    final differentWords = <String>[];

    for (final word in words1) {
      if (!words2.contains(word) && word.length > 2) {
        differentWords.add(word);
      }
    }

    if (differentWords.isEmpty) {
      return 'Las versiones son muy similares';
    }

    return 'Palabras diferentes: ${differentWords.take(5).join(', ')}${differentWords.length > 5 ? '...' : ''}';
  }
}