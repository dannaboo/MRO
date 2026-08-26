// lib/features/reports/domain/usecases/get_reports_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class GetReportsUseCase {
  final ReportRepository _repository;
  const GetReportsUseCase(this._repository);

  Future<Either<Failure, List<DamageReportEntity>>> call({
    String? userId,
    ReportStatus? status,
  }) async {
    return _repository.getReports(userId: userId, status: status);
  }
}
