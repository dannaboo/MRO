// lib/features/media/domain/entities/photo_entity.dart
//
// Representa una fotografía de evidencia asociada a un reporte.
// Puede estar en 3 estados:
// - local: solo en el dispositivo (pendiente de subir)
// - uploading: subiéndose a Firebase Storage
// - uploaded: ya en la nube con URL pública

import 'package:equatable/equatable.dart';
import '../../../reports/domain/entities/report_entity.dart';

enum PhotoUploadStatus {
  local,      // Solo en el dispositivo
  uploading,  // Subiendo ahora mismo
  uploaded,   // Disponible en Firebase Storage
  error;      // Falló la subida

  String get value => name;
  static PhotoUploadStatus fromString(String v) =>
      PhotoUploadStatus.values.firstWhere((e) => e.value == v,
          orElse: () => PhotoUploadStatus.local);
}

class PhotoEntity extends Equatable {
  final String id;
  final String reportId;

  // Ruta local en el dispositivo (mientras no se sube)
  // null si solo existe en la nube
  final String? localPath;

  // URL de Firebase Storage (disponible después de subir)
  final String? remoteUrl;

  // URL de miniatura (generada por Cloud Function, Fase posterior)
  final String? thumbnailUrl;

  // Descripción que el cuadrillero agrega a la foto
  final String? description;

  // Coordenadas donde se tomó la foto
  final GeoLocation? location;

  // Cuándo se tomó
  final DateTime takenAt;

  // Quién la tomó
  final String takenBy;
  final String takenByName;

  // Estado de sincronización
  final PhotoUploadStatus uploadStatus;

  // Orden de la foto en la galería
  final int order;

  const PhotoEntity({
    required this.id,
    required this.reportId,
    this.localPath,
    this.remoteUrl,
    this.thumbnailUrl,
    this.description,
    this.location,
    required this.takenAt,
    required this.takenBy,
    required this.takenByName,
    required this.uploadStatus,
    required this.order,
  });

  bool get isLocal => uploadStatus == PhotoUploadStatus.local;
  bool get isUploaded => uploadStatus == PhotoUploadStatus.uploaded;
  bool get isUploading => uploadStatus == PhotoUploadStatus.uploading;

  // URL para mostrar: prefiere la remota, cae en la local
  String? get displayUrl => remoteUrl ?? localPath;

  PhotoEntity copyWith({
    String? id,
    String? reportId,
    String? localPath,
    String? remoteUrl,
    String? thumbnailUrl,
    String? description,
    GeoLocation? location,
    DateTime? takenAt,
    String? takenBy,
    String? takenByName,
    PhotoUploadStatus? uploadStatus,
    int? order,
  }) {
    return PhotoEntity(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
      location: location ?? this.location,
      takenAt: takenAt ?? this.takenAt,
      takenBy: takenBy ?? this.takenBy,
      takenByName: takenByName ?? this.takenByName,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => [id, reportId, uploadStatus, remoteUrl];
}