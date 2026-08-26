// lib/main.dart
//
// ¿Qué hace este archivo?
// Es el punto de entrada de la aplicación Flutter.
// Se ejecuta primero cuando el usuario abre la app.
// Aquí inicializamos todos los servicios globales:
// Firebase, Hive (almacenamiento local), y configuramos
// el árbol de widgets principal con Riverpod.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';


import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';

// main() es la función que Dart ejecuta primero.
// Es async porque necesitamos esperar que Firebase inicie
// antes de mostrar cualquier pantalla.
Future<void> main() async {
  // Asegura que Flutter esté listo para usar plugins nativos
  WidgetsFlutterBinding.ensureInitialized();

  // Forzar orientación vertical (portrait) en móvil.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar Hive (base de datos local para modo offline).
  await Hive.initFlutter();

  // 1. Creamos el contenedor de Riverpod explícitamente
  final container = ProviderContainer();

  // 2. Forzamos la lectura de tu SyncProvider para que se active e inicie
  // (Asegúrate de importar aquí el archivo donde declaraste tu provider de sync)
  // Reemplaza 'syncProvider' por el nombre exacto de tu variable global del provider.


  Intl.defaultLocale = 'es_MX';

  // 3. Pasamos el contenedor inicializado usando UncontrolledProviderScope
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MROApp(),
    ),
  );
}

// MROApp es el widget raíz de la aplicación.
// ConsumerWidget le permite acceder a los providers de Riverpod.
class MROApp extends ConsumerWidget {
  const MROApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtenemos el router desde el provider (lo crearemos en el siguiente paso).
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // Título de la app (aparece en el task switcher del teléfono)
      title: 'MRO Damage System',

      // Ocultar el banner "DEBUG" en la esquina superior derecha
      debugShowCheckedModeBanner: false,

      // Tema visual de la app (lo definiremos en app_theme.dart)
      //theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Configuración de localización para español de México
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        // GlobalWidgetsLocalizations.delegate,
        // GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'MX'),
        Locale('en', 'US'),
      ],

      // Router declarativo (GoRouter maneja toda la navegación)
      routerConfig: router,
    );
  }
}
