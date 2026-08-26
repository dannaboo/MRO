// lib/features/concepts/data/datasources/concept_local_datasource.dart
//
// Cachea el catálogo completo en Hive para modo offline.
// El catálogo cambia poco, así que una descarga semanal es suficiente.

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/concept_model.dart';

abstract class ConceptLocalDataSource {
  Future<void> cacheConcepts(List<ConceptModel> concepts);
  Future<List<ConceptModel>> getCachedConcepts();
  Future<List<ConceptModel>> searchLocal(String query);
  Future<bool> hasCachedConcepts();
}

class ConceptLocalDataSourceImpl implements ConceptLocalDataSource {
  Box<String>? _box;

  Future<Box<String>> get _conceptsBox async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(AppConstants.hiveBoxConcepts);
    return _box!;
  }

  @override
  Future<void> cacheConcepts(List<ConceptModel> concepts) async {
    try {
      final box = await _conceptsBox;
      await box.clear();
      final Map<String, String> entries = {};
      for (final c in concepts) {
        entries[c.id] = jsonEncode({
          'id': c.id,
          'code': c.code,
          'name': c.name,
          'category': c.category,
          'subcategory': c.subcategory,
          'unit': c.unit.value,
          'unitPriceWithoutTax': c.unitPriceWithoutTax,
          'unitPriceWithTax': c.unitPriceWithTax,
          'isActive': c.isActive,
          'searchTags': c.searchTags,
        });
      }
      await box.putAll(entries);
    } catch (e) {
      throw CacheException(message: 'Error al cachear conceptos: $e');
    }
  }

  @override
  Future<List<ConceptModel>> getCachedConcepts() async {
    try {
      final box = await _conceptsBox;
      return box.values
          .map((json) => ConceptModel.fromMap(
                jsonDecode(json) as Map<String, dynamic>,
              ))
          .where((c) => c.isActive)
          .toList()
        ..sort((a, b) => a.code.compareTo(b.code));
    } catch (e) {
      throw CacheException(message: 'Error al leer conceptos: $e');
    }
  }

  @override
  Future<List<ConceptModel>> searchLocal(String query) async {
    final all = await getCachedConcepts();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return all;

    return all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q) ||
          c.searchTags.any((t) => t.contains(q));
    }).toList();
  }

  @override
  Future<bool> hasCachedConcepts() async {
    final box = await _conceptsBox;
    return box.isNotEmpty;
  }
}