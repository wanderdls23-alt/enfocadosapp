import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/themes/app_colors.dart';

/// Indicador de carga personalizado
class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const LoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppColors.primary,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer effect base widget
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer para el versículo diario
class ShimmerDailyVerseCard extends StatelessWidget {
  const ShimmerDailyVerseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: 150, height: 20),
            const SizedBox(height: 12),
            const ShimmerBox(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            const ShimmerBox(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            const ShimmerBox(width: 200, height: 16),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 100, height: 14),
                ShimmerBox(width: 80, height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer para video destacado
class ShimmerFeaturedVideoCard extends StatelessWidget {
  const ShimmerFeaturedVideoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const ShimmerBox(
            width: double.infinity,
            height: 200,
            borderRadius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: double.infinity, height: 18),
                SizedBox(height: 8),
                ShimmerBox(width: 150, height: 14),
                SizedBox(height: 8),
                Row(
                  children: [
                    ShimmerBox(width: 60, height: 14),
                    SizedBox(width: 16),
                    ShimmerBox(width: 60, height: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer para carrusel de cursos
class ShimmerCourseCarousel extends StatelessWidget {
  const ShimmerCourseCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 180,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(
                    width: double.infinity,
                    height: 100,
                    borderRadius: 0,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: double.infinity, height: 16),
                        SizedBox(height: 8),
                        ShimmerBox(width: 100, height: 14),
                        SizedBox(height: 12),
                        ShimmerBox(width: 80, height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shimmer para lista de items
class ShimmerListItem extends StatelessWidget {
  final bool showImage;
  final double imageSize;

  const ShimmerListItem({
    super.key,
    this.showImage = true,
    this.imageSize = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (showImage) ...[
            ShimmerBox(
              width: imageSize,
              height: imageSize,
              borderRadius: 8,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: double.infinity, height: 16),
                SizedBox(height: 8),
                ShimmerBox(width: 150, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading overlay para operaciones
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: LoadingIndicator(
              message: message,
            ),
          ),
      ],
    );
  }
}