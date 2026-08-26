// lib/features/calculation/presentation/providers/calculation_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/calculation_entity.dart';
import '../../domain/usecases/calculation_engine.dart';
import '../../domain/usecases/calculate_item_usecase.dart';
import '../../../concepts/domain/entities/concept_entity.dart';

// Motor: singleton global
final calculationEngineProvider = Provider<CalculationEngine>((ref) {
  return CalculationEngine();
});

final calculateItemUseCaseProvider = Provider<CalculateItemUseCase>((ref) {
  return CalculateItemUseCase(ref.watch(calculationEngineProvider));
});

// Estado del calculador en tiempo real
// Se usa en la pantalla de selección de concepto
class CalculatorState {
  final CalculationResult? result;
  final String? error;
  final bool hasCalculated;

  const CalculatorState({
    this.result,
    this.error,
    this.hasCalculated = false,
  });

  CalculatorState copyWith({
    CalculationResult? result,
    String? error,
    bool? hasCalculated,
  }) {
    return CalculatorState(
      result: result ?? this.result,
      error: error,
      hasCalculated: hasCalculated ?? this.hasCalculated,
    );
  }
}

class CalculatorNotifier extends FamilyNotifier<CalculatorState, ConceptEntity> {
  @override
  CalculatorState build(ConceptEntity arg) => const CalculatorState();

  void calculate({
    double? length,
    double? width,
    double? height,
    int? pieces,
    double? quantity,
  }) {
    final useCase = ref.read(calculateItemUseCaseProvider);
    final result = useCase.call(
      CalculateItemParams(
        concept: arg,
        length: length,
        width: width,
        height: height,
        pieces: pieces,
        quantity: quantity,
      ),
    );

    result.fold(
      (failure) => state = state.copyWith(
        error: failure.message,
        hasCalculated: false,
      ),
      (calcResult) => state = state.copyWith(
        result: calcResult,
        error: null,
        hasCalculated: true,
      ),
    );
  }

  void reset() => state = const CalculatorState();
}

final calculatorProvider = NotifierProviderFamily<CalculatorNotifier, CalculatorState, ConceptEntity>(
  () => CalculatorNotifier(),
);
