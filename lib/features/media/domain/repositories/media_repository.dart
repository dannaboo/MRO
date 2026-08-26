// lib/features/media/domain/repositories/media_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/photo_entity.dart';
import '../../../reports/domain/entities/report_entity.dart';

abstract class MediaRepository {
  // Toma una foto con la cámara del dispositivo.
  // Retorna el path local del archivo.
  Future<Either<Failure, String>> takePhoto();

  // Selecciona foto de la galería.
  Future<Either<Failure, String>> pickFromGallery();

  // Sube una foto a Firebase Storage y retorna la URL.
  // Reporta progreso (0.0 a 1.0) a través del callback.
  Future<Either<Failure, PhotoEntity>> uploadPhoto({
    required String reportId,
    required String localPath,
    required String uploadedBy,
    required String uploadedByName,
    String? description,
    GeoLocation? location,
    required int order,
    void Function(double progress)? onProgress,
  });

  // Obtiene todas las fotos de un reporte desde Firebase Storage
  Future<Either<Failure, List<PhotoEntity>>> getReportPhotos(String reportId);

  // Elimina una foto del Storage y de Firestore
  Future<Either<Failure, void>> deletePhoto({
    required String reportId,
    required String photoId,
    required String remoteUrl,
  });

  // Obtiene la ubicación GPS actual
  Future<Either<Failure, GeoLocation>> getCurrentLocation();
}