// lib/features/media/data/models/photo_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/photo_entity.dart';
import '../../../reports/domain/entities/report_entity.dart';

class PhotoModel extends PhotoEntity {
  const PhotoModel({
    required super.id,
    required super.reportId,
    super.localPath,
    super.remoteUrl,
    super.thumbnailUrl,
    super.description,
    super.location,
    required super.takenAt,
    required super.takenBy,
    required super.takenByName,
    required super.uploadStatus,
    required super.order,
  });

  factory PhotoModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PhotoModel(
      id: doc.id,
      reportId: d['reportId'] as String? ?? '',
      localPath: d['localPath'] as String?,
      remoteUrl: d['remoteUrl'] as String?,
      thumbnailUrl: d['thumbnailUrl'] as String?,
      description: d['description'] as String?,
      location: d['location'] != null
          ? GeoLocation(
              latitude: (d['location']['latitude'] as num).toDouble(),
              longitude: (d['location']['longitude'] as num).toDouble(),
              accuracy: (d['location']['accuracy'] as num?)?.toDouble(),
            )
          : null,
      takenAt: (d['takenAt'] as Timestamp).toDate(),
      takenBy: d['takenBy'] as String? ?? '',
      takenByName: d['takenByName'] as String? ?? '',
      uploadStatus: PhotoUploadStatus.fromString(
          d['uploadStatus'] as String? ?? 'uploaded'),
      order: d['order'] as int? ?? 0,
    );
  }

  factory PhotoModel.fromMap(Map<String, dynamic> d) {
    return PhotoModel(
      id: d['id'] as String,
      reportId: d['reportId'] as String? ?? '',
      localPath: d['localPath'] as String?,
      remoteUrl: d['remoteUrl'] as String?,
      thumbnailUrl: d['thumbnailUrl'] as String?,
      description: d['description'] as String?,
      location: d['location'] != null
          ? GeoLocation(
              latitude: (d['location']['latitude'] as num).toDouble(),
              longitude: (d['location']['longitude'] as num).toDouble(),
            )
          : null,
      takenAt: DateTime.parse(d['takenAt'] as String),
      takenBy: d['takenBy'] as String? ?? '',
      takenByName: d['takenByName'] as String? ?? '',
      uploadStatus: PhotoUploadStatus.fromString(
          d['uploadStatus'] as String? ?? 'local'),
      order: d['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'reportId': reportId,
        'localPath': localPath,
        'remoteUrl': remoteUrl,
        'thumbnailUrl': thumbnailUrl,
        'description': description,
        'location': location != null
            ? {
                'latitude': location!.latitude,
                'longitude': location!.longitude,
                'accuracy': location!.accuracy,
              }
            : null,
        'takenAt': Timestamp.fromDate(takenAt),
        'takenBy': takenBy,
        'takenByName': takenByName,
        'uploadStatus': uploadStatus.value,
        'order': order,
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'reportId': reportId,
        'localPath': localPath,
        'remoteUrl': remoteUrl,
        'thumbnailUrl': thumbnailUrl,
        'description': description,
        'location': location != null
            ? {
                'latitude': location!.latitude,
                'longitude': location!.longitude,
                'accuracy': location!.accuracy,
              }
            : null,
        'takenAt': takenAt.toIso8601String(),
        'takenBy': takenBy,
        'takenByName': takenByName,
        'uploadStatus': uploadStatus.value,
        'order': order,
      };
}