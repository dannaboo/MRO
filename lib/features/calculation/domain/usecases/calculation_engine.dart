// lib/features/calculation/domain/usecases/calculation_engine.dart
//
// Motor central de cálculo del sistema MRO.
//
// Implementa la lógica del sheet GENERADORES del tabulador real.
// Para cada tipo de concepto define CÓMO calcular la cantidad
// final a partir de las medidas ingresadas.
//
// TIPOS DE CÁLCULO:
//
// SIMPLE:  cantidad = medida directa (ML, M2, M3, PZA)
//          Precio final = cantidad × P.U. con IVA del tabulador
//
// COMPLEX: cantidad + desglose de subcomponentes
//          Ejemplo: defensa metálica → tramos + postes + tornillos
//          El precio del tabulador ya incluye todos los componentes,
//          pero mostramos el desglose para transparencia.
//
// FORMULA: cálculo personalizado con reglas especiales
//          Ejemplo: bacheo → área = largo × ancho, mínimo 1 m²

import 'dart:math' as math;

import '../../../../core/constants/app_constants.dart';
import '../../../concepts/domain/entities/concept_entity.dart';
import '../entities/calculation_entity.dart';

class CalculationEngine {
  // Singleton: una sola instancia en toda la app
  static final CalculationEngine _instance = CalculationEngine._internal();
  factory CalculationEngine() => _instance;
  CalculationEngine._internal();

  // ─── MÉTODO PRINCIPAL ────────────────────────────────
  // Recibe un concepto y las medidas, devuelve el resultado completo.
  CalculationResult calculate({
    required ConceptEntity concept,
    double? length,
    double? width,
    double? height,
    int? pieces,
    double? quantity,
    double taxRate = AppConstants.taxRate,
  }) {
    // Determina el tipo de cálculo según el código del concepto
    final rule = _getRuleForConcept(concept.code);

    if (rule != null && rule.type == 'complex') {
      return _calculateComplex(
        concept: concept,
        rule: rule,
        length: length ?? 0,
        width: width ?? 0,
        height: height ?? 0,
        pieces: pieces ?? 0,
        taxRate: taxRate,
      );
    }

    return _calculateSimple(
      concept: concept,
      length: length,
      width: width,
      height: height,
      pieces: pieces,
      quantity: quantity,
      taxRate: taxRate,
    );
  }

  // ─── CÁLCULO SIMPLE ──────────────────────────────────
  // La cantidad la determina directamente la unidad del concepto.
  // El precio viene del tabulador sin modificación.
  CalculationResult _calculateSimple({
    required ConceptEntity concept,
    double? length,
    double? width,
    double? height,
    int? pieces,
    double? quantity,
    required double taxRate,
  }) {
    final qty = concept.calculateQuantity(
      length: length,
      width: width,
      height: height,
      pieces: pieces,
      quantity: quantity,
    );

    // El tabulador ya incluye IVA en unitPriceWithTax.
    // El precio sin IVA es el que usamos para los cálculos contables.
    final subtotalWithTax = qty * concept.unitPriceWithTax;
    final subtotalWithoutTax = qty * concept.unitPriceWithoutTax;
    final taxAmount = subtotalWithoutTax * taxRate;

    return CalculationResult(
      conceptId: concept.id,
      conceptCode: concept.code,
      conceptName: concept.name,
      inputLength: length,
      inputWidth: width,
      inputHeight: height,
      inputPieces: pieces,
      inputQuantity: quantity,
      calculatedQuantity: qty,
      unit: concept.unit.displayName,
      unitPrice: concept.unitPriceWithTax,
      subtotalWithoutTax: subtotalWithoutTax,
      taxAmount: taxAmount,
      totalWithTax: subtotalWithTax,
      calculatedAt: DateTime.now(),
    );
  }

