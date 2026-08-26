// lib/features/sync/domain/usecases/sync_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../reports/presentation/providers/report_provider.dart';

enum SyncServiceStatus { idle, syncing, error, done }

class SyncState {
  final SyncServiceStatus status;
  final int pendingCount;
  final int syncedCount;
  final String? message;
  final bool hasInternet;

  const SyncState({
    this.status = SyncServiceStatus.idle,
    this.pendingCount = 0,
    this.syncedCount = 0,
    this.message,
    this.hasInternet = true,
  });

  SyncState copyWith({
    SyncServiceStatus? status,
    int? pendingCount,
    int? syncedCount,
    String? message,
    bool? hasInternet,
  }) =>
      SyncState(
        status: status ?? this.status,
        pendingCount: pendingCount ?? this.pendingCount,
        syncedCount: syncedCount ?? this.syncedCount,
        message: message,
        hasInternet: hasInternet ?? this.hasInternet,
      );

  bool get isSyncing => status == SyncServiceStatus.syncing;
  bool get hasPending => pendingCount > 0;
}

class SyncNotifier extends Notifier<SyncState> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  SyncState build() {
    _startListening();
    ref.onDispose(() => _sub?.cancel());
    return const SyncState();
  }

  void _startListening() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.isNotEmpty &&
          results.first != ConnectivityResult.none;
      state = state.copyWith(hasInternet: online);
      if (online && state.hasPending) syncNow();
    });
    _init();
  }

  Future<void> _init() async {
    final result = await Connectivity().checkConnectivity();
   final online = !result.contains(ConnectivityResult.none);
    state = state.copyWith(hasInternet: online);
    await _countPending();
    if (online && state.hasPending) await syncNow();
  }

  Future<void> _countPending() async {
    try {
      final ds = ref.read(reportLocalDataSourceProvider);
      final pending = await ds.getPendingReports();
      state = state.copyWith(pendingCount: pending.length);
    } catch (_) {}
  }

  Future<void> syncNow() async {
    if (state.isSyncing) return;
    state = state.copyWith(
      status: SyncServiceStatus.syncing,
      message: 'Sincronizando reportes...',
    );

    final result =
        await ref.read(reportRepositoryProvider).syncPendingReports();

    result.fold(
      (f) => state = state.copyWith(
        status: SyncServiceStatus.error,
        message: f.message,
      ),
      (count) {
        state = state.copyWith(
          status: SyncServiceStatus.done,
          syncedCount: count,
          pendingCount: 0,
          message: count > 0 ? '$count reporte(s) sincronizado(s)' : null,
        );
        if (count > 0) {
          ref.read(reportsProvider.notifier).loadReports();
        }
      },
    );
  }

  void clearMessage() => state = state.copyWith(
        status: SyncServiceStatus.idle,
        message: null,
      );
}

final syncProvider =
    NotifierProvider<SyncNotifier, SyncState>(() => SyncNotifier());