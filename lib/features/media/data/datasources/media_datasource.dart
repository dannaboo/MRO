// lib/features/media/data/datasources/media_datasource.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/photo_entity.dart';         
import '../../../reports/domain/entities/report_entity.dart';
import '../models/photo_model.dart';

abstract class MediaDataSource {
  Future<String?> takePhoto();
  Future<String?> pickFromGallery();
  Future<PhotoModel> uploadPhoto({
    required String reportId,
    required String localPath,
    required String uploadedBy,
    required String uploadedByName,
    String? description,
    GeoLocation? location,
    required int order,
    void Function(double)? onProgress,
  });
  Future<List<PhotoModel>> getReportPhotos(String reportId);
  Future<void> deletePhoto({
    required String reportId,
    required String photoId,
    required String remoteUrl,
  });
  Future<GeoLocation> getCurrentLocation();
}

class MediaDataSourceImpl implements MediaDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  MediaDataSourceImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    ImagePicker? picker,
  })  : _firestore = firestore,
        _storage = storage,
        _picker = picker ?? ImagePicker();

  @override
  Future<String?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,     // Comprime al 85% para no desperdiciar Storage
        maxWidth: 2048,       // Máximo 2K para buena calidad sin ser enorme
        maxHeight: 2048,
      );
      return photo?.path;
    } catch (e) {
      throw PermissionException(
        message: 'No se pudo acceder a la cámara. '
            'Verifica los permisos en configuración.',
      );
    }
  }

  @override
  Future<String?> pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      return photo?.path;
    } catch (e) {
      throw PermissionException(
        message: 'No se pudo acceder a la galería. '
            'Verifica los permisos.',
      );
    }
  }

  @override
  Future<PhotoModel> uploadPhoto({
    required String reportId,
    required String localPath,
    required String uploadedBy,
    required String uploadedByName,
    String? description,
    GeoLocation? location,
    required int order,
    void Function(double)? onProgress,
  }) async {
    try {
      final photoId = const Uuid().v4();
      // Estructura en Storage: reports/{reportId}/photos/{photoId}.jpg
      final storageRef = _storage
          .ref()
          .child('reports')
          .child(reportId)
          .child('photos')
          .child('$photoId.jpg');

      UploadTask uploadTask;

      if (kIsWeb) {
        // En web, image_picker devuelve una URL de blob, no un path de archivo.
        // Necesitamos leer los bytes directamente del XFile.
        // El localPath en web es en realidad una URL temporal.
        final xFile = XFile(localPath);
        final bytes = await xFile.readAsBytes();
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        // En móvil, el localPath es una ruta real del sistema de archivos
        uploadTask = storageRef.putFile(
          File(localPath),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      // Escuchar el progreso de la subida
      uploadTask.snapshotEvents.listen((snapshot) {
        if (onProgress != null && snapshot.totalBytes > 0) {
          final progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });

      // Esperar a que termine la subida
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Guardar metadatos en Firestore
      final photoModel = PhotoModel(
        id: photoId,
        reportId: reportId,
        localPath: kIsWeb ? null : localPath,
        remoteUrl: downloadUrl,
        description: description,
        location: location,
        takenAt: DateTime.now(),
        takenBy: uploadedBy,
        takenByName: uploadedByName,
        uploadStatus: PhotoUploadStatus.uploaded,
        order: order,
      );

      await _firestore
          .collection(AppConstants.collectionReports)
          .doc(reportId)
          .collection(AppConstants.subCollectionPhotos)
          .doc(photoId)
          .set(photoModel.toFirestore());

      // Actualizamos el contador de fotos en el reporte principal
      await _firestore
          .collection(AppConstants.collectionReports)
          .doc(reportId)
          .update({
        'photoCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return photoModel;
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Error al subir la foto',
        code: e.code,
      );
    } catch (e) {
      throw ServerException(message: 'Error inesperado al subir foto: $e');
    }
  }

  @override
  Future<List<PhotoModel>> getReportPhotos(String reportId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionReports)
          .doc(reportId)
          .collection(AppConstants.subCollectionPhotos)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => PhotoModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Error al obtener fotos',
        code: e.code,
      );
    }
  }

  @override
  Future<void> deletePhoto({
    required String reportId,
    required String photoId,
    required String remoteUrl,
  }) async {
    try {
      // Eliminar de Storage
      await _storage.refFromURL(remoteUrl).delete();

      // Eliminar de Firestore
      await _firestore
          .collection(AppConstants.collectionReports)
          .doc(reportId)
          .collection(AppConstants.subCollectionPhotos)
          .doc(photoId)
          .delete();

      // Actualizar contador
      await _firestore
          .collection(AppConstants.collectionReports)
          .doc(reportId)
          .update({
        'photoCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ServerException(
        message: e.message ?? 'Error al eliminar foto',
        code: e.code,
      );
    }
  }

  @override
  Future<GeoLocation> getCurrentLocation() async {
    try {
      // Verificar si el servicio GPS está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const PermissionException(
          message: 'El GPS está desactivado. Actívalo en la configuración.',
        );
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw const PermissionException(
            message: 'Permiso de ubicación denegado.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw const PermissionException(
          message: 'Permiso de ubicación denegado permanentemente. '
              'Habilítalo en la configuración del dispositivo.',
        );
      }

      // Obtener posición actual con timeout de 30 segundos
      final position = await Geolocator.getCurrentPosition(
  locationSettings: LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: AppConstants.gpsTimeoutSeconds),
  ),
);

      return GeoLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } on PermissionException {
      rethrow;
    } catch (e) {
      throw PermissionException(
        message: 'No se pudo obtener la ubicación: $e',
      );
    }
  }
}