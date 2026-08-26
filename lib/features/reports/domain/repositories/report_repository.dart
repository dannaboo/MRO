// lib/features/reports/domain/repositories/report_repository.dart
//
// Contrato que define TODAS las operaciones posibles
// con reportes. Ni la UI ni los casos de uso saben
// si los datos vienen de Firestore o de Hive.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/report_entity.dart';

abstract class ReportRepository {
  // ─── CREAR ────────────────────────────────────────────
  // Crea un borrador. Si hay internet lo guarda en Firestore.
  // Si no hay internet lo guarda en Hive y lo marca como pending.
  Future<Either<Failure, DamageReportEntity>> createReport(
    DamageReportEntity report,
  );

  // ─── LEER ─────────────────────────────────────────────
  // Retorna los reportes según el rol:
  // - fieldWorker: solo los suyos
  // - analyst/admin: todos
  Future<Either<Failure, List<DamageReportEntity>>> getReports({
    String? userId,       // null = todos (admin)
    ReportStatus? status, // null = todos los estados
    int limit = 20,
    DamageReportEntity? lastDocument, // para paginación
  });

  // Obtiene un reporte específico por su ID
  Future<Either<Failure, DamageReportEntity>> getReportById(String id);

  // Stream en tiempo real: la lista se actualiza automáticamente
  // cuando cambia algo en Firestore (ideal para el panel admin)
  Stream<Either<Failure, List<DamageReportEntity>>> watchReports({
    String? userId,
    ReportStatus? status,
  });

  // ─── ACTUALIZAR ───────────────────────────────────────
  Future<Either<Failure, DamageReportEntity>> updateReport(
    DamageReportEntity report,
  );

  // Enviar a revisión (cuadrillero → oficina)
  Future<Either<Failure, DamageReportEntity>> submitReport(String reportId);

  // Cambiar estado (solo admin/analyst)
  Future<Either<Failure, DamageReportEntity>> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? rejectionReason,
  });

  // ─── ÍTEMS ────────────────────────────────────────────
  // Agrega un concepto al reporte
  Future<Either<Failure, DamageReportEntity>> addItemToReport({
    required String reportId,
    required ReportItemEntity item,
  });

  // Elimina un concepto del reporte
  Future<Either<Failure, DamageReportEntity>> removeItemFromReport({
    required String reportId,
    required String itemId,
  });

  // ─── SINCRONIZACIÓN OFFLINE ───────────────────────────
  // Sincroniza todos los reportes pendientes de Hive → Firestore
  Future<Either<Failure, int>> syncPendingReports();

  // Descarga todos los reportes de Firestore → Hive (para modo offline)
  Future<Either<Failure, void>> downloadReportsForOffline({String? userId});
}
