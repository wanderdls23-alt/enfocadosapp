import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/prayer_request_model.dart';
import '../../../data/models/testimony_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

/// Pantalla principal de la comunidad
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Comunidad',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'MURO DE ORACIÓN'),
            Tab(text: 'TESTIMONIOS'),
            Tab(text: 'EVENTOS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PrayerWallTab(user: user),
          _TestimoniesTab(user: user),
          _EventsTab(),
        ],
      ),
      floatingActionButton: user != null
          ? FloatingActionButton(
              onPressed: () => _showCreateDialog(),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showSearchDialog() {
    showSearch(
      context: context,
      delegate: _CommunitySearchDelegate(ref),
    );
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.prayer_times, color: AppColors.primary),
              title: const Text('Petición de Oración'),
              subtitle: const Text('Comparte tu necesidad de oración'),
              onTap: () {
                Navigator.pop(context);
                context.push('/community/prayer/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: AppColors.gold),
              title: const Text('Testimonio'),
              subtitle: const Text('Comparte lo que Dios ha hecho en tu vida'),
              onTap: () {
                Navigator.pop(context);
                context.push('/community/testimony/create');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event, color: Colors.blue),
              title: const Text('Evento'),
              subtitle: const Text('Crea un evento cristiano'),
              onTap: () {
                Navigator.pop(context);
                context.push('/community/event/create');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Tab del Muro de Oración
class _PrayerWallTab extends ConsumerWidget {
  final dynamic user;

  const _PrayerWallTab({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerRequests = ref.watch(prayerRequestsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(prayerRequestsProvider);
      },
      child: prayerRequests.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.prayer_times,
              title: 'No hay peticiones de oración',
              subtitle: 'Sé el primero en compartir una petición',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _PrayerRequestCard(
                request: request,
                onPray: () => _handlePray(ref, request),
                onShare: () => _shareRequest(context, request),
                isOwner: user?.id == request.userId,
              );
            },
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  void _handlePray(WidgetRef ref, PrayerRequest request) {
    ref.read(communityProvider.notifier).prayForRequest(request.id);
  }

  void _shareRequest(BuildContext context, PrayerRequest request) {
    // Compartir petición
  }
}

/// Tarjeta de petición de oración
class _PrayerRequestCard extends StatelessWidget {
  final PrayerRequest request;
  final VoidCallback onPray;
  final VoidCallback onShare;
  final bool isOwner;

  const _PrayerRequestCard({
    required this.request,
    required this.onPray,
    required this.onShare,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAnonymous = request.isAnonymous;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/community/prayer/${request.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isAnonymous ? Colors.grey : AppColors.primary,
                    backgroundImage: !isAnonymous && request.userAvatar != null
                        ? NetworkImage(request.userAvatar!)
                        : null,
                    child: isAnonymous || request.userAvatar == null
                        ? Icon(
                            isAnonymous ? Icons.person_outline : Icons.person,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAnonymous ? 'Anónimo' : request.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(request.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (request.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'URGENTE',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(context, value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Título
              if (request.title != null)
                Text(
                  request.title!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              if (request.title != null) const SizedBox(height: 8),

              // Contenido
              Text(
                request.content,
                style: const TextStyle(height: 1.5),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),

              // Categoría
              if (request.category != null) ...[
                const SizedBox(height: 12),
                Chip(
                  label: Text(
                    request.category!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                ),
              ],

              const SizedBox(height: 16),

              // Acciones
              Row(
                children: [
                  // Botón de orar
                  _ActionButton(
                    icon: Icons.prayer_times,
                    label: '${request.prayerCount} orando',
                    isActive: request.hasPrayed ?? false,
                    onPressed: onPray,
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(width: 16),

                  // Comentarios
                  _ActionButton(
                    icon: Icons.comment_outlined,
                    label: '${request.commentCount}',
                    onPressed: () => context.push('/community/prayer/${request.id}'),
                  ),

                  const SizedBox(width: 16),

                  // Compartir
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'Compartir',
                    onPressed: onShare,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        context.push('/community/prayer/${request.id}/edit');
        break;
      case 'delete':
        _confirmDelete(context);
        break;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar petición'),
        content: const Text('¿Estás seguro de que quieres eliminar esta petición de oración?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Eliminar petición
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Tab de Testimonios
class _TestimoniesTab extends ConsumerWidget {
  final dynamic user;

  const _TestimoniesTab({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testimonies = ref.watch(testimoniesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(testimoniesProvider);
      },
      child: testimonies.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.favorite,
              title: 'No hay testimonios',
              subtitle: 'Sé el primero en compartir tu testimonio',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final testimony = items[index];
              return _TestimonyCard(
                testimony: testimony,
                isOwner: user?.id == testimony.userId,
              );
            },
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

/// Tarjeta de testimonio
class _TestimonyCard extends StatelessWidget {
  final Testimony testimony;
  final bool isOwner;

  const _TestimonyCard({
    required this.testimony,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/community/testimony/${testimony.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de portada si existe
            if (testimony.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    testimony.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 50),
                      );
                    },
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.gold,
                        backgroundImage: testimony.userAvatar != null
                            ? NetworkImage(testimony.userAvatar!)
                            : null,
                        child: testimony.userAvatar == null
                            ? Text(
                                testimony.userName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              testimony.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDate(testimony.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (testimony.isVerified)
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 20,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Título
                  Text(
                    testimony.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Contenido (preview)
                  Text(
                    testimony.content,
                    style: const TextStyle(height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Categoría
                  if (testimony.category != null) ...[
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(
                        testimony.category!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppColors.gold.withOpacity(0.2),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Estadísticas
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${testimony.likesCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${testimony.commentsCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${testimony.viewsCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 7) {
      return 'hace ${difference.inDays} días';
    } else if (difference.inDays < 30) {
      return 'hace ${(difference.inDays / 7).floor()} semanas';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Tab de Eventos
class _EventsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(eventsProvider);
      },
      child: events.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.event,
              title: 'No hay eventos próximos',
              subtitle: 'Los eventos aparecerán aquí',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final event = items[index];
              return _EventCard(event: event);
            },
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

/// Tarjeta de evento
class _EventCard extends StatelessWidget {
  final dynamic event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/community/event/${event.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Fecha
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${event.date.day}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _getMonthName(event.date.month),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          event.time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Asistentes
              Column(
                children: [
                  const Icon(Icons.people, size: 20),
                  Text(
                    '${event.attendeesCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
    ];
    return months[month - 1];
  }
}

/// Botón de acción
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? activeColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? (activeColor ?? AppColors.primary) : Colors.grey[600];

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Delegado de búsqueda
class _CommunitySearchDelegate extends SearchDelegate {
  final WidgetRef ref;

  _CommunitySearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Implementar búsqueda
    return const Center(
      child: Text('Resultados de búsqueda'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Sugerencias de búsqueda
    return const Center(
      child: Text('Escribe para buscar'),
    );
  }
}