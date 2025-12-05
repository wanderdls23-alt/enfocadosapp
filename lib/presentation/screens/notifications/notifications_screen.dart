import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/themes/app_colors.dart';
import '../../../core/constants/route_names.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NotificationCategory _selectedCategory = NotificationCategory.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Marcar todas como leídas cuando se abre la pantalla
    Future.microtask(() {
      ref.read(notificationProvider.notifier).markAllAsRead();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('Borrar todas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Configuración'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          tabs: const [
            Tab(text: 'RECIENTES'),
            Tab(text: 'ANTERIORES'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtros de categoría
          Container(
            height: 50,
            color: Colors.grey[100],
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: NotificationCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Lista de notificaciones
          Expanded(
            child: notificationState.isLoading
                ? const LoadingIndicator()
                : notificationState.error != null
                    ? CustomErrorWidget(
                        message: notificationState.error!,
                        onRetry: () {
                          ref.read(notificationProvider.notifier).loadNotifications();
                        },
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNotificationList(true),
                          _buildNotificationList(false),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(bool isRecent) {
    final notifications = ref.watch(notificationProvider).notifications;

    // Filtrar por categoría
    final filteredNotifications = _selectedCategory == NotificationCategory.all
        ? notifications
        : notifications.where((n) => n.notificationCategory == _selectedCategory).toList();

    // Filtrar por tiempo (recientes = últimas 24 horas)
    final now = DateTime.now();
    final recentCutoff = now.subtract(const Duration(hours: 24));

    final displayNotifications = filteredNotifications.where((n) {
      if (isRecent) {
        return n.timestamp.isAfter(recentCutoff);
      } else {
        return n.timestamp.isBefore(recentCutoff);
      }
    }).toList();

    if (displayNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay notificaciones',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayNotifications.length,
      itemBuilder: (context, index) {
        final notification = displayNotifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        ref.read(notificationProvider.notifier).clearNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notificación eliminada'),
            action: SnackBarAction(
              label: 'DESHACER',
              onPressed: () {
                // Implementar deshacer
              },
            ),
          ),
        );
      },
      child: Card(
        elevation: notification.isRead ? 0 : 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: notification.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.notificationType).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.notificationType),
                    color: _getNotificationColor(notification.notificationType),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            notification.formattedTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (notification.imageUrl != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: notification.imageUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Indicador de no leído
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8, top: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.dailyVerse:
        return Icons.menu_book;
      case NotificationType.newVideo:
        return Icons.play_circle_outline;
      case NotificationType.newCourse:
        return Icons.school;
      case NotificationType.prayerReminder:
        return Icons.alarm;
      case NotificationType.eventReminder:
        return Icons.event;
      case NotificationType.liveStream:
        return Icons.live_tv;
      case NotificationType.courseUpdate:
        return Icons.update;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.communityUpdate:
        return Icons.people;
      case NotificationType.system:
        return Icons.info_outline;
      case NotificationType.general:
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.dailyVerse:
      case NotificationType.prayerReminder:
        return AppColors.primary;
      case NotificationType.newVideo:
      case NotificationType.liveStream:
        return Colors.red;
      case NotificationType.newCourse:
      case NotificationType.courseUpdate:
        return Colors.blue;
      case NotificationType.achievement:
        return AppColors.gold;
      case NotificationType.eventReminder:
      case NotificationType.communityUpdate:
        return Colors.green;
      case NotificationType.system:
      case NotificationType.general:
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Marcar como leída
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }

    // Navegar según el tipo
    switch (notification.notificationType) {
      case NotificationType.dailyVerse:
        context.push(Routes.dailyVerse);
        break;
      case NotificationType.newVideo:
        if (notification.data?['videoId'] != null) {
          context.push('${Routes.videos}/player/${notification.data!['videoId']}');
        } else {
          context.go(Routes.videos);
        }
        break;
      case NotificationType.newCourse:
      case NotificationType.courseUpdate:
        if (notification.data?['courseId'] != null) {
          context.push('${Routes.academy}/course/${notification.data!['courseId']}');
        } else {
          context.go(Routes.academy);
        }
        break;
      case NotificationType.liveStream:
        context.push(Routes.live);
        break;
      case NotificationType.eventReminder:
        if (notification.data?['eventId'] != null) {
          context.push('${Routes.events}/${notification.data!['eventId']}');
        } else {
          context.push(Routes.events);
        }
        break;
      case NotificationType.achievement:
        context.push(Routes.achievements);
        break;
      case NotificationType.communityUpdate:
        context.go(Routes.community);
        break;
      case NotificationType.prayerReminder:
        context.push(Routes.prayerWall);
        break;
      default:
        // No hacer nada o mostrar detalles
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            if (notification.imageUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: notification.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Recibido: ${notification.formattedTime}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (notification.actionUrl != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Abrir URL de acción
              },
              child: const Text('Ir'),
            ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_all':
        _confirmClearAll();
        break;
      case 'settings':
        context.push(Routes.notificationSettings);
        break;
    }
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar todas las notificaciones'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar todas las notificaciones? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).clearAllNotifications();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todas las notificaciones han sido eliminadas'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Borrar todas'),
          ),
        ],
      ),
    );
  }
}