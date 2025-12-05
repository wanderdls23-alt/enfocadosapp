import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/loading_indicator.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isEditingProfile = false;

  // Form controllers
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = ref.read(authStateProvider).value?.user;
    if (user != null) {
      _displayNameController.text = user.displayName;
      _bioController.text = user.bio ?? '';
      _phoneController.text = user.phone ?? '';
      _locationController.text = user.location ?? '';
      _websiteController.text = user.website ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value?.user;
    final userStats = ref.watch(userStatsProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_outline,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'No has iniciado sesión',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push(Routes.login),
                child: const Text('Iniciar Sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background pattern
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Profile content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Avatar with edit button
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                backgroundImage: user.avatarUrl != null
                                    ? CachedNetworkImageProvider(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(
                                        user.displayName[0].toUpperCase(),
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    onPressed: _changeProfilePicture,
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Name and username
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${user.username}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                          // Premium badge
                          if (user.isPremium) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.gold,
                                    AppColors.gold.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          // Stats
                          userStats.when(
                            data: (stats) => _buildStatsRow(stats),
                            loading: () => const LoadingIndicator(
                              color: Colors.white,
                              size: 20,
                            ),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: const Text(
                'Mi Perfil',
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isEditingProfile ? Icons.check : Icons.edit,
                  color: Colors.white,
                ),
                onPressed: _toggleEditMode,
              ),
            ],
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Información'),
                  Tab(text: 'Actividad'),
                  Tab(text: 'Logros'),
                  Tab(text: 'Contenido'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildActivityTab(),
                _buildAchievementsTab(),
                _buildContentTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserStats stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(
          value: stats.bibleStreak.toString(),
          label: 'Días seguidos',
          icon: Icons.local_fire_department,
        ),
        _StatItem(
          value: stats.coursesCompleted.toString(),
          label: 'Cursos',
          icon: Icons.school,
        ),
        _StatItem(
          value: stats.videosWatched.toString(),
          label: 'Videos',
          icon: Icons.play_circle,
        ),
        _StatItem(
          value: _formatDuration(stats.totalReadingTime),
          label: 'Lectura',
          icon: Icons.menu_book,
        ),
      ],
    );
  }

  Widget _buildInfoTab() {
    final user = ref.watch(authStateProvider).value!.user!;

    if (_isEditingProfile) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildEditableField(
              controller: _displayNameController,
              label: 'Nombre completo',
              icon: Icons.person,
            ),
            _buildEditableField(
              controller: _bioController,
              label: 'Biografía',
              icon: Icons.edit,
              maxLines: 3,
            ),
            _buildEditableField(
              controller: _phoneController,
              label: 'Teléfono',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            _buildEditableField(
              controller: _locationController,
              label: 'Ubicación',
              icon: Icons.location_on,
            ),
            _buildEditableField(
              controller: _websiteController,
              label: 'Sitio web',
              icon: Icons.link,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _loadUserData();
                      _toggleEditMode();
                    },
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            title: 'Información Personal',
            items: [
              _InfoItem(
                icon: Icons.email,
                label: 'Correo',
                value: user.email,
              ),
              _InfoItem(
                icon: Icons.phone,
                label: 'Teléfono',
                value: user.phone ?? 'No especificado',
              ),
              _InfoItem(
                icon: Icons.location_on,
                label: 'Ubicación',
                value: user.location ?? 'No especificada',
              ),
              _InfoItem(
                icon: Icons.link,
                label: 'Sitio web',
                value: user.website ?? 'No especificado',
              ),
              _InfoItem(
                icon: Icons.cake,
                label: 'Miembro desde',
                value: _formatDate(user.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Biografía',
            content: user.bio?.isNotEmpty == true
                ? user.bio!
                : 'No has agregado una biografía aún',
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Preferencias',
            items: [
              _InfoItem(
                icon: Icons.menu_book,
                label: 'Versión de Biblia',
                value: user.preferences.bibleVersion,
              ),
              _InfoItem(
                icon: Icons.language,
                label: 'Idioma',
                value: 'Español',
              ),
              _InfoItem(
                icon: Icons.notifications,
                label: 'Notificaciones',
                value: user.preferences.notificationsEnabled
                    ? 'Activadas'
                    : 'Desactivadas',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final activities = ref.watch(userActivityProvider);

    return activities.when(
      data: (activityList) {
        if (activityList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timeline,
                  size: 80,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay actividad reciente',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activityList.length,
          itemBuilder: (context, index) {
            final activity = activityList[index];
            return _ActivityCard(activity: activity);
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (_, __) => const Center(
        child: Text('Error al cargar actividad'),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final achievements = ref.watch(userAchievementsProvider);

    return achievements.when(
      data: (achievementList) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: achievementList.length,
          itemBuilder: (context, index) {
            final achievement = achievementList[index];
            return _AchievementCard(achievement: achievement);
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (_, __) => const Center(
        child: Text('Error al cargar logros'),
      ),
    );
  }

  Widget _buildContentTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Guardados'),
              Tab(text: 'Destacados'),
              Tab(text: 'Notas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSavedContent(),
                _buildHighlights(),
                _buildNotes(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedContent() {
    final savedItems = ref.watch(userSavedContentProvider);

    return savedItems.when(
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState(
            icon: Icons.bookmark_border,
            message: 'No tienes contenido guardado',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _SavedItemCard(item: item);
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (_, __) => _buildEmptyState(
        icon: Icons.error_outline,
        message: 'Error al cargar contenido',
      ),
    );
  }

  Widget _buildHighlights() {
    final highlights = ref.watch(userHighlightsProvider);

    return highlights.when(
      data: (highlightsList) {
        if (highlightsList.isEmpty) {
          return _buildEmptyState(
            icon: Icons.highlight_off,
            message: 'No tienes versículos destacados',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: highlightsList.length,
          itemBuilder: (context, index) {
            final highlight = highlightsList[index];
            return _HighlightCard(highlight: highlight);
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (_, __) => _buildEmptyState(
        icon: Icons.error_outline,
        message: 'Error al cargar destacados',
      ),
    );
  }

  Widget _buildNotes() {
    final notes = ref.watch(userNotesProvider);

    return notes.when(
      data: (notesList) {
        if (notesList.isEmpty) {
          return _buildEmptyState(
            icon: Icons.note_alt_outlined,
            message: 'No tienes notas',
            actionLabel: 'Crear nota',
            onAction: _createNewNote,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notesList.length,
          itemBuilder: (context, index) {
            final note = notesList[index];
            return _NoteCard(note: note);
          },
        );
      },
      loading: () => const Center(child: LoadingIndicator()),
      error: (_, __) => _buildEmptyState(
        icon: Icons.error_outline,
        message: 'Error al cargar notas',
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    String? content,
    List<_InfoItem>? items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (content != null)
            Text(
              content,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          if (items != null)
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${item.label}:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditingProfile = !_isEditingProfile;
    });
  }

  void _changeProfilePicture() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cambiar foto de perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        _uploadProfilePicture(File(image.path));
      }
    }
  }

  void _uploadProfilePicture(File image) {
    // Implement upload
    ref.read(userProfileProvider.notifier).updateAvatar(image);
  }

  void _removeProfilePicture() {
    ref.read(userProfileProvider.notifier).removeAvatar();
  }

  void _saveProfile() {
    ref.read(userProfileProvider.notifier).updateProfile(
          displayName: _displayNameController.text,
          bio: _bioController.text,
          phone: _phoneController.text,
          location: _locationController.text,
          website: _websiteController.text,
        );
    _toggleEditMode();
  }

  void _createNewNote() {
    context.push(Routes.newNote);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}

// Supporting Widgets
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.gold,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _ActivityCard extends StatelessWidget {
  final dynamic activity;

  const _ActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
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
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatActivityTime(activity.timestamp),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'bible_reading':
        return Icons.menu_book;
      case 'video_watched':
        return Icons.play_circle;
      case 'course_completed':
        return Icons.school;
      case 'achievement':
        return Icons.emoji_events;
      default:
        return Icons.timeline;
    }
  }

  String _formatActivityTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} min';
    } else {
      return 'Ahora';
    }
  }
}

class _AchievementCard extends StatelessWidget {
  final dynamic achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            achievement.icon,
            size: 40,
            color: isUnlocked ? AppColors.gold : AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isUnlocked) ...[
            const SizedBox(height: 4),
            Text(
              achievement.date,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SavedItemCard extends StatelessWidget {
  final dynamic item;

  const _SavedItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getItemIcon(item.type),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  IconData _getItemIcon(String type) {
    switch (type) {
      case 'verse':
        return Icons.menu_book;
      case 'video':
        return Icons.play_circle;
      case 'course':
        return Icons.school;
      case 'article':
        return Icons.article;
      default:
        return Icons.bookmark;
    }
  }
}

class _HighlightCard extends StatelessWidget {
  final dynamic highlight;

  const _HighlightCard({required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.left(
          color: Color(highlight.color),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            highlight.text,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                highlight.reference,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                highlight.date,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final dynamic note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                note.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Edit note
                },
                icon: Icon(
                  Icons.edit,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.content,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (note.tags.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: note.tags.take(3).map<Widget>((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              Text(
                note.date,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// User Stats Model
class UserStats {
  final int bibleStreak;
  final int coursesCompleted;
  final int videosWatched;
  final Duration totalReadingTime;

  UserStats({
    required this.bibleStreak,
    required this.coursesCompleted,
    required this.videosWatched,
    required this.totalReadingTime,
  });
}