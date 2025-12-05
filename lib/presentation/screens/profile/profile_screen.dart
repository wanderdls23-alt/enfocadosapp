import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../providers/daily_verse_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar estadísticas
    Future.microtask(() {
      ref.read(verseStatsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authStateProvider);
    final verseStats = ref.watch(verseStatsProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: LoadingIndicator(),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar con imagen de perfil
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.white,
                              backgroundImage: user.photoUrl != null
                                  ? CachedNetworkImageProvider(user.photoUrl!)
                                  : null,
                              child: user.photoUrl == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppColors.primary,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Nombre
                      Text(
                        user.displayName ?? user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Badge de verificación
                      if (user.emailVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Cuenta Verificada',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  context.push(Routes.settings);
                },
              ),
            ],
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Estadísticas
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Mi Progreso Espiritual',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      verseStats.when(
                        data: (stats) => _buildStatistics(stats),
                        loading: () => const ShimmerBox(
                          width: double.infinity,
                          height: 100,
                        ),
                        error: (_, __) => const Text('Error al cargar estadísticas'),
                      ),
                    ],
                  ),
                ),

                // Opciones del perfil
                _buildProfileSection(
                  title: 'Mi Cuenta',
                  items: [
                    _ProfileOption(
                      icon: Icons.person_outline,
                      title: 'Editar Perfil',
                      subtitle: 'Actualiza tu información personal',
                      onTap: () => context.push(Routes.editProfile),
                    ),
                    _ProfileOption(
                      icon: Icons.lock_outline,
                      title: 'Cambiar Contraseña',
                      subtitle: 'Actualiza tu contraseña de acceso',
                      onTap: () {
                        // TODO: Implementar cambio de contraseña
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.notifications_outlined,
                      title: 'Notificaciones',
                      subtitle: 'Gestiona tus preferencias',
                      onTap: () => context.push(Routes.preferences),
                    ),
                  ],
                ),

                _buildProfileSection(
                  title: 'Mi Contenido',
                  items: [
                    _ProfileOption(
                      icon: Icons.bookmark_outline,
                      title: 'Versículos Guardados',
                      subtitle: '${user.preferences?.favoriteVerses ?? 0} versículos',
                      onTap: () => context.push(Routes.bibleFavorites),
                    ),
                    _ProfileOption(
                      icon: Icons.note_outlined,
                      title: 'Mis Notas',
                      subtitle: 'Notas y reflexiones personales',
                      onTap: () => context.push(Routes.bibleNotes),
                    ),
                    _ProfileOption(
                      icon: Icons.history,
                      title: 'Historial',
                      subtitle: 'Videos y lecturas recientes',
                      onTap: () => context.push(Routes.videoHistory),
                    ),
                    _ProfileOption(
                      icon: Icons.download_outlined,
                      title: 'Descargas',
                      subtitle: 'Contenido disponible offline',
                      onTap: () => context.push(Routes.videoDownloads),
                    ),
                  ],
                ),

                _buildProfileSection(
                  title: 'Soporte',
                  items: [
                    _ProfileOption(
                      icon: Icons.help_outline,
                      title: 'Centro de Ayuda',
                      subtitle: 'Preguntas frecuentes y soporte',
                      onTap: () => context.push(Routes.help),
                    ),
                    _ProfileOption(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacidad',
                      subtitle: 'Políticas y términos de uso',
                      onTap: () => context.push(Routes.privacy),
                    ),
                    _ProfileOption(
                      icon: Icons.info_outline,
                      title: 'Acerca de',
                      subtitle: 'Versión ${user.appVersion ?? '1.0.0'}',
                      onTap: () => context.push(Routes.about),
                    ),
                  ],
                ),

                // Botón de cerrar sesión
                Container(
                  margin: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(DailyVerseStats stats) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.calendar_today,
              value: stats.totalDays.toString(),
              label: 'Días activo',
              color: AppColors.primary,
            ),
            _buildStatItem(
              icon: Icons.local_fire_department,
              value: stats.consecutiveDays.toString(),
              label: 'Racha actual',
              color: AppColors.gold,
            ),
            _buildStatItem(
              icon: Icons.menu_book,
              value: stats.totalRead.toString(),
              label: 'Versículos leídos',
              color: AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Barra de progreso semanal
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lectura esta semana',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${stats.readPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: stats.readPercentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection({
    required String title,
    required List<_ProfileOption> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: items
                  .map((item) => Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item.icon,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: item.subtitle != null
                                ? Text(
                                    item.subtitle!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                : null,
                            trailing: item.trailing ??
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                            onTap: item.onTap,
                          ),
                          if (items.last != item)
                            Divider(
                              height: 1,
                              indent: 72,
                              endIndent: 16,
                            ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('¿Cerrar sesión?'),
          content: const Text(
            'Al cerrar sesión deberás volver a iniciar sesión para acceder a tu cuenta.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await ref.read(authStateProvider).logout();
                if (context.mounted) {
                  context.go(Routes.login);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileOption {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });
}