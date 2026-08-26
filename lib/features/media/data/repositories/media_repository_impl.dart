// lib/features/media/data/repositories/media_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/repositories/media_repository.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../datasources/media_datasource.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaDataSource _dataSource;
  const MediaRepositoryImpl({required MediaDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Either<Failure, String>> takePhoto() async {
    try {
      final path = await _dataSource.takePhoto();
      if (path == null) {
        return const Left(
          ValidationFailure(message: 'No se tomó ninguna foto.'),
        );
      }
      return Right(path);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> pickFromGallery() async {
    try {
      final path = await _dataSource.pickFromGallery();
      if (path == null) {
        return const Left(
          ValidationFailure(message: 'No se seleccionó ninguna foto.'),
        );
      }
      return Right(path);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PhotoEntity>> uploadPhoto({
    required String reportId,
    required String localPath,
    required String uploadedBy,
    required String uploadedByName,
    String? description,
    GeoLocation? location,
    required int order,
    void Function(double)? onProgress,
  }) async {
    try {
      final photo = await _dataSource.uploadPhoto(
        reportId: reportId,
        localPath: localPath,
        uploadedBy: uploadedBy,
        uploadedByName: uploadedByName,
        description: description,
        location: location,
        order: order,
        onProgress: onProgress,
      );
      return Right(photo);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PhotoEntity>>> getReportPhotos(
      String reportId) async {
    try {
      final photos = await _dataSource.getReportPhotos(reportId);
      return Right(photos);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deletePhoto({
    required String reportId,
    required String photoId,
    required String remoteUrl,
  }) async {
    try {
      await _dataSource.deletePhoto(
        reportId: reportId,
        photoId: photoId,
        remoteUrl: remoteUrl,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, GeoLocation>> getCurrentLocation() async {
    try {
      final location = await _dataSource.getCurrentLocation();
      return Right(location);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}