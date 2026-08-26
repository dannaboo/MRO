// lib/features/media/presentation/providers/media_provider.dart


import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../../data/datasources/media_datasource.dart';
import '../../data/repositories/media_repository_impl.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/repositories/media_repository.dart';
import '../../domain/usecases/get_location_usecase.dart';
import '../../domain/usecases/upload_photo_usecase.dart';

// ─── PROVIDERS DE INFRAESTRUCTURA ───────────────────────

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final mediaDataSourceProvider = Provider<MediaDataSource>((ref) {
  return MediaDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  );
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepositoryImpl(
    dataSource: ref.watch(mediaDataSourceProvider),
  );
});

final uploadPhotoUseCaseProvider = Provider<UploadPhotoUseCase>((ref) {
  return UploadPhotoUseCase(ref.watch(mediaRepositoryProvider));
});

final getLocationUseCaseProvider = Provider<GetLocationUseCase>((ref) {
  return GetLocationUseCase(ref.watch(mediaRepositoryProvider));
});

// ─── ESTADO DE GALERÍA DE FOTOS ──────────────────────────

class PhotoGalleryState {
  final List<PhotoEntity> photos;
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;     // 0.0 a 1.0
  final String? error;

  const PhotoGalleryState({
    this.photos = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.error,
  });

  PhotoGalleryState copyWith({
    List<PhotoEntity>? photos,
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    String? error,
  }) {
    return PhotoGalleryState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error,
    );
  }
}

class PhotoGalleryNotifier extends FamilyNotifier<PhotoGalleryState, String> {
  // arg = reportId

  @override
  PhotoGalleryState build(String arg) {
    Future.microtask(() => loadPhotos());
    return const PhotoGalleryState(isLoading: true);
  }

  Future<void> loadPhotos() async {
    state = state.copyWith(isLoading: true);
    final result = await ref
        .read(mediaRepositoryProvider)
        .getReportPhotos(arg);

    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (photos) => state = state.copyWith(isLoading: false, photos: photos),
    );
  }

  // Toma una foto con la cámara y la sube
  Future<bool> takeAndUpload({
    String? description,
    GeoLocation? location,
  }) async {
    // Paso 1: abrir cámara
    final cameraResult =
        await ref.read(mediaRepositoryProvider).takePhoto();

    return cameraResult.fold(
      (f) {
        state = state.copyWith(error: f.message);
        return false;
      },
      (localPath) => _uploadFromPath(
        localPath: localPath,
        description: description,
        location: location,
      ),
    );
  }

  // Selecciona de galería y sube
  Future<bool> pickAndUpload({
    String? description,
    GeoLocation? location,
  }) async {
    final galleryResult =
        await ref.read(mediaRepositoryProvider).pickFromGallery();

    return galleryResult.fold(
      (f) {
        state = state.copyWith(error: f.message);
        return false;
      },
      (localPath) => _uploadFromPath(
        localPath: localPath,
        description: description,
        location: location,
      ),
    );
  }

  Future<bool> _uploadFromPath({
    required String localPath,
    String? description,
    GeoLocation? location,
  }) async {
    final user = ref.read(currentUserProvider)!;
    state = state.copyWith(isUploading: true, uploadProgress: 0);

    final result = await ref.read(uploadPhotoUseCaseProvider).call(
          UploadPhotoParams(
            reportId: arg,
            localPath: localPath,
            uploadedBy: user.uid,
            uploadedByName: user.displayName,
            description: description,
            location: location,
            order: state.photos.length,
            onProgress: (p) {
              state = state.copyWith(uploadProgress: p);
            },
          ),
        );

    return result.fold(
      (f) {
        state = state.copyWith(isUploading: false, error: f.message);
        return false;
      },
      (photo) {
        state = state.copyWith(
          isUploading: false,
          uploadProgress: 1.0,
          photos: [...state.photos, photo],
        );
        return true;
      },
    );
  }

  Future<bool> deletePhoto(PhotoEntity photo) async {
    if (photo.remoteUrl == null) return false;

    final result = await ref.read(mediaRepositoryProvider).deletePhoto(
          reportId: arg,
          photoId: photo.id,
          remoteUrl: photo.remoteUrl!,
        );

    return result.fold(
      (f) {
        state = state.copyWith(error: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          photos: state.photos.where((p) => p.id != photo.id).toList(),
        );
        return true;
      },
    );
  }

  void clearError() => state = state.copyWith(error: null);
}

final photoGalleryProvider =
    NotifierProviderFamily<PhotoGalleryNotifier, PhotoGalleryState, String>(
  () => PhotoGalleryNotifier(),
);

// ─── PROVIDER DE GPS ─────────────────────────────────────

class LocationState {
  final GeoLocation? location;
  final bool isLoading;
  final String? error;

  const LocationState({this.location, this.isLoading = false, this.error});

  LocationState copyWith({
    GeoLocation? location,
    bool? isLoading,
    String? error,
  }) =>
      LocationState(
        location: location ?? this.location,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  Future<GeoLocation?> getLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ref.read(getLocationUseCaseProvider).call();

    return result.fold(
      (f) {
        state = state.copyWith(isLoading: false, error: f.message);
        return null;
      },
      (location) {
        state = state.copyWith(isLoading: false, location: location);
        return location;
      },
    );
  }

  void clearError() => state = state.copyWith(error: null);
}

final locationProvider =
    NotifierProvider<LocationNotifier, LocationState>(() => LocationNotifier());