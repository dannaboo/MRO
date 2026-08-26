// lib/features/reports/data/repositories/report_repository_impl.dart
// Implementa el contrato. Decide qué fuente usar:
// - Con internet: Firestore primero, luego cachea en Hive
// - Sin internet: Hive directamente, marca como pending

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_local_datasource.dart';
import '../datasources/report_remote_datasource.dart';
import '../models/report_model.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _remote;
  final ReportLocalDataSource _local;
  final Connectivity _connectivity;

  const ReportRepositoryImpl({
    required ReportRemoteDataSource remote,
    required ReportLocalDataSource local,
    required Connectivity connectivity,
  })  : _remote = remote,
        _local = local,
        _connectivity = connectivity;

  // Verifica si hay conexión a internet
  Future<bool> get _hasInternet async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  @override
Future<Either<Failure, DamageReportEntity>> createReport(
  DamageReportEntity report,
) async {
  // Convertimos la entidad del dominio a modelo de datos.
  // Antes hacíamos "report as DamageReportModel" que fallaba
  // cuando el UseCase pasaba una entidad pura.
  final model = report is DamageReportModel
      ? report
      : DamageReportModel.fromEntity(report);

  // SIEMPRE guardamos local primero — nunca se pierde información
  try {
    await _local.cacheReport(model);
  } catch (e) {
    return Left(CacheFailure(message: 'Error al guardar localmente: $e'));
  }

  // Si hay internet, sincronizamos con Firestore
  if (await _hasInternet) {
    try {
      final synced = await _remote.createReport(model);
      await _local.cacheReport(synced);
      return Right(synced);
    } on ServerException catch (_) {
      // Falla el servidor pero el dato está seguro en Hive
      return Right(model);
    } catch (e) {
      // Cualquier otro error — el dato sigue en Hive
      return Right(model);
    }
  }

  // Sin internet: devuelve el guardado local con syncStatus=pending
  return Right(model);
}

  @override
  Future<Either<Failure, List<DamageReportEntity>>> getReports({
    String? userId,
    ReportStatus? status,
    int limit = 20,
    DamageReportEntity? lastDocument,
  }) async {
    if (await _hasInternet) {
      try {
        final remote = await _remote.getReports(
          userId: userId,
          status: status,
          limit: limit,
        );
        // Cacheamos todos para modo offline
        for (final r in remote) {
          await _local.cacheReport(r);
        }
        return Right(remote);
      } on ServerException catch (_) {
        // Si Firestore falla, usamos el caché
        return _getFromCache(userId: userId);
      }
    }

    // Sin internet: solo caché
    return _getFromCache(userId: userId);
  }

  Future<Either<Failure, List<DamageReportEntity>>> _getFromCache({
    String? userId,
  }) async {
    try {
      final cached = await _local.getCachedReports(userId: userId);
      return Right(cached);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, DamageReportEntity>> getReportById(String id) async {
    if (await _hasInternet) {
      try {
        final report = await _remote.getReportById(id);
        await _local.cacheReport(report);
        return Right(report);
      } on ServerException {
        // Fallback a caché
      }
    }

    try {
      final cached = await _local.getCachedReportById(id);
      if (cached != null) return Right(cached);
      return const Left(CacheFailure(message: 'Reporte no encontrado localmente'));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Stream<Either<Failure, List<DamageReportEntity>>> watchReports({
    String? userId,
    ReportStatus? status,
  }) {
    return _remote.watchReports(userId: userId, status: status).map(
          (reports) => Right<Failure, List<DamageReportEntity>>(reports),
        );
  }

  @override
  Future<Either<Failure, DamageReportEntity>> updateReport(
    DamageReportEntity report,
  ) async {
    final model = report as DamageReportModel;
    await _local.cacheReport(model);

    if (await _hasInternet) {
      try {
        final updated = await _remote.updateReport(model);
        await _local.cacheReport(updated);
        return Right(updated);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    }
    return Right(model);
  }

  @override
  Future<Either<Failure, DamageReportEntity>> submitReport(
    String reportId,
  ) async {
    if (!await _hasInternet) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _remote.submitReport(reportId);
      await _local.cacheReport(result);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, DamageReportEntity>> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? rejectionReason,
  }) async {
    if (!await _hasInternet) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await _remote.updateReportStatus(
        reportId: reportId,
        newStatus: newStatus,
        rejectionReason: rejectionReason,
      );
      await _local.cacheReport(result);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  // REEMPLAZA el método addItemToReport completo:

@override
Future<Either<Failure, DamageReportEntity>> addItemToReport({
  required String reportId,
  required ReportItemEntity item,
}) async {
  if (!await _hasInternet) {
    return const Left(NetworkFailure());
  }
  try {
    // Convertimos la entidad a modelo de datos.
    // El cast directo falla en web cuando viene una entidad pura.
    final model = item is ReportItemModel
        ? item
        : ReportItemModel.fromEntity(item);

    final result = await _remote.addItemToReport(
      reportId: reportId,
      item: model,
    );
    await _local.cacheReport(result);
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message));
  } catch (e) {
    return Left(ServerFailure(message: 'Error al agregar concepto: $e'));
  }
}

  @override
  Future<Either<Failure, DamageReportEntity>> removeItemFromReport({
    required String reportId,
    required String itemId,
  }) async {
    if (!await _hasInternet) {
      return const Left(NetworkFailure());
    }
    try {
      final result =
          await _remote.removeItemFromReport(reportId: reportId, itemId: itemId);
      await _local.cacheReport(result);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, int>> syncPendingReports() async {
    if (!await _hasInternet) return const Left(NetworkFailure());

    try {
      final pending = await _local.getPendingReports();
      int synced = 0;

      for (final report in pending) {
        try {
          final uploaded = await _remote.createReport(report);
          await _local.cacheReport(uploaded);
          synced++;
        } catch (_) {
          // Si falla uno, continúa con el siguiente
        }
      }
      return Right(synced);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> downloadReportsForOffline({
    String? userId,
  }) async {
    if (!await _hasInternet) return const Left(NetworkFailure());

    try {
      final reports = await _remote.getReports(userId: userId, limit: 100);
      for (final r in reports) {
        await _local.cacheReport(r);
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}