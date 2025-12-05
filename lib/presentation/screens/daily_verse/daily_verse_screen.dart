import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import '../../../core/theme/app_colors.dart';
import '../../../data/models/daily_verse_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/daily_verse_provider.dart';
import '../../widgets/common/loading_widget.dart';

/// Pantalla del versículo diario con IA
class DailyVerseScreen extends ConsumerStatefulWidget {
  const DailyVerseScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyVerseScreen> createState() => _DailyVerseScreenState();
}

class _DailyVerseScreenState extends ConsumerState<DailyVerseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showReflection = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dailyVerseAsync = ref.watch(dailyVerseProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: dailyVerseAsync.when(
        data: (verse) => _buildVerseContent(verse, user),
        loading: () => const LoadingWidget(),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(dailyVerseProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerseContent(DailyVerse verse, dynamic user) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.gold.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Patrón de fondo
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // AppBar personalizado
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      Text(
                        'Versículo del Día',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today, color: Colors.white),
                        onPressed: () => _showCalendar(context),
                      ),
                    ],
                  ),
                ),

                // Contenido con scroll
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Fecha
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatDate(verse.date),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Tarjeta del versículo
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Texto del versículo
                                  SelectableText(
                                    verse.verseText,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      height: 1.6,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 24),

                                  // Referencia
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.book,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        verse.reference,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Versión
                                  Text(
                                    verse.version,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Botones de acción
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ActionButton(
                                icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                                label: 'Favorito',
                                color: _isFavorite ? Colors.red : Colors.white,
                                onPressed: () => _toggleFavorite(verse),
                              ),
                              _ActionButton(
                                icon: Icons.share,
                                label: 'Compartir',
                                onPressed: () => _shareVerse(verse),
                              ),
                              _ActionButton(
                                icon: Icons.copy,
                                label: 'Copiar',
                                onPressed: () => _copyVerse(verse),
                              ),
                              _ActionButton(
                                icon: Icons.image,
                                label: 'Imagen',
                                onPressed: () => _generateImage(verse),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Reflexión AI
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: _showReflection ? null : 60,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.9),
                                  Colors.white.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _showReflection = !_showReflection;
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            color: AppColors.gold,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Reflexión personalizada con IA',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        _showReflection
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                      ),
                                    ],
                                  ),
                                ),
                                if (_showReflection) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    verse.aiReflection ??
                                        'Basado en tu historial de lectura, este versículo te recuerda la importancia de la perseverancia. Has estado leyendo sobre las pruebas en Santiago, y este versículo complementa perfectamente ese estudio.',
                                    style: const TextStyle(
                                      height: 1.6,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (verse.personalizedMessage != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              verse.personalizedMessage!,
                                              style: TextStyle(
                                                color: AppColors.primary,
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

                        const SizedBox(height: 24),

                        // Aplicación práctica
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: AppColors.gold,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Aplicación práctica',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (verse.practicalApplication != null)
                                Text(
                                  verse.practicalApplication!,
                                  style: const TextStyle(
                                    height: 1.6,
                                    fontSize: 15,
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _ApplicationItem(
                                      icon: Icons.favorite,
                                      title: 'En tu vida personal',
                                      description: 'Reflexiona cómo este versículo aplica a tus circunstancias actuales.',
                                    ),
                                    const SizedBox(height: 12),
                                    _ApplicationItem(
                                      icon: Icons.people,
                                      title: 'En tus relaciones',
                                      description: 'Considera cómo puedes aplicar esta enseñanza con tu familia y amigos.',
                                    ),
                                    const SizedBox(height: 12),
                                    _ApplicationItem(
                                      icon: Icons.work,
                                      title: 'En tu trabajo',
                                      description: 'Piensa en cómo este principio puede guiar tus decisiones profesionales.',
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Oración sugerida
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.prayer_times,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Oración sugerida',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                verse.prayerSuggestion ??
                                    'Señor, ayúdame a aplicar esta palabra en mi vida diaria. Que tu Espíritu Santo me guíe y me dé sabiduría para vivir conforme a tu voluntad. Amén.',
                                style: const TextStyle(
                                  height: 1.6,
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Enlaces relacionados
                        if (verse.relatedVerses != null && verse.relatedVerses!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.link,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Versículos relacionados',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...verse.relatedVerses!.map((relatedVerse) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: InkWell(
                                        onTap: () => _navigateToVerse(relatedVerse),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.book,
                                                color: AppColors.primary,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                relatedVerse,
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const Spacer(),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: AppColors.primary,
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),

                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    const days = [
      'Domingo', 'Lunes', 'Martes', 'Miércoles',
      'Jueves', 'Viernes', 'Sábado'
    ];

    return '${days[date.weekday % 7]}, ${date.day} de ${months[date.month - 1]} de ${date.year}';
  }

  void _toggleFavorite(DailyVerse verse) {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      ref.read(dailyVerseProvider.notifier).saveFavorite(verse);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Versículo guardado en favoritos'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ref.read(dailyVerseProvider.notifier).removeFavorite(verse.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Versículo eliminado de favoritos'),
        ),
      );
    }
  }

  void _shareVerse(DailyVerse verse) {
    final text = '${verse.verseText}\n\n${verse.reference} ${verse.version}\n\n'
        'Compartido desde Enfocados en Dios TV';

    Share.share(text, subject: 'Versículo del Día');
  }

  void _copyVerse(DailyVerse verse) {
    final text = '${verse.verseText}\n${verse.reference} ${verse.version}';
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Versículo copiado al portapapeles'),
      ),
    );
  }

  void _generateImage(DailyVerse verse) {
    context.push('/daily-verse/image-generator', extra: verse);
  }

  void _showCalendar(BuildContext context) {
    context.push('/daily-verse/calendar');
  }

  void _navigateToVerse(String reference) {
    context.push('/bible/verse', extra: {'reference': reference});
  }
}

/// Botón de acción
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item de aplicación práctica
class _ApplicationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ApplicationItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Painter para el patrón de fondo
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Dibujar círculos decorativos
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.1),
      80,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.3),
      120,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      100,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.9),
      60,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}