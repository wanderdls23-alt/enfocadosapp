import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';

/// Acciones rápidas del home
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Acceso Rápido',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                QuickActionItem(
                  icon: Icons.church_outlined,
                  label: 'En Vivo',
                  color: AppColors.error,
                  onTap: () => context.push('${Routes.videos}?category=live'),
                ),
                QuickActionItem(
                  icon: Icons.favorite_outline,
                  label: 'Versículo',
                  color: AppColors.primary,
                  onTap: () => context.push(Routes.dailyVerse),
                ),
                QuickActionItem(
                  icon: Icons.groups_outlined,
                  label: 'Comunidad',
                  color: AppColors.success,
                  onTap: () => context.push(Routes.community),
                ),
                QuickActionItem(
                  icon: Icons.pray_outline,
                  label: 'Oración',
                  color: AppColors.gold,
                  onTap: () => context.push(Routes.prayerWall),
                ),
                QuickActionItem(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Donar',
                  color: AppColors.info,
                  onTap: () => context.push(Routes.donations),
                ),
                QuickActionItem(
                  icon: Icons.bookmark_outline,
                  label: 'Guardados',
                  color: AppColors.warning,
                  onTap: () => context.push(Routes.bibleFavorites),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Item de acción rápida
class QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.05)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension para el ícono de oración (no existe en Material Icons)
extension on Icons {
  static const IconData pray_outline = IconData(
    0xe4db,
    fontFamily: 'MaterialIcons',
  );
}