  // ─── CÁLCULO COMPLEJO ────────────────────────────────
  // Usa las reglas de componentes para descomponer el precio.
  // IMPORTANTE: el total sigue siendo cantidad × P.U. del tabulador.
  // Los componentes son solo para mostrar el desglose al cliente.
  CalculationResult _calculateComplex({
    required ConceptEntity concept,
    required CalculationRule rule,
    required double length,
    required double width,
    required double height,
    required int pieces,
    required double taxRate,
  }) {
    final qty = concept.calculateQuantity(
      length: length,
      width: width,
      height: height,
      pieces: pieces,
    );

    // Calcular cada componente
    final components = rule.componentRules.map((comp) {
      final compQty = comp.calculate(length, width, height, pieces);
      final compSubtotal = compQty * comp.unitCost;
      return CalculationComponent(
        name: comp.name,
        quantity: compQty,
        unit: comp.unit,
        unitCost: comp.unitCost,
        subtotal: compSubtotal,
        formula: comp.formulaDescription,
      );
    }).toList();

    // El total financiero usa el precio del tabulador (ya validado con la aseguradora)
    final subtotalWithTax = qty * concept.unitPriceWithTax;
    final subtotalWithoutTax = qty * concept.unitPriceWithoutTax;
    final taxAmount = subtotalWithoutTax * taxRate;

    return CalculationResult(
      conceptId: concept.id,
      conceptCode: concept.code,
      conceptName: concept.name,
      inputLength: length,
      inputWidth: width,
      inputHeight: height,
      calculatedQuantity: qty,
      unit: concept.unit.displayName,
      unitPrice: concept.unitPriceWithTax,
      components: components,
      subtotalWithoutTax: subtotalWithoutTax,
      taxAmount: taxAmount,
      totalWithTax: subtotalWithTax,
      calculatedAt: DateTime.now(),
    );
  }

  // ─── RESUMEN FINANCIERO DEL REPORTE ──────────────────
  // Recalcula todos los totales de un reporte desde cero.
  // Se llama después de agregar o eliminar un ítem.
  ReportFinancialSummary calculateReportSummary({
    required List<({
      String conceptCode,
      String category,
      double quantity,
      double unitPrice,
      double subtotal,
    })> items,
    double taxRate = AppConstants.taxRate,
  }) {
    final subtotalByCategory = <String, double>{};
    double totalSubtotalWithTax = 0;

    for (final item in items) {
      totalSubtotalWithTax += item.subtotal;
      subtotalByCategory[item.category] =
          (subtotalByCategory[item.category] ?? 0) + item.subtotal;
    }

    // Reversa: el subtotal con IVA / 1.16 = subtotal sin IVA
    final subtotalWithoutTax = totalSubtotalWithTax / (1 + taxRate);
    final taxAmount = totalSubtotalWithTax - subtotalWithoutTax;

    return ReportFinancialSummary(
      itemCount: items.length,
      subtotalWithoutTax: subtotalWithoutTax,
      taxAmount: taxAmount,
      totalWithTax: totalSubtotalWithTax,
      subtotalByCategory: subtotalByCategory,
    );
  }

  // ─── REGLAS DE COMPONENTES POR CONCEPTO ──────────────
  // Basadas en el sheet GENERADORES del tabulador MRO 2021.
  // Solo los conceptos con desglose complejo tienen regla aquí.
  // Los demás usan cálculo simple.
  CalculationRule? _getRuleForConcept(String code) {
    return _complexRules[code];
  }

