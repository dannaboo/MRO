// lib/features/reports/domain/usecases/create_report_usecase.dart
//
// Caso de uso: Crear un nuevo reporte de daños.
// Genera el número de reporte, valida los datos mínimos,
// y lo envía al repositorio.

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class CreateReportParams {
  final String highway;
  final double kmStart;
  final double kmEnd;
  final RoadBody body;
  final RoadSide side;
  final RoadType roadType;
  final double? speedLimit;
  final DateTime accidentDate;
  final String observations;
  final String squadNumber;
  final String createdBy;
  final String createdByName;
  final GeoLocation? location;
  final String? locationAddress;
  final List<VehicleInfo> vehicles;
  final int fatalitiesCount;
  final int seriousInjuriesCount;
  final int minorInjuriesCount;
  final int uninjuredCount;
  final String? probableCause;
  final String? incidentDescription;
  final String? weatherCondition;
  final String? surfaceCondition;
  final String? lightCondition;

  const CreateReportParams({
    required this.highway,
    required this.kmStart,
    required this.kmEnd,
    required this.body,
    required this.side,
    required this.roadType,
    this.speedLimit,
    required this.accidentDate,
    required this.observations,
    required this.squadNumber,
    required this.createdBy,
    required this.createdByName,
    this.location,
    this.locationAddress,
    this.vehicles = const [],
    this.fatalitiesCount = 0,
    this.seriousInjuriesCount = 0,
    this.minorInjuriesCount = 0,
    this.uninjuredCount = 0,
    this.probableCause,
    this.incidentDescription,
    this.weatherCondition,
    this.surfaceCondition,
    this.lightCondition,
  });
}

class CreateReportUseCase {
  final ReportRepository _repository;
  final Uuid _uuid;

  const CreateReportUseCase(this._repository, this._uuid);

  Future<Either<Failure, DamageReportEntity>> call(
      CreateReportParams params) async {
    // ─── VALIDACIONES ─────────────────────────────────
    if (params.highway.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'El nombre de la carretera es requerido.'),
      );
    }
    if (params.kmStart < 0 || params.kmEnd < 0) {
      return const Left(
        ValidationFailure(message: 'Los kilómetros deben ser positivos.'),
      );
    }
    if (params.kmStart > params.kmEnd) {
      return const Left(
        ValidationFailure(
          message: 'El KM inicial no puede ser mayor al KM final.',
        ),
      );
    }

    // ─── GENERAR NÚMERO DE REPORTE ────────────────────
    // Formato: MRO-2026-XXXXXX
    final year = params.accidentDate.year;
    final shortId = _uuid.v4().substring(0, 6).toUpperCase();
    final reportNumber = '${AppConstants.reportPrefix}-$year-$shortId';

    // ─── CONSTRUIR LA ENTIDAD ─────────────────────────
    final now = DateTime.now();
    final report = DamageReportEntity(
      id: _uuid.v4(),
      reportNumber: reportNumber,
      status: ReportStatus.draft,
      syncStatus: SyncStatus.pending, // Siempre empieza como pending
      highway: params.highway.trim(),
      kmStart: params.kmStart,
      kmEnd: params.kmEnd,
      body: params.body,
      side: params.side,
      roadType: params.roadType,
      speedLimit: params.speedLimit,
      accidentDate: params.accidentDate,
      incidentDescription: params.incidentDescription,
      vehicles: params.vehicles,
      fatalitiesCount: params.fatalitiesCount,
      seriousInjuriesCount: params.seriousInjuriesCount,
      minorInjuriesCount: params.minorInjuriesCount,
      uninjuredCount: params.uninjuredCount,
      probableCause: params.probableCause,
      weatherCondition: params.weatherCondition,
      surfaceCondition: params.surfaceCondition,
      lightCondition: params.lightCondition,
      observations: params.observations.trim(),
      location: params.location,
      locationAddress: params.locationAddress,
      squadNumber: params.squadNumber,
      createdBy: params.createdBy,
      createdByName: params.createdByName,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.createReport(report);
  }
}