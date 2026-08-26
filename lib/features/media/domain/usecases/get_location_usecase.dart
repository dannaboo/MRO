// lib/features/media/domain/usecases/get_location_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/media_repository.dart';
import '../../../reports/domain/entities/report_entity.dart';

class GetLocationUseCase {
  final MediaRepository _repository;
  const GetLocationUseCase(this._repository);

  Future<Either<Failure, GeoLocation>> call() async {
    return _repository.getCurrentLocation();
  }
}
