// lib/features/reports/data/datasources/report_local_datasource.dart
//
// Almacenamiento local con Hive para modo offline.
// Guarda reportes como Map<String, dynamic> serializado en JSON.
// Cuando hay internet, el repositorio sincroniza los pendientes.

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/report_entity.dart';
import '../models/report_model.dart';

abstract class ReportLocalDataSource {
  Future<void> cacheReport(DamageReportModel report);
  Future<List<DamageReportModel>> getCachedReports({String? userId});
  Future<DamageReportModel?> getCachedReportById(String id);
  Future<void> deleteReport(String id);
  Future<List<DamageReportModel>> getPendingReports(); // Solo los no sincronizados
  Future<void> clearCache();
}

class ReportLocalDataSourceImpl implements ReportLocalDataSource {
  // La caja de Hive se abre una vez y se reutiliza.
  // Es lazy: se abre la primera vez que se necesita.
  Box<String>? _box;

  Future<Box<String>> get _reportsBox async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(AppConstants.hiveBoxReports);
    return _box!;
  }

  @override
  Future<void> cacheReport(DamageReportModel report) async {
    try {
      final box = await _reportsBox;
      // Guardamos como JSON string con el ID como clave
      await box.put(report.id, jsonEncode(report.toMap()));
    } catch (e) {
      throw CacheException(message: 'Error al guardar reporte local: $e');
    }
  }

  @override
  Future<List<DamageReportModel>> getCachedReports({String? userId}) async {
    try {
      final box = await _reportsBox;
      final reports = box.values
          .map((jsonStr) => DamageReportModel.fromMap(
                jsonDecode(jsonStr) as Map<String, dynamic>,
              ))
          .toList();

      // Filtramos por usuario si se especifica
      final filtered = userId != null
          ? reports.where((r) => r.createdBy == userId).toList()
          : reports;

      // Ordenamos por fecha de creación, más recientes primero
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    } catch (e) {
      throw CacheException(message: 'Error al leer reportes locales: $e');
    }
  }

  @override
  Future<DamageReportModel?> getCachedReportById(String id) async {
    try {
      final box = await _reportsBox;
      final jsonStr = box.get(id);
      if (jsonStr == null) return null;
      return DamageReportModel.fromMap(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (e) {
      throw CacheException(message: 'Error al leer reporte local: $e');
    }
  }

  @override
  Future<void> deleteReport(String id) async {
    try {
      final box = await _reportsBox;
      await box.delete(id);
    } catch (e) {
      throw CacheException(message: 'Error al eliminar reporte local: $e');
    }
  }

  @override
  Future<List<DamageReportModel>> getPendingReports() async {
    try {
      final all = await getCachedReports();
      return all
          .where((r) => r.syncStatus == SyncStatus.pending)
          .toList();
    } catch (e) {
      throw CacheException(message: 'Error al obtener pendientes: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    final box = await _reportsBox;
    await box.clear();
  }
}