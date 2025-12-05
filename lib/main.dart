import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'core/themes/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/storage_service.dart';
import 'presentation/navigation/app_router.dart';
import 'services/notification_service.dart';
import 'presentation/providers/notification_provider.dart';

// Background message handler para Firebase
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Mensaje en background: ${message.messageId}');
}

void main() async {
  // Asegurar que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación (solo portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar status bar transparente
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  try {
    // Cargar variables de entorno
    await dotenv.load(fileName: '.env');

    // Inicializar Firebase
    await Firebase.initializeApp();

    // Configurar Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Configurar Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Inicializar servicios locales
    await StorageService.initialize();

    // Ejecutar app con manejo de errores
    runApp(
      ProviderScope(
        child: EnfocadosTVApp(),
      ),
    );
  } catch (error, stackTrace) {
    print('Error al inicializar la app: $error');
    print('StackTrace: $stackTrace');

    // Mostrar pantalla de error
    runApp(
      MaterialApp(
        home: _ErrorScreen(error: error.toString()),
      ),
    );
  }
}

class EnfocadosTVApp extends ConsumerStatefulWidget {
  const EnfocadosTVApp({Key? key}) : super(key: key);

  @override
  ConsumerState<EnfocadosTVApp> createState() => _EnfocadosTVAppState();
}

class _EnfocadosTVAppState extends ConsumerState<EnfocadosTVApp>
    with WidgetsBindingObserver {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter();
    WidgetsBinding.instance.addObserver(this);
    _setupFirebaseMessaging();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Manejar cambios en el ciclo de vida de la app
    switch (state) {
      case AppLifecycleState.resumed:
        print('App resumed');
        // Refrescar datos si es necesario
        break;
      case AppLifecycleState.paused:
        print('App paused');
        // Guardar estado si es necesario
        break;
      case AppLifecycleState.detached:
        print('App detached');
        break;
      case AppLifecycleState.inactive:
        print('App inactive');
        break;
      case AppLifecycleState.hidden:
        print('App hidden');
        break;
    }
  }

  void _setupFirebaseMessaging() async {
    // Inicializar el servicio de notificaciones a través del provider
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.initialize();

    // Solicitar permisos si no se han otorgado
    await ref.read(notificationProvider.notifier).requestPermission();

    // El servicio de notificaciones maneja todo lo demás
    // (token FCM, listeners, navegación, etc.)
  }

  @override
  Widget build(BuildContext context) {
    // Observar el tema seleccionado
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      // Configuración básica
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Temas
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Localización
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // English
      ],
      locale: const Locale('es', 'ES'),

      // Router
      routerConfig: _appRouter.config(),

      // Builder para configuraciones globales
      builder: (context, child) {
        // Configurar tamaño de texto fijo (ignorar configuración del sistema)
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}

// Pantalla de error para casos críticos
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Error al iniciar la aplicación',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Reintentar
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Cerrar aplicación',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}