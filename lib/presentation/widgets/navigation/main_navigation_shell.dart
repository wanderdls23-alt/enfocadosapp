import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../providers/notification_provider.dart';
import '../common/notification_badge.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final currentIndex = widget.navigationShell.currentIndex;
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Container(
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
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Biblia',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            activeIcon: Icon(Icons.play_circle),
            label: 'Videos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Academia',
          ),
          BottomNavigationBarItem(
            icon: unreadCount > 0
                ? NotificationBadge(
                    child: const Icon(Icons.more_horiz),
                  )
                : const Icon(Icons.more_horiz),
            activeIcon: unreadCount > 0
                ? NotificationBadge(
                    child: const Icon(Icons.more_horiz),
                  )
                : const Icon(Icons.more_horiz),
            label: 'Más',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

// Widget para la pantalla "Más" con todas las opciones adicionales
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Más opciones'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Sección de Usuario
          _buildSection(
            title: 'Mi Cuenta',
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Mi Perfil'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.profile),
              ),
              ListTile(
                leading: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (unreadCount > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
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
                ),
                title: const Text('Notificaciones'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => context.push(Routes.notifications),
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_outline),
                title: const Text('Favoritos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.favorites),
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Historial'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.history),
              ),
            ],
          ),

          // Sección de Comunidad
          _buildSection(
            title: 'Comunidad',
            children: [
              ListTile(
                leading: const Icon(Icons.live_tv),
                title: const Text('En Vivo'),
                subtitle: const Text('Transmisión en directo'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onTap: () => context.push(Routes.live),
              ),
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Eventos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.events),
              ),
              ListTile(
                leading: const Icon(Icons.group_outlined),
                title: const Text('Muro de Oración'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.prayerWall),
              ),
              ListTile(
                leading: const Icon(Icons.message_outlined),
                title: const Text('Testimonios'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.testimonies),
              ),
            ],
          ),

          // Sección de Herramientas
          _buildSection(
            title: 'Herramientas',
            children: [
              ListTile(
                leading: const Icon(Icons.auto_stories),
                title: const Text('Planes de Lectura'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.readingPlans),
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_outlined),
                title: const Text('Versículo del Día'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.dailyVerse),
              ),
              ListTile(
                leading: const Icon(Icons.quiz_outlined),
                title: const Text('Quiz Bíblico'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.bibleQuiz),
              ),
            ],
          ),

          // Sección de Apoyo
          _buildSection(
            title: 'Apoya el Ministerio',
            children: [
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('Donaciones'),
                subtitle: const Text('Apoya nuestra misión'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.donations),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Compartir App'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Implementar compartir
                },
              ),
            ],
          ),

          // Sección de Configuración
          _buildSection(
            title: 'Configuración',
            children: [
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configuración'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.settings),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Acerca de'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.about),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Ayuda y Soporte'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.help),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _showLogoutConfirmation(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Implementar logout
                // await ref.read(authProvider.notifier).logout();
                context.go(Routes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}