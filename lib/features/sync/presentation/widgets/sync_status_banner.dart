// lib/features/sync/presentation/widgets/sync_status_banner.dart
//
// Banner que aparece en la parte superior cuando:
// - No hay internet (naranja)
// - Hay sincronización en progreso (azul + spinner)
// - Sincronización completada (verde, desaparece en 3s)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/usecases/sync_service.dart';

class SyncStatusBanner extends ConsumerStatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  ConsumerState<SyncStatusBanner> createState() =>
      _SyncStatusBannerState();
}

class _SyncStatusBannerState extends ConsumerState<SyncStatusBanner> {
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncProvider);

    // Auto-ocultar el banner de "sincronizado" después de 3s
    if (syncState.status == SyncServiceStatus.done &&
        syncState.message != null) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          ref.read(syncProvider.notifier).clearMessage();
        }
      });
    }

    // No mostrar nada si hay internet y no hay actividad
    if (syncState.hasInternet &&
        syncState.status == SyncServiceStatus.idle &&
        !syncState.hasPending) {
      return const SizedBox.shrink();
    }

    // No mostrar si está done y ya se limpió el mensaje
    if (syncState.status == SyncServiceStatus.done &&
        syncState.message == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: _bannerColor(syncState),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Icono / spinner
            if (syncState.isSyncing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                _bannerIcon(syncState),
                size: 16,
                color: Colors.white,
              ),
            const SizedBox(width: 10),
            // Mensaje
            Expanded(
              child: Text(
                _bannerText(syncState),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Botón de sincronizar manualmente
            if (!syncState.hasInternet && syncState.hasPending)
              Text(
                '${syncState.pendingCount} pendiente(s)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              )
            else if (syncState.hasPending && !syncState.isSyncing)
              TextButton(
                onPressed: () =>
                    ref.read(syncProvider.notifier).syncNow(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Sincronizar',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _bannerColor(SyncState s) {
    if (!s.hasInternet) return AppColors.syncPending;
    if (s.isSyncing) return AppColors.primary;
    if (s.status == SyncServiceStatus.done) return AppColors.success;
    if (s.status == SyncServiceStatus.error) return AppColors.error;
    if (s.hasPending) return AppColors.syncPending;
    return AppColors.primary;
  }

  IconData _bannerIcon(SyncState s) {
    if (!s.hasInternet) return Icons.cloud_off;
    if (s.status == SyncServiceStatus.done) return Icons.cloud_done;
    if (s.status == SyncServiceStatus.error) return Icons.error_outline;
    return Icons.cloud_upload_outlined;
  }

  String _bannerText(SyncState s) {
    if (!s.hasInternet) {
      return s.hasPending
          ? 'Sin internet · ${s.pendingCount} reporte(s) guardados localmente'
          : 'Sin conexión a internet · Modo offline activo';
    }
    if (s.isSyncing) return s.message ?? 'Sincronizando...';
    if (s.status == SyncServiceStatus.done && s.message != null) {
      return '✓ ${s.message}';
    }
    if (s.status == SyncServiceStatus.error) {
      return s.message ?? 'Error al sincronizar';
    }
    if (s.hasPending) {
      return '${s.pendingCount} reporte(s) pendiente(s) de sincronizar';
    }
    return '';
  }
}
