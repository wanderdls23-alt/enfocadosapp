import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';

/// Provider para el índice del tab actual
final currentTabProvider = StateProvider<int>((ref) => 0);

/// Pantalla principal con navegación inferior
class MainScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // Mapeo de rutas a índices del bottom navigation
  int _calculateSelectedIndex(String location) {
    if (location.startsWith(Routes.home)) return 0;
    if (location.startsWith(Routes.bible)) return 1;
    if (location.startsWith(Routes.videos)) return 2;
    if (location.startsWith(Routes.academy)) return 3;
    if (location.startsWith(Routes.profile)) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    ref.read(currentTabProvider.notifier).state = index;

    switch (index) {
      case 0:
        context.go(Routes.home);
        break;
      case 1:
        context.go(Routes.bible);
        break;
      case 2:
        context.go(Routes.videos);
        break;
      case 3:
        context.go(Routes.academy);
        break;
      case 4:
        context.go(Routes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _calculateSelectedIndex(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.backgroundDark
              : Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          iconSize: 24,
          elevation: 0,
          items: [
            _buildNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Inicio',
              index: 0,
              currentIndex: selectedIndex,
            ),
            _buildNavItem(
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book,
              label: 'Biblia',
              index: 1,
              currentIndex: selectedIndex,
            ),
            _buildNavItem(
              icon: Icons.play_circle_outline,
              activeIcon: Icons.play_circle,
              label: 'Videos',
              index: 2,
              currentIndex: selectedIndex,
            ),
            _buildNavItem(
              icon: Icons.school_outlined,
              activeIcon: Icons.school,
              label: 'Academia',
              index: 3,
              currentIndex: selectedIndex,
            ),
            _buildNavItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Perfil',
              index: 4,
              currentIndex: selectedIndex,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
  }) {
    final isSelected = index == currentIndex;

    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        child: Icon(
          isSelected ? activeIcon : icon,
          size: isSelected ? 26 : 24,
        ),
      ),
      label: label,
      backgroundColor: Colors.transparent,
    );
  }
}

/// Widget para mostrar badge de notificaciones
class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}