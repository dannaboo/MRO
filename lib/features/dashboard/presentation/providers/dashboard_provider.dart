// lib/features/dashboard/presentation/providers/dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reports/domain/entities/report_entity.dart';
import '../../../reports/presentation/providers/report_provider.dart';

class DashboardStats {
  final int total;
  final int drafts;
  final int submitted;
  final int reviewing;
  final int approved;
  final int rejected;
  final double totalAmount;

  const DashboardStats({
    this.total = 0,
    this.drafts = 0,
    this.submitted = 0,
    this.reviewing = 0,
    this.approved = 0,
    this.rejected = 0,
    this.totalAmount = 0,
  });
}

class DashboardState {
  final List<DamageReportEntity> allReports;
  final List<DamageReportEntity> pendingReports;
  final DashboardStats stats;
  final bool isLoading;
  final String? error;
  final ReportStatus? filterStatus;

  const DashboardState({
    this.allReports = const [],
    this.pendingReports = const [],
    this.stats = const DashboardStats(),
    this.isLoading = false,
    this.error,
    this.filterStatus,
  });

  DashboardState copyWith({
    List<DamageReportEntity>? allReports,
    List<DamageReportEntity>? pendingReports,
    DashboardStats? stats,
    bool? isLoading,
    String? error,
    Object? filterStatus = _kUnset,
  }) =>
      DashboardState(
        allReports: allReports ?? this.allReports,
        pendingReports: pendingReports ?? this.pendingReports,
        stats: stats ?? this.stats,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        filterStatus: filterStatus == _kUnset
            ? this.filterStatus
            : filterStatus as ReportStatus?,
      );
}

const _kUnset = Object();

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    Future.microtask(() => _load());
    return const DashboardState(isLoading: true);
  }

  Future<void> _load({ReportStatus? filterStatus}) async {
    state = state.copyWith(isLoading: true, error: null);

    // Todos los reportes (admin ve todos)
    final allResult = await ref
        .read(reportRepositoryProvider)
        .getReports(status: filterStatus, limit: 100);

    // Pendientes de revisión específicamente
    final pendingResult = await ref
        .read(reportRepositoryProvider)
        .getReports(status: ReportStatus.submitted, limit: 50);

    allResult.fold(
      (f) => state = state.copyWith(
          isLoading: false, error: f.message),
      (all) {
        
final pending = pendingResult.fold((_) => <DamageReportEntity>[], (r) => r);


        // Calcular estadísticas
        final stats = DashboardStats(
          total: all.length,
          drafts: all
              .where((r) => r.status == ReportStatus.draft)
              .length,
          submitted: all
              .where(
                  (r) => r.status == ReportStatus.submitted)
              .length,
          reviewing: all
              .where(
                  (r) => r.status == ReportStatus.reviewing)
              .length,
          approved: all
              .where(
                  (r) => r.status == ReportStatus.approved)
              .length,
          rejected: all
              .where(
                  (r) => r.status == ReportStatus.rejected)
              .length,
          totalAmount:
              all.fold(0, (sum, r) => sum + r.total),
        );

        state = state.copyWith(
          isLoading: false,
          allReports: all,
          pendingReports: pending,
          stats: stats,
          filterStatus: filterStatus,
        );
      },
    );
  }

  Future<void> refresh() => _load(filterStatus: state.filterStatus);

  Future<void> filterByStatus(ReportStatus? status) =>
      _load(filterStatus: status);
}

final dashboardProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(
  () => DashboardNotifier(),
);