// lib/features/concepts/data/models/concept_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/concept_entity.dart';

class ConceptModel extends ConceptEntity {
  const ConceptModel({
    required super.id,
    required super.code,
    required super.name,
    required super.category,
    super.subcategory,
    required super.unit,
    required super.unitPriceWithoutTax,
    required super.unitPriceWithTax,
    super.description,
    super.isActive,
    super.searchTags,
  });

  factory ConceptModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ConceptModel(
      id: doc.id,
      code: d['code'] as String? ?? '',
      name: d['name'] as String? ?? '',
      category: d['category'] as String? ?? '',
      subcategory: d['subcategory'] as String?,
      unit: MeasurementUnit.fromString(d['unit'] as String? ?? 'pza'),
      unitPriceWithoutTax:
          (d['unitPriceWithoutTax'] as num?)?.toDouble() ?? 0,
      unitPriceWithTax:
          (d['unitPriceWithTax'] as num?)?.toDouble() ?? 0,
      description: d['description'] as String?,
      isActive: d['isActive'] as bool? ?? true,
      searchTags: List<String>.from(d['searchTags'] as List? ?? []),
    );
  }

  factory ConceptModel.fromMap(Map<String, dynamic> d) {
    return ConceptModel(
      id: d['id'] as String,
      code: d['code'] as String? ?? '',
      name: d['name'] as String? ?? '',
      category: d['category'] as String? ?? '',
      subcategory: d['subcategory'] as String?,
      unit: MeasurementUnit.fromString(d['unit'] as String? ?? 'pza'),
      unitPriceWithoutTax:
          (d['unitPriceWithoutTax'] as num?)?.toDouble() ?? 0,
      unitPriceWithTax:
          (d['unitPriceWithTax'] as num?)?.toDouble() ?? 0,
      description: d['description'] as String?,
      isActive: d['isActive'] as bool? ?? true,
      searchTags: List<String>.from(d['searchTags'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'code': code,
        'name': name,
        'category': category,
        'subcategory': subcategory,
        'unit': unit.value,
        'unitPriceWithoutTax': unitPriceWithoutTax,
        'unitPriceWithTax': unitPriceWithTax,
        'description': description,
        'isActive': isActive,
        'searchTags': searchTags,
      };
}