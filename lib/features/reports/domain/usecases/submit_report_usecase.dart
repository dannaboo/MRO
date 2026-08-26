// lib/features/reports/domain/usecases/submit_report_usecase.dart
//
// Caso de uso: Enviar el reporte a revisión de oficina.
// Solo se puede enviar si tiene al menos un concepto/ítem.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class SubmitReportUseCase {
  final ReportRepository _repository;
  const SubmitReportUseCase(this._repository);

  Future<Either<Failure, DamageReportEntity>> call(String reportId) async {
    // Primero obtenemos el reporte para validar sus condiciones
    final reportResult = await _repository.getReportById(reportId);

    return reportResult.fold(
      (failure) => Left(failure),
      (report) async {
        // ─── REGLA DE NEGOCIO ──────────────────────────
        // No se puede enviar un reporte sin conceptos de daño.
        // Un reporte sin ítems no es procesable por la aseguradora.
        if (report.items.isEmpty) {
          return const Left(
            ValidationFailure(
              message: 'Agrega al menos un concepto de daño antes de enviar.',
            ),
          );
        }

        if (!report.isDraft) {
          return const Left(
            ValidationFailure(
              message: 'Solo se pueden enviar reportes en estado borrador.',
            ),
          );
        }

        return _repository.submitReport(reportId);
      },
    );
  }
}