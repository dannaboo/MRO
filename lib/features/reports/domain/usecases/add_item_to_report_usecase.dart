// lib/features/reports/domain/usecases/add_item_to_report_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/constants/app_constants.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class AddItemToReportUseCase {
  final ReportRepository _repository;
  const AddItemToReportUseCase(this._repository);

  Future<Either<Failure, DamageReportEntity>> call({
    required String reportId,
    required ReportItemEntity item,
  }) async {
    // Verificamos límites antes de llamar al repositorio
    final reportResult = await _repository.getReportById(reportId);

    return reportResult.fold(
      (failure) => Left(failure),
      (report) async {
        if (report.items.length >= AppConstants.maxItemsPerReport) {
          return Left(
            ValidationFailure(
              message: 'Máximo ${AppConstants.maxItemsPerReport} conceptos por reporte.',
            ),
          );
        }

        if (!report.isDraft) {
          return const Left(
            ValidationFailure(
              message: 'Solo se pueden agregar conceptos a reportes en borrador.',
            ),
          );
        }

        return _repository.addItemToReport(reportId: reportId, item: item);
      },
    );
  }
}
