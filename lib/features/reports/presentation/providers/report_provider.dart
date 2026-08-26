// lib/features/reports/presentation/providers/report_provider.dart
//
// Providers de Riverpod que conectan UI → Casos de Uso.
// AsyncNotifier maneja los 3 estados: loading / data / error.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/report_local_datasource.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/usecases/add_item_to_report_usecase.dart';
import '../../domain/usecases/create_report_usecase.dart';
import '../../domain/usecases/get_reports_usecase.dart';
import '../../domain/usecases/submit_report_usecase.dart';
import 'package:mro_damage_system/features/auth/domain/entities/user_entity.dart';
// ─── PROVIDERS DE INFRAESTRUCTURA ───────────────────────

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final reportLocalDataSourceProvider = Provider<ReportLocalDataSource>((ref) {
  return ReportLocalDataSourceImpl();
});

final reportRemoteDataSourceProvider = Provider<ReportRemoteDataSource>((ref) {
  return ReportRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(
    remote: ref.watch(reportRemoteDataSourceProvider),
    local: ref.watch(reportLocalDataSourceProvider),
    connectivity: ref.watch(connectivityProvider),
  );
});

// ─── PROVIDERS DE CASOS DE USO ──────────────────────────

final createReportUseCaseProvider = Provider<CreateReportUseCase>((ref) {
  return CreateReportUseCase(
    ref.watch(reportRepositoryProvider),
    const Uuid(),
  );
});

final getReportsUseCaseProvider = Provider<GetReportsUseCase>((ref) {
  return GetReportsUseCase(ref.watch(reportRepositoryProvider));
});

final submitReportUseCaseProvider = Provider<SubmitReportUseCase>((ref) {
  return SubmitReportUseCase(ref.watch(reportRepositoryProvider));
});

final addItemUseCaseProvider = Provider<AddItemToReportUseCase>((ref) {
  return AddItemToReportUseCase(ref.watch(reportRepositoryProvider));
});

// ─── ESTADO DE LISTA DE REPORTES ────────────────────────

// Centinela: objeto único que usamos para distinguir
// "no pasaste filterStatus" de "pasaste null explícitamente".
// Sin esto, copyWith(filterStatus: null) es idéntico a no pasar el parámetro.
const _kUnset = Object();

class ReportsState {
  final List<DamageReportEntity> reports;
  final bool isLoading;
  final String? error;
  final ReportStatus? filterStatus; // null = "Todos"

  const ReportsState({
    this.reports = const [],
    this.isLoading = false,
    this.error,
    this.filterStatus,
  });

  ReportsState copyWith({
    List<DamageReportEntity>? reports,
    bool? isLoading,
    String? error,
    // Usamos Object? con valor por defecto _kUnset para poder
    // distinguir "no lo pasaste" de "lo pasaste como null"
    Object? filterStatus = _kUnset,
  }) {
    return ReportsState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: error, // null borra el error anterior (intencional)
      filterStatus: filterStatus == _kUnset
          ? this.filterStatus          // no se pasó → mantén el valor actual
          : filterStatus as ReportStatus?, // se pasó → usa el nuevo (puede ser null)
    );
  }
}

class ReportsNotifier extends Notifier<ReportsState> {
  @override
  ReportsState build() {
    // Carga inicial al construirse
    Future.microtask(() => loadReports());
    return const ReportsState(isLoading: true);
  }

  Future<void> loadReports({ReportStatus? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    final user = ref.read(currentUserProvider);
    // Si es cuadrillero o supervisor, solo ve sus propios reportes
    
    final userId = user?.role.canViewAllReports == false ? user?.uid : null;

    final result = await ref.read(getReportsUseCaseProvider).call(
          userId: userId,
          status: status ?? state.filterStatus,
        );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (reports) => state = state.copyWith(
        isLoading: false,
        reports: reports,
        filterStatus: status,
      ),
    );
  }

  Future<String?> createReport(CreateReportParams params) async {
  state = state.copyWith(isLoading: true, error: null);

  try {
    final result = await ref.read(createReportUseCaseProvider).call(params);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return null;
      },
      (report) {
        state = state.copyWith(
          isLoading: false,
          reports: [report, ...state.reports],
        );
        return report.id;
      },
    );
  } catch (e) {
    // Captura cualquier excepción no manejada para que el spinner
    // nunca quede girando indefinidamente
    state = state.copyWith(
      isLoading: false,
      error: 'Error inesperado: $e',
    );
    return null;
  }
}

  Future<bool> submitReport(String reportId) async {
    final result = await ref.read(submitReportUseCaseProvider).call(reportId);

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (report) {
        // Actualiza el reporte en la lista
        final updated = state.reports
            .map((r) => r.id == reportId ? report : r)
            .toList();
        state = state.copyWith(reports: updated);
        return true;
      },
    );
  }

  void clearError() => state = state.copyWith(error: null);
}

final reportsProvider = NotifierProvider<ReportsNotifier, ReportsState>(() {
  return ReportsNotifier();
});

// ─── PROVIDER DE REPORTE INDIVIDUAL ─────────────────────
// Carga un reporte específico por ID (para la pantalla de detalle)

final reportDetailProvider = FutureProvider.family<DamageReportEntity?, String>(
  (ref, reportId) async {
    final result = await ref
        .watch(reportRepositoryProvider)
        .getReportById(reportId);

    return result.fold((_) => null, (r) => r);
  },
);