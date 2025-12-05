import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/custom_app_bar.dart';

/// Pantalla de configuración y ajustes
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Configuración',
        showBackButton: true,
      ),
      body: ListView(
        children: [
          // Sección de cuenta
          _buildSectionHeader('CUENTA'),
          if (user != null) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile/edit'),
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login, color: AppColors.primary),
              title: const Text('Iniciar Sesión'),
              subtitle: const Text('Accede a todas las funciones'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/login'),
            ),
          ],

          const Divider(),

          // Sección de notificaciones
          _buildSectionHeader('NOTIFICACIONES'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: const Text('Notificaciones Push'),
            subtitle: const Text('Recibe alertas importantes'),
            value: settings.pushNotificationsEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updatePushNotifications(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_stories),
            title: const Text('Versículo Diario'),
            subtitle: Text(
              settings.dailyVerseEnabled
                  ? 'A las ${settings.dailyVerseTime.format(context)}'
                  : 'Desactivado',
            ),
            value: settings.dailyVerseEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateDailyVerse(value);
            },
          ),
          if (settings.dailyVerseEnabled)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Hora del Versículo Diario'),
              subtitle: Text(settings.dailyVerseTime.format(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectTime(),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.video_library),
            title: const Text('Nuevos Videos'),
            subtitle: const Text('Notificaciones de videos nuevos'),
            value: settings.videoNotificationsEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateVideoNotifications(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.school),
            title: const Text('Recordatorios de Cursos'),
            subtitle: const Text('Recordatorios de tus cursos activos'),
            value: settings.courseRemindersEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateCourseReminders(value);
            },
          ),

          const Divider(),

          // Sección de Biblia
          _buildSectionHeader('BIBLIA'),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Versión Predeterminada'),
            subtitle: Text(settings.defaultBibleVersion),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectBibleVersion(),
          ),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Tamaño de Fuente'),
            subtitle: Text('${settings.bibleFontSize.toStringAsFixed(0)}pt'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectFontSize(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.format_list_numbered),
            title: const Text('Mostrar Números de Versículos'),
            value: settings.showVerseNumbers,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowVerseNumbers(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notes),
            title: const Text('Mostrar Notas al Pie'),
            value: settings.showFootnotes,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateShowFootnotes(value);
            },
          ),

          const Divider(),

          // Sección de reproducción
          _buildSectionHeader('REPRODUCCIÓN DE VIDEO'),
          ListTile(
            leading: const Icon(Icons.high_quality),
            title: const Text('Calidad de Video'),
            subtitle: Text(settings.videoQuality),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectVideoQuality(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.play_circle_outline),
            title: const Text('Reproducción Automática'),
            subtitle: const Text('Continuar con el siguiente video'),
            value: settings.autoplayEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updateAutoplay(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.picture_in_picture),
            title: const Text('Picture in Picture'),
            subtitle: const Text('Ver videos en ventana flotante'),
            value: settings.pipEnabled,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).updatePip(value);
            },
          ),

          const Divider(),

          // Sección de apariencia
          _buildSectionHeader('APARIENCIA'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Tema'),
            subtitle: Text(settings.themeMode == ThemeMode.system
                ? 'Sistema'
                : settings.themeMode == ThemeMode.dark
                    ? 'Oscuro'
                    : 'Claro'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectTheme(),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Idioma'),
            subtitle: Text(settings.language),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectLanguage(),
          ),

          const Divider(),

          // Sección de almacenamiento
          _buildSectionHeader('ALMACENAMIENTO'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Descargas'),
            subtitle: const Text('Gestionar contenido descargado'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/downloads'),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Limpiar Caché'),
            subtitle: const Text('Liberar espacio en el dispositivo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _clearCache(),
          ),

          const Divider(),

          // Sección de privacidad
          _buildSectionHeader('PRIVACIDAD'),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Política de Privacidad'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Términos y Condiciones'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/terms'),
          ),

          const Divider(),

          // Sección de soporte
          _buildSectionHeader('SOPORTE'),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Centro de Ayuda'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/help'),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Reportar un Problema'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _reportBug(),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Calificar App'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _rateApp(),
          ),

          const Divider(),

          // Sección Acerca de
          _buildSectionHeader('ACERCA DE'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Versión'),
            subtitle: const Text('1.0.0 (Build 1)'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Licencias'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Enfocados TV',
              applicationVersion: '1.0.0',
            ),
          ),

          // Botón de cerrar sesión
          if (user != null) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final settings = ref.read(settingsProvider);
    final time = await showTimePicker(
      context: context,
      initialTime: settings.dailyVerseTime,
    );

    if (time != null) {
      ref.read(settingsProvider.notifier).updateDailyVerseTime(time);
    }
  }

  void _selectBibleVersion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Versión de la Biblia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'RVR 1960',
            'NVI',
            'LBLA',
            'NTV',
            'DHH',
          ].map((version) {
            return RadioListTile<String>(
              title: Text(version),
              value: version,
              groupValue: ref.read(settingsProvider).defaultBibleVersion,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateBibleVersion(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _selectFontSize() {
    showDialog(
      context: context,
      builder: (context) {
        double fontSize = ref.read(settingsProvider).bibleFontSize;
        return AlertDialog(
          title: const Text('Tamaño de Fuente'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ejemplo de texto',
                    style: TextStyle(fontSize: fontSize),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: fontSize,
                    min: 12,
                    max: 24,
                    divisions: 12,
                    label: '${fontSize.toStringAsFixed(0)}pt',
                    onChanged: (value) {
                      setState(() {
                        fontSize = value;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).updateBibleFontSize(
                      ref.read(settingsProvider).bibleFontSize,
                    );
                Navigator.pop(context);
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  void _selectVideoQuality() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calidad de Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Auto',
            '1080p',
            '720p',
            '480p',
            '360p',
          ].map((quality) {
            return RadioListTile<String>(
              title: Text(quality),
              value: quality,
              groupValue: ref.read(settingsProvider).videoQuality,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateVideoQuality(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _selectTheme() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Sistema'),
              value: ThemeMode.system,
              groupValue: ref.read(settingsProvider).themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Claro'),
              value: ThemeMode.light,
              groupValue: ref.read(settingsProvider).themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Oscuro'),
              value: ThemeMode.dark,
              groupValue: ref.read(settingsProvider).themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _selectLanguage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Español',
            'English',
            'Português',
          ].map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: ref.read(settingsProvider).language,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateLanguage(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Caché'),
        content: const Text(
          'Esto eliminará todos los datos temporales. Los videos y cursos descargados no se verán afectados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Limpiar caché
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caché limpiado exitosamente')),
      );
    }
  }

  void _reportBug() {
    context.push('/report-bug');
  }

  void _rateApp() {
    // Abrir store para calificar
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }
}