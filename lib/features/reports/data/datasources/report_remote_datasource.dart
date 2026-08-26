// lib/features/reports/data/datasources/report_remote_datasource.dart
//
// Toda la comunicación con Firestore para reportes.
// Gestiona la sub-colección "items" dentro de cada reporte.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/report_entity.dart';
import '../models/report_model.dart';

abstract class ReportRemoteDataSource {
  Future<DamageReportModel> createReport(DamageReportModel report);
  Future<List<DamageReportModel>> getReports({
    String? userId,
    ReportStatus? status,
    int limit,
  });
  Future<DamageReportModel> getReportById(String id);
  Stream<List<DamageReportModel>> watchReports({String? userId, ReportStatus? status});
  Future<DamageReportModel> updateReport(DamageReportModel report);
  Future<DamageReportModel> submitReport(String reportId);
  Future<DamageReportModel> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? rejectionReason,
  });
  Future<DamageReportModel> addItemToReport({
    required String reportId,
    required ReportItemModel item,
  });
  Future<DamageReportModel> removeItemFromReport({
    required String reportId,
    required String itemId,
  });
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final FirebaseFirestore _firestore;

  ReportRemoteDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // Referencia a la colección de reportes
  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _firestore.collection(AppConstants.collectionReports);

  @override
  Future<DamageReportModel> createReport(DamageReportModel report) async {
    try {
      final data = report.toFirestore();
      // Usamos el ID generado localmente para poder referenciarlo offline
      await _reportsRef.doc(report.id).set(data);

      // Retornamos el reporte marcado como sincronizado
      return DamageReportModel.fromMap(
        report.toMap()..['syncStatus'] = SyncStatus.synced.value,
      );
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error al crear reporte', code: e.code);
    }
  }

  @override
  Future<List<DamageReportModel>> getReports({
    String? userId,
    ReportStatus? status,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _reportsRef;

      // Si hay userId, filtramos por cuadrillero
      if (userId != null) {
        query = query.where('createdBy', isEqualTo: userId);
      }
      // Si hay filtro de estado
      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      // Ordenamos por fecha de creación, más recientes primero
      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => DamageReportModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error al obtener reportes', code: e.code);
    }
  }

  @override
  Future<DamageReportModel> getReportById(String id) async {
    try {
      final doc = await _reportsRef.doc(id).get();
      if (!doc.exists) {
        throw const ServerException(message: 'Reporte no encontrado', code: 'not-found');
      }
      return DamageReportModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error al obtener reporte', code: e.code);
    }
  }

  @override
  Stream<List<DamageReportModel>> watchReports({
    String? userId,
    ReportStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _reportsRef;

    if (userId != null) {
      query = query.where('createdBy', isEqualTo: userId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    query = query.orderBy('createdAt', descending: true).limit(50);

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => DamageReportModel.fromFirestore(doc))
        .toList());
  }

  @override
  Future<DamageReportModel> updateReport(DamageReportModel report) async {
    try {
      final data = report.toFirestore();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _reportsRef.doc(report.id).update(data);
      return await getReportById(report.id);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error al actualizar', code: e.code);
    }
  }

  @override
  Future<DamageReportModel> submitReport(String reportId) async {
    try {
      await _reportsRef.doc(reportId).update({
        'status': ReportStatus.submitted.value,
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return await getReportById(reportId);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error al enviar reporte', code: e.code);
    }
  }

  @override
  Future<DamageReportModel> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? rejectionReason,
  }) async {
    try {
      final update = <String, dynamic>{
        'status': newStatus.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (newStatus == ReportStatus.rejected && rejectionReason != null) {
        update['rejectionReason'] = rejectionReason;
      }
      if (newStatus == ReportStatus.approved) {
        update['approvedAt'] = FieldValue.serverTimestamp();
      }
      await _reportsRef.doc(reportId).update(update);
      return await getReportById(reportId);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error al cambiar estado', code: e.code);
    }
  }

  @override
  Future<DamageReportModel> addItemToReport({
    required String reportId,
    required ReportItemModel item,
  }) async {
    try {
      // Usamos arrayUnion para agregar el ítem sin sobrescribir los existentes
      await _reportsRef.doc(reportId).update({
        'items': FieldValue.arrayUnion([item.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Recalculamos totales
      final report = await getReportById(reportId);
      final newSubtotal = report.items.fold<double>(0, (s, i) => s + i.subtotal);
      final newTax = newSubtotal * 0.16;
      final newTotal = newSubtotal + newTax;

      await _reportsRef.doc(reportId).update({
        'subtotal': newSubtotal,
        'tax': newTax,
        'total': newTotal,
      });

      return await getReportById(reportId);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error al agregar concepto', code: e.code);
    }
  }

  @override
  Future<DamageReportModel> removeItemFromReport({
    required String reportId,
    required String itemId,
  }) async {
    try {
      final report = await getReportById(reportId);
      final updatedItems = report.items
          .where((i) => i.id != itemId)
          .map((i) => (i as ReportItemModel).toMap())
          .toList();

      final newSubtotal = report.items
          .where((i) => i.id != itemId)
          .fold<double>(0, (s, i) => s + i.subtotal);
      final newTax = newSubtotal * 0.16;

      await _reportsRef.doc(reportId).update({
        'items': updatedItems,
        'subtotal': newSubtotal,
        'tax': newTax,
        'total': newSubtotal + newTax,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return await getReportById(reportId);
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Error al eliminar concepto', code: e.code);
    }
  }
}