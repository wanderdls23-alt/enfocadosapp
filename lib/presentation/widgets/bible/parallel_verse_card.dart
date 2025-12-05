import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/bible_parallel_models.dart';

/// Tarjeta para mostrar un versículo paralelo
class ParallelVerseCard extends StatelessWidget {
  final ParallelVerse parallelVerse;
  final VoidCallback? onTap;
  final bool showRelevanceScore;
  final bool showRelationship;

  const ParallelVerseCard({
    Key? key,
    required this.parallelVerse,
    this.onTap,
    this.showRelevanceScore = true,
    this.showRelationship = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetVerse = parallelVerse.targetVerse;

    if (targetVerse == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getTypeColor(parallelVerse.type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con referencia y tipo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _getTypeIcon(parallelVerse.type),
                          size: 20,
                          color: _getTypeColor(parallelVerse.type),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${targetVerse.book?.name ?? ''} ${targetVerse.chapter}:${targetVerse.verse}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getTypeColor(parallelVerse.type),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showRelevanceScore)
                    _buildRelevanceIndicator(),
                ],
              ),

              // Relación o descripción
              if (showRelationship && parallelVerse.relationship != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(parallelVerse.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    parallelVerse.relationship!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getTypeColor(parallelVerse.type),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              // Texto del versículo
              const SizedBox(height: 12),
              Text(
                targetVerse.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),

              // Versión de la Biblia
              const SizedBox(height: 8),
              Text(
                targetVerse.version?.name ?? 'RVR 1960',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelevanceIndicator() {
    final relevancePercentage = (parallelVerse.relevanceScore * 100).round();
    Color relevanceColor;

    if (relevancePercentage >= 80) {
      relevanceColor = Colors.green;
    } else if (relevancePercentage >= 60) {
      relevanceColor = Colors.orange;
    } else {
      relevanceColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: relevanceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: relevanceColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_graph,
            size: 16,
            color: relevanceColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$relevancePercentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: relevanceColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(ParallelType type) {
    switch (type) {
      case ParallelType.parallel:
        return const Color(0xFF4CAF50);
      case ParallelType.crossReference:
        return const Color(0xFF2196F3);
      case ParallelType.quotation:
        return const Color(0xFFFF9800);
      case ParallelType.allusion:
        return const Color(0xFF9C27B0);
      case ParallelType.fulfillment:
        return const Color(0xFFF44336);
      case ParallelType.typology:
        return const Color(0xFF00BCD4);
      case ParallelType.contrast:
        return const Color(0xFF795548);
      case ParallelType.explanation:
        return const Color(0xFF607D8B);
    }
  }

  IconData _getTypeIcon(ParallelType type) {
    switch (type) {
      case ParallelType.parallel:
        return Icons.compare_arrows;
      case ParallelType.crossReference:
        return Icons.link;
      case ParallelType.quotation:
        return Icons.format_quote;
      case ParallelType.allusion:
        return Icons.lightbulb_outline;
      case ParallelType.fulfillment:
        return Icons.check_circle_outline;
      case ParallelType.typology:
        return Icons.layers;
      case ParallelType.contrast:
        return Icons.swap_horiz;
      case ParallelType.explanation:
        return Icons.info_outline;
    }
  }
}