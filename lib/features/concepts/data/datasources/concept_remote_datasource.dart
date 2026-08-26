// lib/features/concepts/data/datasources/concept_remote_datasource.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/concept_model.dart';

abstract class ConceptRemoteDataSource {
  Future<List<ConceptModel>> getAllConcepts();
  Future<List<ConceptModel>> searchConcepts(String query);
  Future<List<ConceptModel>> getConceptsByCategory(String category);
  Future<List<String>> getCategories();
  Future<ConceptModel> getConceptById(String id);
}

class ConceptRemoteDataSourceImpl implements ConceptRemoteDataSource {
  final FirebaseFirestore _firestore;
  ConceptRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _conceptsRef =>
      _firestore.collection(AppConstants.collectionConcepts);

  @override
  Future<List<ConceptModel>> getAllConcepts() async {
    try {
      final snap = await _conceptsRef
          .where('isActive', isEqualTo: true)
          .orderBy('code')
          .get();
      return snap.docs.map((d) => ConceptModel.fromFirestore(d)).toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error al obtener conceptos', code: e.code);
    }
  }

  @override
  Future<List<ConceptModel>> searchConcepts(String query) async {
    try {
      final q = query.toLowerCase().trim();
      if (q.isEmpty) return getAllConcepts();

      // Firestore no soporta full-text search nativamente.
      // Usamos array-contains con los searchTags que generamos.
      // Para búsquedas de más de una palabra, buscamos la primera.
      final firstWord = q.split(' ').first;

      final snap = await _conceptsRef
          .where('isActive', isEqualTo: true)
          .where('searchTags', arrayContains: firstWord)
          .get();

      final results = snap.docs
          .map((d) => ConceptModel.fromFirestore(d))
          .toList();

      // Filtramos en cliente para múltiples palabras
      if (q.contains(' ')) {
        return results
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.code.toLowerCase().contains(q))
            .toList();
      }

      return results;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error en búsqueda', code: e.code);
    }
  }

  @override
  Future<List<ConceptModel>> getConceptsByCategory(String category) async {
    try {
      final snap = await _conceptsRef
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: category)
          .orderBy('code')
          .get();
      return snap.docs.map((d) => ConceptModel.fromFirestore(d)).toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error al filtrar', code: e.code);
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final snap = await _conceptsRef
          .where('isActive', isEqualTo: true)
          .get();
      final categories = snap.docs
          .map((d) => d.data()['category'] as String? ?? '')
          .toSet()
          .where((c) => c.isNotEmpty)
          .toList()
        ..sort();
      return categories;
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error', code: e.code);
    }
  }

  @override
  Future<ConceptModel> getConceptById(String id) async {
    try {
      final doc = await _conceptsRef.doc(id).get();
      if (!doc.exists) {
        throw const ServerException(message: 'Concepto no encontrado');
      }
      return ConceptModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error', code: e.code);
    }
  }
}