  // Mapa de reglas complejas
  // La clave es el código exacto del tabulador.
  late final Map<String, CalculationRule> _complexRules = {

    // ═══════════════════════════════════════════════════
    // C.1.1 — Defensa metálica tipo W c/poste IPR
    // Fórmula del generador:
    //   tramos = CEIL(LARGO / 3.81)
    //   postes = tramos + 1
    //   tornillos = tramos × 8
    //   Precio tabulador = $1,444.99/ML (ya incluye todo)
    // ═══════════════════════════════════════════════════
    'C.1.1': CalculationRule(
      conceptCode: 'C.1.1',
      type: 'complex',
      componentRules: [
        ComponentRule(
          name: 'Tramos de defensa W',
          formulaDescription: 'CEIL(Largo / 3.81m)',
          calculate: (l, w, h, p) => _ceil(l / 3.81),
          unit: 'PZA',
          unitCost: 580.00,
        ),
        ComponentRule(
          name: 'Postes metálicos IPR',
          formulaDescription: 'CEIL(Largo / 3.81m) + 1',
          calculate: (l, w, h, p) => _ceil(l / 3.81) + 1,
          unit: 'PZA',
          unitCost: 788.80,
        ),
        ComponentRule(
          name: 'Tornillos y tuercas galv.',
          formulaDescription: 'CEIL(Largo / 3.81m) × 8',
          calculate: (l, w, h, p) => (_ceil(l / 3.81) * 8),
          unit: 'PZA',
          unitCost: 12.50,
        ),
        ComponentRule(
          name: 'Placas de unión',
          formulaDescription: 'CEIL(Largo / 3.81m) × 2',
          calculate: (l, w, h, p) => (_ceil(l / 3.81) * 2),
          unit: 'PZA',
          unitCost: 45.00,
        ),
        ComponentRule(
          name: 'Mano de obra instalación',
          formulaDescription: 'CEIL(Largo / 3.81m) tramos',
          calculate: (l, w, h, p) => _ceil(l / 3.81),
          unit: 'TRAMO',
          unitCost: 280.00,
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════
    // C.1.2 — Defensa metálica tipo W c/poste de madera
    // ═══════════════════════════════════════════════════
    'C.1.2': CalculationRule(
      conceptCode: 'C.1.2',
      type: 'complex',
      componentRules: [
        ComponentRule(
          name: 'Tramos de defensa W',
          formulaDescription: 'CEIL(Largo / 3.81m)',
          calculate: (l, w, h, p) => _ceil(l / 3.81),
          unit: 'PZA',
          unitCost: 580.00,
        ),
        ComponentRule(
          name: 'Postes de madera',
          formulaDescription: 'CEIL(Largo / 3.81m) + 1',
          calculate: (l, w, h, p) => _ceil(l / 3.81) + 1,
          unit: 'PZA',
          unitCost: 320.00,
        ),
        ComponentRule(
          name: 'Tornillos y tuercas',
          formulaDescription: 'CEIL(Largo / 3.81m) × 8',
          calculate: (l, w, h, p) => (_ceil(l / 3.81) * 8),
          unit: 'PZA',
          unitCost: 12.50,
        ),
        ComponentRule(
          name: 'Mano de obra instalación',
          formulaDescription: 'CEIL(Largo / 3.81m) tramos',
          calculate: (l, w, h, p) => _ceil(l / 3.81),
          unit: 'TRAMO',
          unitCost: 220.00,
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════
    // C.3.1 — Separador tipo New Jersey
    // Fórmula: cada pieza pesa ~800kg, incluye grúa
    // ═══════════════════════════════════════════════════
    'C.3.1': CalculationRule(
      conceptCode: 'C.3.1',
      type: 'complex',
      componentRules: [
        ComponentRule(
          name: 'Separadores NJ (pieza)',
          formulaDescription: 'Piezas ingresadas',
          calculate: (l, w, h, pzs) => pzs.toDouble(),
          unit: 'PZA',
          unitCost: 4500.00,
        ),
        ComponentRule(
          name: 'Maniobras con grúa',
          formulaDescription: 'CEIL(Piezas / 4) viajes',
          calculate: (l, w, h, pzs) => _ceil(pzs / 4),
          unit: 'VIAJE',
          unitCost: 3500.00,
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════
    // D.1.1 — Bacheo superficial
    // Fórmula: área = Largo × Ancho
    // Mínimo 1 m² por especificación de contrato
    // ═══════════════════════════════════════════════════
    'D.1.1': CalculationRule(
      conceptCode: 'D.1.1',
      type: 'complex',
      componentRules: [
        ComponentRule(
          name: 'Corte y retiro de carpeta',
          formulaDescription: 'Largo × Ancho m²',
          calculate: (l, w, h, p) => math.max(l * w, 1.0),
          unit: 'M²',
          unitCost: 95.00,
        ),
        ComponentRule(
          name: 'Mezcla asfáltica en caliente',
          formulaDescription: 'Largo × Ancho × 0.05m (5cm)',
          calculate: (l, w, h, p) => math.max(l * w * 0.05, 0.05),
          unit: 'M³',
          unitCost: 4850.00,
        ),
        ComponentRule(
          name: 'Compactación y acabado',
          formulaDescription: 'Largo × Ancho m²',
          calculate: (l, w, h, p) => math.max(l * w, 1.0),
          unit: 'M²',
          unitCost: 45.00,
        ),
        ComponentRule(
          name: 'Riego de liga',
          formulaDescription: 'Largo × Ancho m²',
          calculate: (l, w, h, p) => math.max(l * w, 1.0),
          unit: 'M²',
          unitCost: 18.00,
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════
    // D.1.2 — Bacheo profundo e=10cm
    // ═══════════════════════════════════════════════════
    'D.1.2': CalculationRule(
      conceptCode: 'D.1.2',
      type: 'complex',
      componentRules: [
        ComponentRule(
          name: 'Demolición y retiro',
          formulaDescription: 'Largo × Ancho m²',
          calculate: (l, w, h, p) => math.max(l * w, 1.0),
          unit: 'M²',
          unitCost: 125.00,
        ),
        ComponentRule(
          name: 'Base hidráulica e=10cm',
          formulaDescription: 'Largo × Ancho × 0.10m',
          calculate: (l, w, h, p) => math.max(l * w * 0.10, 0.1),
          unit: 'M³',
          unitCost: 3200.00,
        ),
        ComponentRule(
          name: 'Mezcla asfáltica e=10cm',
          formulaDescription: 'Largo × Ancho × 0.10m',
          calculate: (l, w, h, p) => math.max(l * w * 0.10, 0.1),
          unit: 'M³',
          unitCost: 4850.00,
        ),
        ComponentRule(
          name: 'Compactación',
          formulaDescription: 'Largo × Ancho m²',
          calculate: (l, w, h, p) => math.max(l * w, 1.0),
          unit: 'M²',
          unitCost: 65.00,
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════
    // E.1.1 — Reparación de barandal de puente
    // Fórmula: tramos de 2m c/u
    // ═══════════════════════════════════════════════════
    'E.1.1': CalculationRule(
      conceptCode: 'E.1.1',
      type: 'complex',
      componentRules: [
        ComponentRule(
          name: 'Tramos de barandal (2m)',
          formulaDescription: 'CEIL(Largo / 2.0m)',
          calculate: (l, w, h, p) => _ceil(l / 2.0),
          unit: 'PZA',
          unitCost: 2400.00,
        ),
        ComponentRule(
          name: 'Postes de anclaje',
          formulaDescription: 'CEIL(Largo / 2.0m) + 1',
          calculate: (l, w, h, p) => _ceil(l / 2.0) + 1,
          unit: 'PZA',
          unitCost: 850.00,
        ),
        ComponentRule(
          name: 'Soldadura y pintura anticorrosiva',
          formulaDescription: 'Largo metros lineales',
          calculate: (l, w, h, p) => l,
          unit: 'ML',
          unitCost: 185.00,
        ),
      ],
    ),

    // ═══════════════════════════════════════════════════
    // G.1.1 — Reparación de talud
    // Fórmula: volumen = Largo × Ancho × Alto
    // ═══════════════════════════════════════════════════
    'G.1.1': CalculationRule(
      conceptCode: 'G.1.1',
      type: 'complex',
      componentRules: [
        ComponentRule(
          name: 'Material de relleno',
          formulaDescription: 'Largo × Ancho × Alto m³',
          calculate: (l, w, h, p) => l * w * h,
          unit: 'M³',
          unitCost: 95.00,
        ),
        ComponentRule(
          name: 'Tendido y conformación',
          formulaDescription: 'Largo × Ancho m²',
          calculate: (l, w, h, p) => l * w,
          unit: 'M²',
          unitCost: 28.00,
        ),
        ComponentRule(
          name: 'Compactación',
          formulaDescription: 'Largo × Ancho × Alto m³',
          calculate: (l, w, h, p) => l * w * h,
          unit: 'M³',
          unitCost: 45.00,
        ),
      ],
    ),
  };

  // ─── UTILIDADES MATEMÁTICAS ──────────────────────────

  // Redondeo hacia arriba (CEIL)
  // Ejemplo: CEIL(12/3.81) = CEIL(3.149) = 4
  static double _ceil(double value) =>
      value.ceil().toDouble();

  // Redondeo comercial a 2 decimales
  static double round2(double value) =>
      (value * 100).round() / 100;
}