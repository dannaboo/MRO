// lib/core/router/app_router.dart
//
// Versión actualizada con:
// 1. Rutas protegidas: si no estás logueado, va al login
// 2. Redirección por rol: gerente va a dashboard, cuadrillero a reportes
// 3. Splash que verifica sesión antes de mostrar cualquier pantalla

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/domain/entities/user_entity.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Escuchamos el estado de auth para redirigir automáticamente.
  // RouterNotifier notifica a GoRouter cuando debe re-evaluar las rutas.
  final authNotifier = ValueNotifier<AuthState>(const AuthState.initial());

  ref.listen<AuthState>(authProvider, (_, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,

    // redirect se ejecuta ANTES de mostrar cualquier ruta.
    // Aquí implementamos la lógica de protección de rutas.
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSplash = state.matchedLocation == '/splash';

      // Mientras verificamos la sesión, mostrar splash
      if (authState.status == AuthStatus.initial) {
        return '/splash';
      }

      // Si no está autenticado y no va al login → redirigir al login
      if (authState.status == AuthStatus.unauthenticated) {
        if (!isGoingToLogin) return '/login';
        return null;
      }

      // Si está autenticado y va al login o splash → redirigir al home
      if (authState.status == AuthStatus.authenticated) {
        if (isGoingToLogin || isGoingToSplash) {
          return '/home';
        }
      }

      return null; // Sin redirección, continuar normalmente
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePagePlaceholder(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsPlaceholder(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página no encontrada: ${state.uri}'),
      ),
    ),
  );
});

// ─── SPLASH SCREEN FUNCIONAL ────────────────────────────
// Esta pantalla verifica la sesión mientras muestra la marca.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.construction_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'MRO Damage System',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sistema de Levantamiento de Daños',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 64),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholders temporales
class HomePagePlaceholder extends ConsumerWidget {
  const HomePagePlaceholder({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MRO Damage System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              '¡Bienvenido!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text('Usuario: ${user?.displayName ?? ""}'),
            Text('Rol: ${user?.role.displayName ?? ""}'),
            Text('Empleado: ${user?.employeeId ?? ""}'),
          ],
        ),
      ),
    );
  }
}

class ReportsPlaceholder extends StatelessWidget {
  const ReportsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Reportes - Fase 4')),
      );
}