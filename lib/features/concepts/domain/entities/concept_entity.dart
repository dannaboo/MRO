// lib/features/concepts/domain/entities/concept_entity.dart
//
// Modela exactamente la estructura del TABULADOR MR 2021:
// Clave | Concepto | Unidad | P.U. sin IVA | P.U. con IVA
//
// Cada concepto sabe qué medidas necesita para calcularse
// (del sheet GENERADORES: LARGO, ANCHO, ALTO, PIEZAS).

import 'package:equatable/equatable.dart';

// Tipo de unidad de medida (del tabulador real)
enum MeasurementUnit {
  ml,   // Metro lineal
  m2,   // Metro cuadrado
  m3,   // Metro cúbico
  pza,  // Pieza
  kg,   // Kilogramo
  ton,  // Tonelada
  lt,   // Litro
  jgo,  // Juego
  lote, // Lote
  viaje;// Viaje

  String get displayName {
    switch (this) {
      case MeasurementUnit.ml:    return 'ML';
      case MeasurementUnit.m2:    return 'M²';
      case MeasurementUnit.m3:    return 'M³';
      case MeasurementUnit.pza:   return 'PZA';
      case MeasurementUnit.kg:    return 'KG';
      case MeasurementUnit.ton:   return 'TON';
      case MeasurementUnit.lt:    return 'LT';
      case MeasurementUnit.jgo:   return 'JGO';
      case MeasurementUnit.lote:  return 'LOTE';
      case MeasurementUnit.viaje: return 'VIAJE';
    }
  }

  String get value => name.toUpperCase();

  static MeasurementUnit fromString(String v) {
    switch (v.toLowerCase().trim()) {
      case 'ml':    return MeasurementUnit.ml;
      case 'm2':
      case 'm²':    return MeasurementUnit.m2;
      case 'm3':
      case 'm³':    return MeasurementUnit.m3;
      case 'pza':
      case 'pieza': return MeasurementUnit.pza;
      case 'kg':    return MeasurementUnit.kg;
      case 'ton':   return MeasurementUnit.ton;
      case 'lt':    return MeasurementUnit.lt;
      case 'jgo':   return MeasurementUnit.jgo;
      case 'lote':  return MeasurementUnit.lote;
      case 'viaje': return MeasurementUnit.viaje;
      default:      return MeasurementUnit.pza;
    }
  }

  // ¿Qué campos de medida requiere esta unidad?
  List<MeasurementField> get requiredFields {
    switch (this) {
      case MeasurementUnit.ml:
        return [MeasurementField.length];
      case MeasurementUnit.m2:
        return [MeasurementField.length, MeasurementField.width];
      case MeasurementUnit.m3:
        return [MeasurementField.length, MeasurementField.width, MeasurementField.height];
      case MeasurementUnit.pza:
      case MeasurementUnit.jgo:
      case MeasurementUnit.lote:
      case MeasurementUnit.viaje:
        return [MeasurementField.pieces];
      case MeasurementUnit.kg:
      case MeasurementUnit.ton:
      case MeasurementUnit.lt:
        return [MeasurementField.quantity];
    }
  }
}

// Campos que el generador puede pedir al cuadrillero
enum MeasurementField {
  length,   // LARGO (metros)
  width,    // ANCHO (metros)
  height,   // ALTO (metros)
  pieces,   // PIEZAS (entero)
  quantity; // CANTIDAD genérica

  String get label {
    switch (this) {
      case MeasurementField.length:   return 'Largo (m)';
      case MeasurementField.width:    return 'Ancho (m)';
      case MeasurementField.height:   return 'Alto (m)';
      case MeasurementField.pieces:   return 'Piezas';
      case MeasurementField.quantity: return 'Cantidad';
    }
  }

  String get value => name;
  bool get isDecimal => this != MeasurementField.pieces;
}

class ConceptEntity extends Equatable {
  final String id;
  final String code;          // "D.1.2" — clave del tabulador
  final String name;          // "Suministro y colocación de Defensa Metálica W"
  final String category;      // "DEFENSAS", "SEÑALAMIENTO", etc.
  final String? subcategory;
  final MeasurementUnit unit; // ML, M2, PZA...
  final double unitPriceWithoutTax;  // P.U. sin IVA
  final double unitPriceWithTax;     // P.U. con IVA (= sin IVA × 1.16)
  final String? description;
  final bool isActive;

  // Palabras clave para búsqueda rápida
  // Incluye el nombre descompuesto + sinónimos
  final List<String> searchTags;

  const ConceptEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    this.subcategory,
    required this.unit,
    required this.unitPriceWithoutTax,
    required this.unitPriceWithTax,
    this.description,
    this.isActive = true,
    this.searchTags = const [],
  });

  // Calcula qué campos de medida necesita este concepto
  List<MeasurementField> get requiredMeasurements => unit.requiredFields;

  // Calcula el subtotal dado una cantidad
  double calculateSubtotal(double quantity) => unitPriceWithTax * quantity;

  // Calcula la cantidad dado las medidas ingresadas
  double calculateQuantity({
    double? length,
    double? width,
    double? height,
    int? pieces,
    double? quantity,
  }) {
    switch (unit) {
      case MeasurementUnit.ml:
        return length ?? 0;
      case MeasurementUnit.m2:
        return (length ?? 0) * (width ?? 1);
      case MeasurementUnit.m3:
        return (length ?? 0) * (width ?? 1) * (height ?? 1);
      case MeasurementUnit.pza:
      case MeasurementUnit.jgo:
      case MeasurementUnit.lote:
      case MeasurementUnit.viaje:
        return (pieces ?? 0).toDouble();
      case MeasurementUnit.kg:
      case MeasurementUnit.ton:
      case MeasurementUnit.lt:
        return quantity ?? 0;
    }
  }

  // Genera las search tags automáticamente desde el nombre
  // "Defensa metálica W tipo 1" → ["defensa", "metalica", "tipo", "1", ...]
  static List<String> generateSearchTags(String name, String code) {
    final words = name
        .toLowerCase()
        .replaceAllMapped(RegExp(r'[áéíóúü]', caseSensitive: false), (Match m) {
  const map = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
  final char = m[0]!.toLowerCase(); // Convertimos a minúscula para asegurar el match en el mapa
  return map[char] ?? m[0]!;
})
        .split(RegExp(r'[\s,./()-]+'))
        .where((w) => w.length > 2)
        .toList();
    return [...words, code.toLowerCase()];
  }

  @override
  List<Object?> get props => [id, code, isActive];
}