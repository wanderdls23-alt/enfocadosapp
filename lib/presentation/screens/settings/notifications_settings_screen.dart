import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../providers/settings_provider.dart';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends ConsumerState<NotificationsSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master Switch
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    settings.enabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: settings.enabled
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notificaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          settings.enabled
                              ? 'Recibirás notificaciones importantes'
                              : 'No recibirás ninguna notificación',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.enabled,
                    onChanged: (value) {
                      ref.read(notificationSettingsProvider.notifier)
                          .toggleEnabled(value);
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            if (settings.enabled) ...[
              const SizedBox(height: 24),

              // Daily Verse Section
              _buildSectionTitle('VERSÍCULO DIARIO'),
              _buildNotificationCard([
                _NotificationTile(
                  icon: Icons.menu_book,
                  title: 'Versículo del día',
                  subtitle: 'Recibe un versículo cada mañana',
                  value: settings.dailyVerse,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .toggleDailyVerse(value);
                  },
                ),
                if (settings.dailyVerse)
                  _TimePicker(
                    title: 'Hora del versículo',
                    time: settings.dailyVerseTime,
                    onTimeChanged: (time) {
                      ref.read(notificationSettingsProvider.notifier)
                          .updateDailyVerseTime(time);
                    },
                  ),
              ]),

              const SizedBox(height: 24),

              // Prayer Reminders Section
              _buildSectionTitle('RECORDATORIOS DE ORACIÓN'),
              _buildNotificationCard([
                _NotificationTile(
                  icon: Icons.alarm,
                  title: 'Recordatorios de oración',
                  subtitle: 'Notificaciones para orar',
                  value: settings.prayerReminders,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .togglePrayerReminders(value);
                  },
                ),
                if (settings.prayerReminders) ...[
                  _FrequencySelector(
                    frequency: settings.prayerFrequency,
                    onChanged: (frequency) {
                      ref.read(notificationSettingsProvider.notifier)
                          .updatePrayerFrequency(frequency);
                    },
                  ),
                  _buildPrayerTimes(),
                ],
              ]),

              const SizedBox(height: 24),

              // Videos Section
              _buildSectionTitle('VIDEOS Y TRANSMISIONES'),
              _buildNotificationCard([
                _NotificationTile(
                  icon: Icons.video_library,
                  title: 'Nuevos videos',
                  subtitle: 'Cuando se publique contenido nuevo',
                  value: settings.newVideos,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .toggleNewVideos(value);
                  },
                ),
                _NotificationTile(
                  icon: Icons.live_tv,
                  title: 'Transmisiones en vivo',
                  subtitle: 'Alertas cuando comience un en vivo',
                  value: settings.liveStreams,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .toggleLiveStreams(value);
                  },
                  showDivider: false,
                ),
              ]),

              const SizedBox(height: 24),

              // Academy Section
              _buildSectionTitle('ACADEMIA'),
              _buildNotificationCard([
                _NotificationTile(
                  icon: Icons.school,
                  title: 'Nuevos cursos',
                  subtitle: 'Cursos disponibles en la academia',
                  value: settings.newCourses,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .toggleNewCourses(value);
                  },
                ),
                _NotificationTile(
                  icon: Icons.assignment,
                  title: 'Tareas pendientes',
                  subtitle: 'Recordatorios de tareas y evaluaciones',
                  value: settings.courseTasks,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .toggleCourseTasks(value);
                  },
                ),
                _NotificationTile(
                  icon: Icons.emoji_events,
                  title: 'Certificados obtenidos',
                  subtitle: 'Cuando completes un curso',
                  value: settings.certificates,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .toggleCertificates(value);
                  },
                  showDivider: false,
                ),
              ]),

              const SizedBox(height: 24),

              // Community Section
              _buildSectionTitle('COMUNIDAD'),
              _buildNotificationCard([
                _NotificationTile(
                  icon: Icons.event,
                  title: 'Eventos',
                  subtitle: 'Próximos eventos y actividades',
                  value: settings.events,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .toggleEvents(value);
                  },
                ),
                _NotificationTile(
                  icon: Icons.favorite,
                  title: 'Muro de oración',
                  subtitle: 'Oraciones por tus peticiones',
                  value: settings.prayerWall,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .togglePrayerWall(value);
                  },
                ),
                _NotificationTile(
                  icon: Icons.comment,
                  title: 'Comentarios',
                  subtitle: 'Respuestas a tus comentarios',
                  value: settings.comments,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .toggleComments(value);
                  },
                  showDivider: false,
                ),
              ]),

              const SizedBox(height: 24),

              // Other Notifications
              _buildSectionTitle('OTRAS NOTIFICACIONES'),
              _buildNotificationCard([
                _NotificationTile(
                  icon: Icons.system_update,
                  title: 'Actualizaciones',
                  subtitle: 'Nuevas funciones y mejoras',
                  value: settings.appUpdates,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .toggleAppUpdates(value);
                  },
                ),
                _NotificationTile(
                  icon: Icons.local_offer,
                  title: 'Ofertas especiales',
                  subtitle: 'Promociones y descuentos',
                  value: settings.promotions,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .togglePromotions(value);
                  },
                  showDivider: false,
                ),
              ]),

              const SizedBox(height: 24),

              // Sound & Vibration
              _buildSectionTitle('SONIDO Y VIBRACIÓN'),
              _buildNotificationCard([
                _NotificationTile(
                  icon: Icons.volume_up,
                  title: 'Sonido',
                  subtitle: 'Reproducir sonido con notificaciones',
                  value: settings.sound,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .toggleSound(value);
                  },
                ),
                _NotificationTile(
                  icon: Icons.vibration,
                  title: 'Vibración',
                  subtitle: 'Vibrar con notificaciones',
                  value: settings.vibration,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .toggleVibration(value);
                  },
                  showDivider: false,
                ),
              ]),

              const SizedBox(height: 24),

              // Quiet Hours
              _buildSectionTitle('HORARIO SILENCIOSO'),
              _buildNotificationCard([
                _NotificationTile(
                  icon: Icons.do_not_disturb_on,
                  title: 'No molestar',
                  subtitle: settings.quietHours
                      ? '${_formatTime(settings.quietStart)} - ${_formatTime(settings.quietEnd)}'
                      : 'Pausar notificaciones temporalmente',
                  value: settings.quietHours,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier)
                        .toggleQuietHours(value);
                  },
                ),
                if (settings.quietHours) ...[
                  _TimeRangePicker(
                    startTime: settings.quietStart,
                    endTime: settings.quietEnd,
                    onStartChanged: (time) {
                      ref.read(notificationSettingsProvider.notifier)
                          .updateQuietStart(time);
                    },
                    onEndChanged: (time) {
                      ref.read(notificationSettingsProvider.notifier)
                          .updateQuietEnd(time);
                    },
                  ),
                ],
              ]),

              const SizedBox(height: 40),
            ] else
              // Disabled state message
              Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_paused,
                      size: 64,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Notificaciones desactivadas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Activa las notificaciones para recibir actualizaciones importantes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(List<Widget> tiles) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(children: tiles),
    );
  }

  Widget _buildPrayerTimes() {
    final settings = ref.watch(notificationSettingsProvider);

    return Column(
      children: settings.prayerTimes.map((time) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Icon(
                Icons.access_time,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                _formatTime(time),
                style: const TextStyle(fontSize: 14),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  ref.read(notificationSettingsProvider.notifier)
                      .removePrayerTime(time);
                },
              ),
            ],
          ),
        );
      }).toList()
        ..add(
          TextButton.icon(
            onPressed: _showAddPrayerTimeDialog,
            icon: Icon(Icons.add, color: AppColors.primary),
            label: Text(
              'Agregar horario',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ),
    );
  }

  void _showAddPrayerTimeDialog() {
    showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    ).then((time) {
      if (time != null) {
        ref.read(notificationSettingsProvider.notifier)
            .addPrayerTime(time);
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: value ? AppColors.primary : AppColors.textSecondary,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: value ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: AppColors.border,
          ),
      ],
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String title;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const _TimePicker({
    required this.title,
    required this.time,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: OutlinedButton(
        onPressed: () async {
          final newTime = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (newTime != null) {
            onTimeChanged(newTime);
          }
        },
        child: Text(_formatTime(time)),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class _TimeRangePicker extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;

  const _TimeRangePicker({
    required this.startTime,
    required this.endTime,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 16, bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desde',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                    );
                    if (time != null) {
                      onStartChanged(time);
                    }
                  },
                  child: Text(_formatTime(startTime)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hasta',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (time != null) {
                      onEndChanged(time);
                    }
                  },
                  child: Text(_formatTime(endTime)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}

class _FrequencySelector extends StatelessWidget {
  final String frequency;
  final ValueChanged<String> onChanged;

  const _FrequencySelector({
    required this.frequency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = {
      'daily': 'Diario',
      '3_times': '3 veces al día',
      'custom': 'Personalizado',
    };

    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frecuencia',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: options.entries.map((entry) {
              final isSelected = frequency == entry.key;
              return ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onChanged(entry.key);
                  }
                },
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}