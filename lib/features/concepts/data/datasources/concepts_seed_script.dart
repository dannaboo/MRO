// lib/features/concepts/data/datasources/concepts_seed_script.dart
//
// Script que carga el catálogo completo en Firestore.
// Se ejecuta UNA SOLA VEZ desde el panel admin.
// Después el catálogo se actualiza desde la UI.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import 'concepts_seed_data.dart';

class ConceptsSeedScript {
  final FirebaseFirestore _firestore;
  const ConceptsSeedScript(this._firestore);

  // Retorna el número de conceptos cargados
  Future<int> seedConcepts({
    void Function(String message)? onProgress,
  }) async {
    final concepts = ConceptsSeedData.concepts;
    int loaded = 0;

    // Usamos batched writes: Firestore permite máximo 500
    // operaciones por batch. Dividimos en grupos de 100.
    const batchSize = 100;

    for (int i = 0; i < concepts.length; i += batchSize) {
      final batch = _firestore.batch();
      final end =
          (i + batchSize < concepts.length) ? i + batchSize : concepts.length;
      final chunk = concepts.sublist(i, end);

      for (final concept in chunk) {
        final id = const Uuid().v4();
        final docRef = _firestore
            .collection(AppConstants.collectionConcepts)
            .doc(id);

        batch.set(docRef, {
          'id': id,
          'code': concept['code'],
          'name': concept['name'],
          'category': concept['category'],
          'subcategory': concept['subcategory'],
          'unit': concept['unit'],
          'unitPriceWithoutTax': concept['priceWithoutTax'],
          'unitPriceWithTax': concept['priceWithTax'],
          'isActive': true,
          'searchTags': concept['searchTags'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        loaded++;
      }

      await batch.commit();
      onProgress?.call('Cargados $loaded / ${concepts.length} conceptos...');
    }

    return loaded;
  }

  // Verifica si ya existe el catálogo en Firestore
  Future<bool> isCatalogLoaded() async {
    final snapshot = await _firestore
        .collection(AppConstants.collectionConcepts)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}