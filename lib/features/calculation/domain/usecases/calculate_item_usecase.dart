// lib/features/calculation/domain/usecases/calculate_item_usecase.dart
//
// Orquesta el cálculo de un concepto con sus medidas.
// Valida los inputs antes de pasar al motor.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../concepts/domain/entities/concept_entity.dart';
import '../entities/calculation_entity.dart';
import 'calculation_engine.dart';

class CalculateItemParams {
  final ConceptEntity concept;
  final double? length;
  final double? width;
  final double? height;
  final int? pieces;
  final double? quantity;

  const CalculateItemParams({
    required this.concept,
    this.length,
    this.width,
    this.height,
    this.pieces,
    this.quantity,
  });
}

class CalculateItemUseCase {
  final CalculationEngine _engine;
  const CalculateItemUseCase(this._engine);

  Either<Failure, CalculationResult> call(CalculateItemParams params) {
    // ─── VALIDAR QUE LAS MEDIDAS REQUERIDAS ESTÁN ────
    for (final field in params.concept.requiredMeasurements) {
      switch (field) {
        case MeasurementField.length:
          if (params.length == null || params.length! <= 0) {
            return Left(ValidationFailure(
              message: 'El Largo es requerido y debe ser mayor a 0.',
            ));
          }
        case MeasurementField.width:
          if (params.width == null || params.width! <= 0) {
            return Left(ValidationFailure(
              message: 'El Ancho es requerido y debe ser mayor a 0.',
            ));
          }
        case MeasurementField.height:
          if (params.height == null || params.height! <= 0) {
            return Left(ValidationFailure(
              message: 'El Alto es requerido y debe ser mayor a 0.',
            ));
          }
        case MeasurementField.pieces:
          if (params.pieces == null || params.pieces! <= 0) {
            return Left(ValidationFailure(
              message: 'Las Piezas deben ser mayor a 0.',
            ));
          }
        case MeasurementField.quantity:
          if (params.quantity == null || params.quantity! <= 0) {
            return Left(ValidationFailure(
              message: 'La Cantidad debe ser mayor a 0.',
            ));
          }
      }
    }

    // ─── VALIDACIONES DE RANGO ────────────────────────
    if (params.length != null && params.length! > 10000) {
      return const Left(ValidationFailure(
        message: 'El Largo no puede exceder 10,000 metros.',
      ));
    }
    if (params.pieces != null && params.pieces! > 9999) {
      return const Left(ValidationFailure(
        message: 'Las Piezas no pueden exceder 9,999.',
      ));
    }

    try {
      final result = _engine.calculate(
        concept: params.concept,
        length: params.length,
        width: params.width,
        height: params.height,
        pieces: params.pieces,
        quantity: params.quantity,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: 'Error en el cálculo: $e'));
    }
  }
}