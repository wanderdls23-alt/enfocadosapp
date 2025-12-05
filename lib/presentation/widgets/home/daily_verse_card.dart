import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/themes/app_colors.dart';
import '../../../data/models/daily_verse_model.dart';
import '../../providers/daily_verse_provider.dart';

/// Tarjeta del versículo diario
class DailyVerseCard extends ConsumerWidget {
  final DailyVerseResponse verse;
  final VoidCallback onTap;

  const DailyVerseCard({
    super.key,
    required this.verse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyVerse = verse.dailyVerse;
    final bibleVerse = verse.verse;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.9),
              AppColors.primary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Patrón de fondo
            Positioned(
              right: -30,
              top: -30,
              child: Icon(
                Icons.format_quote,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Versículo del Día',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (dailyVerse.topic != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            dailyVerse.topic!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Texto del versículo
                  Text(
                    '"${bibleVerse.text}"',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Referencia
                  Text(
                    bibleVerse.reference,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Acciones
                  Row(
                    children: [
                      // Rating
                      if (dailyVerse.userRating != null)
                        _buildRating(dailyVerse.userRating!, ref)
                      else
                        _buildRateButton(ref),

                      const Spacer(),

                      // Compartir
                      IconButton(
                        onPressed: () => _shareVerse(ref, context),
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                        ),
                        tooltip: 'Compartir',
                      ),

                      // Favorito
                      IconButton(
                        onPressed: () => _toggleFavorite(ref),
                        icon: Icon(
                          bibleVerse.isFavorite ?? false
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.white,
                        ),
                        tooltip: 'Favorito',
                      ),
                    ],
                  ),

                  // Reflexión
                  if (dailyVerse.reflection != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 16,
                                color: AppColors.gold,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Reflexión',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dailyVerse.reflection!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRating(int rating, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            ref.read(dailyVerseProvider.notifier).rateVerse(index + 1);
          },
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: AppColors.gold,
            size: 20,
          ),
        );
      }),
    );
  }

  Widget _buildRateButton(WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _showRatingDialog(ref),
      icon: const Icon(
        Icons.star_border,
        color: Colors.white,
        size: 18,
      ),
      label: const Text(
        'Calificar',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  void _showRatingDialog(WidgetRef ref) {
    // Implementar diálogo de calificación
  }

  Future<void> _shareVerse(WidgetRef ref, BuildContext context) async {
    final shareUrl = await ref.read(dailyVerseProvider.notifier).getShareUrl('app');
    final text = '"${verse.verse.text}"\n\n${verse.verse.reference}\n\n$shareUrl';

    await Share.share(
      text,
      subject: 'Versículo del día - Enfocados en Dios TV',
    );

    ref.read(dailyVerseProvider.notifier).markAsShared('app');
  }

  void _toggleFavorite(WidgetRef ref) {
    // Implementar toggle favorito
  }
}