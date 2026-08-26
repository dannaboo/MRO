// lib/core/router/app_router.dart
// Versión completa y correcta.
// Todas las clases están al nivel superior del archivo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/concepts/presentation/pages/concepts_page.dart';
import '../../features/dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/reports/presentation/pages/report_detail_page.dart';
import '../../features/reports/presentation/pages/report_form_page.dart';
import '../../features/reports/presentation/pages/reports_list_page.dart';
import '../../features/sync/presentation/widgets/sync_status_banner.dart';
import '../../core/theme/app_colors.dart';


// ─── PROVIDER DEL ROUTER ─────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState>(const AuthState.initial());

  ref.listen<AuthState>(authProvider, (_, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      if (auth.status == AuthStatus.initial) return '/splash';

      if (auth.status == AuthStatus.unauthenticated) {
        if (loc != '/login') return '/login';
        return null;
      }

      if (auth.status == AuthStatus.authenticated) {
        if (loc == '/login' || loc == '/splash') {
          final user = ref.read(currentUserProvider);
          if (user?.role.canViewDashboard == true) return '/admin';
          return '/reports';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/reports',
            builder: (_, __) => const ReportsListPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const ReportFormPage(),
              ),
              GoRoute(
                path: ':reportId',
                builder: (_, state) => ReportDetailPage(
                  reportId: state.pathParameters['reportId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/concepts',
            builder: (_, __) => const ConceptsPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfilePage(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
});

// ─── MAIN SHELL ──────────────────────────────────────────

class MainShell extends ConsumerWidget {
  final Widget child;
  final String location;

  const MainShell({
    super.key,
    required this.child,
    required this.location,
  });

  int _tabIndex(String loc, bool showAdmin) {
    if (showAdmin) {
      if (loc.startsWith('/admin'))    return 0;
      if (loc.startsWith('/reports'))  return 1;
      if (loc.startsWith('/concepts')) return 2;
      if (loc.startsWith('/profile'))  return 3;
      return 0;
    } else {
      if (loc.startsWith('/concepts')) return 1;
      if (loc.startsWith('/profile'))  return 2;
      return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final showAdmin = user?.role.canViewDashboard ?? false;
    final currentIndex = _tabIndex(location, showAdmin);

    return Scaffold(
      body: Column(
        children: [
          const SyncStatusBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (showAdmin) {
            switch (index) {
              case 0: context.go('/admin');    break;
              case 1: context.go('/reports');  break;
              case 2: context.go('/concepts'); break;
              case 3: context.go('/profile');  break;
            }
          } else {
            switch (index) {
              case 0: context.go('/reports');  break;
              case 1: context.go('/concepts'); break;
              case 2: context.go('/profile');  break;
            }
          }
        },
        destinations: [
          if (showAdmin)
            const NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Admin',
            ),
          const NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Reportes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Catálogo',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ─── SPLASH SCREEN ───────────────────────────────────────

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: Color(0xFF1565C0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              color: Colors.white,
              size: 72,
            ),
            SizedBox(height: 24),
            Text(
              'MRO Damage System',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sistema de Levantamiento de Daños',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            SizedBox(height: 64),
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROFILE PAGE ────────────────────────────────────────

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text(
                    '¿Estás seguro de que quieres salir?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ─── AVATAR ────────────────────────────
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Center(
                  child: Text(
                    user.role.displayName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // ─── DATOS DEL USUARIO ─────────────────
                _InfoTile(
                  icon: Icons.email_outlined,
                  label: 'Correo',
                  value: user.email,
                ),
                _InfoTile(
                  icon: Icons.badge_outlined,
                  label: 'No. de Empleado',
                  value: user.employeeId,
                ),
                if (user.phone != null)
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: user.phone!,
                  ),
                _InfoTile(
                  icon: Icons.security_outlined,
                  label: 'Rol',
                  value: user.role.displayName,
                ),
                _InfoTile(
                  icon: Icons.circle,
                  label: 'Estado',
                  value: user.isActive ? 'Activo' : 'Inactivo',
                  valueColor: user.isActive
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(height: 32),

                // ─── PERMISOS DEL ROL ──────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permisos de tu rol',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _PermissionRow(
                        label: 'Crear reportes',
                        hasPermission: user.role.canCreateReports,
                      ),
                      _PermissionRow(
                        label: 'Revisar reportes',
                        hasPermission: user.role.canReviewReports,
                      ),
                      _PermissionRow(
                        label: 'Aprobar reportes',
                        hasPermission: user.role.canApproveReports,
                      ),
                      _PermissionRow(
                        label: 'Administrar catálogo',
                        hasPermission: user.role.canManageConcepts,
                      ),
                      _PermissionRow(
                        label: 'Administrar usuarios',
                        hasPermission: user.role.canManageUsers,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── WIDGETS AUXILIARES DE PROFILE ───────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final String label;
  final bool hasPermission;

  const _PermissionRow({
    required this.label,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            hasPermission
                ? Icons.check_circle
                : Icons.cancel_outlined,
            size: 18,
            color: hasPermission
                ? AppColors.success
                : AppColors.textDisabled,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: hasPermission
                  ? AppColors.textPrimary
                  : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}