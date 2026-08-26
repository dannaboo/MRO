// lib/features/media/domain/usecases/upload_photo_usecase.dart
//
// Caso de uso: subir una foto a Firebase Storage.
// Valida el tamaño del archivo antes de subir.

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../entities/photo_entity.dart';
import '../repositories/media_repository.dart';
import '../../../reports/domain/entities/report_entity.dart';

class UploadPhotoParams {
  final String reportId;
  final String localPath;
  final String uploadedBy;
  final String uploadedByName;
  final String? description;
  final GeoLocation? location;
  final int order;
  final void Function(double)? onProgress;

  const UploadPhotoParams({
    required this.reportId,
    required this.localPath,
    required this.uploadedBy,
    required this.uploadedByName,
    this.description,
    this.location,
    required this.order,
    this.onProgress,
  });
}

class UploadPhotoUseCase {
  final MediaRepository _repository;
  const UploadPhotoUseCase(this._repository);

  Future<Either<Failure, PhotoEntity>> call(UploadPhotoParams params) async {
    // Validar tamaño del archivo antes de subir
    // En web no podemos verificar el tamaño del path local fácilmente,
    // así que omitimos la validación en esa plataforma
    try {
      final file = File(params.localPath);
      if (await file.exists()) {
        final sizeBytes = await file.length();
        final sizeMB = sizeBytes / (1024 * 1024);
        if (sizeMB > AppConstants.maxPhotoSizeMB) {
          return Left(
            ValidationFailure(
              message: 'La foto excede el tamaño máximo de '
                  '${AppConstants.maxPhotoSizeMB} MB.',
            ),
          );
        }
      }
    } catch (_) {
      // En web o si el archivo no existe, continuamos
    }

    return _repository.uploadPhoto(
      reportId: params.reportId,
      localPath: params.localPath,
      uploadedBy: params.uploadedBy,
      uploadedByName: params.uploadedByName,
      description: params.description,
      location: params.location,
      order: params.order,
      onProgress: params.onProgress,
    );
  }
}