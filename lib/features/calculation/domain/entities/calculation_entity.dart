// lib/features/calculation/domain/entities/calculation_entity.dart
//
// Modela el resultado detallado de aplicar una fórmula
// de cálculo a las medidas ingresadas por el cuadrillero.
//
// Ejemplo real del tabulador:
// Concepto: "Defensa metálica tipo W c/poste IPR"
// Input: LARGO = 12 metros
// Output:
//   - Tramos W:   CEIL(12/3.81) = 4 pzas  × $580.00 = $2,320.00
//   - Postes IPR: 4+1           = 5 pzas  × $788.80 = $3,944.00
//   - Tornillos:  4×8           = 32 pzas × $12.50  =   $400.00
//   - M. de obra: 4 tramos      × $280.00 = $1,120.00
//   SUBTOTAL COMPONENTES: $7,784.00
//   O bien, precio unitario del catálogo × cantidad:
//   12 ML × $1,444.99 = $17,339.88

import 'package:equatable/equatable.dart';

// Un componente individual dentro del cálculo
// Ejemplo: "Postes IPR" → 5 piezas × $788.80 = $3,944.00
class CalculationComponent extends Equatable {
  final String name;
  final double quantity;
  final String unit;
  final double unitCost;
  final double subtotal;
  final String? formula; // descripción humana: "CEIL(12/3.81) + 1"

  const CalculationComponent({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.subtotal,
    this.formula,
  });

  @override
  List<Object?> get props => [name, quantity, unitCost];
}

// El resultado completo de un cálculo
class CalculationResult extends Equatable {
  final String conceptId;
  final String conceptCode;
  final String conceptName;

  // Medidas ingresadas
  final double? inputLength;
  final double? inputWidth;
  final double? inputHeight;
  final int? inputPieces;
  final double? inputQuantity;

  // Resultado principal
  final double calculatedQuantity;
  final String unit;
  final double unitPrice;

  // Desglose de componentes (puede estar vacío para cálculos simples)
  final List<CalculationComponent> components;

  // Totales
  final double subtotalWithoutTax;
  final double taxAmount;       // IVA 16%
  final double totalWithTax;

  final DateTime calculatedAt;

  const CalculationResult({
    required this.conceptId,
    required this.conceptCode,
    required this.conceptName,
    this.inputLength,
    this.inputWidth,
    this.inputHeight,
    this.inputPieces,
    this.inputQuantity,
    required this.calculatedQuantity,
    required this.unit,
    required this.unitPrice,
    this.components = const [],
    required this.subtotalWithoutTax,
    required this.taxAmount,
    required this.totalWithTax,
    required this.calculatedAt,
  });

  bool get hasComponents => components.isNotEmpty;

  @override
  List<Object?> get props => [conceptId, calculatedQuantity, totalWithTax];
}

// Resumen financiero completo de un reporte
class ReportFinancialSummary extends Equatable {
  final int itemCount;
  final double subtotalWithoutTax;
  final double taxAmount;
  final double totalWithTax;
  final Map<String, double> subtotalByCategory; // agrupado por categoría

  const ReportFinancialSummary({
    required this.itemCount,
    required this.subtotalWithoutTax,
    required this.taxAmount,
    required this.totalWithTax,
    required this.subtotalByCategory,
  });

  @override
  List<Object?> get props => [itemCount, totalWithTax];
}

// Regla de cálculo asociada a un tipo de concepto
// Define cómo se descompone el precio unitario en componentes
class CalculationRule extends Equatable {
  final String conceptCode;      // El código que activa esta regla (C.1.1)
  final String type;             // 'simple' | 'complex' | 'fixed'
  final List<ComponentRule> componentRules;

  const CalculationRule({
    required this.conceptCode,
    required this.type,
    this.componentRules = const [],
  });

  @override
  List<Object?> get props => [conceptCode];
}

class ComponentRule extends Equatable {
  final String name;
  final String formulaDescription; // texto para mostrar al usuario
  final double Function(double length, double width, double height, int pieces)
      calculate;
  final String unit;
  final double unitCost;

  const ComponentRule({
    required this.name,
    required this.formulaDescription,
    required this.calculate,
    required this.unit,
    required this.unitCost,
  });

  @override
  List<Object?> get props => [name, unitCost];
}