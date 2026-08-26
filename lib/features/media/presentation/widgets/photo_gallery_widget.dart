// lib/features/media/presentation/widgets/photo_gallery_widget.dart
//
// Widget reutilizable que muestra la galería de fotos de un reporte.
// Se usa dentro de ReportDetailPage y ReportFormPage.
// Permite tomar fotos, subir desde galería, ver en zoom y eliminar.

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/photo_entity.dart';
import '../providers/media_provider.dart';

class PhotoGalleryWidget extends ConsumerWidget {
  final String reportId;
  final bool canEdit;    // false en reportes aprobados o para gerentes

  const PhotoGalleryWidget({
    super.key,
    required this.reportId,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(photoGalleryProvider(reportId));

    // Mostrar errores como SnackBar
    ref.listen<PhotoGalleryState>(
      photoGalleryProvider(reportId),
      (prev, next) {
        if (next.error != null && prev?.error != next.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: AppColors.error,
            ),
          );
          ref.read(photoGalleryProvider(reportId).notifier).clearError();
        }
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── HEADER ──────────────────────────────────────
        Row(
          children: [
            const Icon(Icons.photo_library_outlined,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Evidencias Fotográficas',
              style: AppTextStyles.h3,
            ),
            const Spacer(),
            // Contador de fotos
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.photos.length}/${AppConstants.maxPhotosPerReport}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ─── PROGRESS BAR (mientras sube) ────────────────
        if (state.isUploading)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Subiendo foto... '
                      '${(state.uploadProgress * 100).toInt()}%',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: state.uploadProgress,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

        // ─── GRID DE FOTOS ───────────────────────────────
        if (state.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: state.photos.length +
    (canEdit && state.photos.length < AppConstants.maxPhotosPerReport ? 1 : 0),
            itemBuilder: (context, index) {
              // El último ítem es el botón de agregar
              if (index == state.photos.length) {
                return _AddPhotoButton(
                  reportId: reportId,
                  isDisabled: state.isUploading,
                );
              }
              return _PhotoThumbnail(
                photo: state.photos[index],
                reportId: reportId,
                canDelete: canEdit,
                onTap: () => _openPhotoViewer(
                  context,
                  state.photos,
                  index,
                ),
              );
            },
          ),

        // Estado vacío
        if (!state.isLoading && state.photos.isEmpty && !canEdit)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.no_photography_outlined,
                      size: 48, color: AppColors.textDisabled),
                  const SizedBox(height: 8),
                  Text(
                    'Sin evidencias fotográficas',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _openPhotoViewer(
    BuildContext context,
    List<PhotoEntity> photos,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewerPage(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

// ─── BOTÓN DE AGREGAR FOTO ───────────────────────────────
class _AddPhotoButton extends ConsumerWidget {
  final String reportId;
  final bool isDisabled;

  const _AddPhotoButton({
    required this.reportId,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: isDisabled ? null : () => _showSourceDialog(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled ? AppColors.border : AppColors.primary,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 28,
              color:
                  isDisabled ? AppColors.textDisabled : AppColors.primary,
            ),
            const SizedBox(height: 6),
            Text(
              'Agregar',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDisabled
                    ? AppColors.textDisabled
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSourceDialog(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(photoGalleryProvider(reportId).notifier);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Agregar evidencia', style: AppTextStyles.h3),
              const SizedBox(height: 20),

              // Opción Cámara
              if (!kIsWeb)  // La cámara nativa solo funciona en móvil
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: AppColors.primary),
                  ),
                  title: const Text('Tomar foto'),
                  subtitle: const Text('Usar la cámara del dispositivo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    notifier.takeAndUpload();
                  },
                ),

              // Opción Galería
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppColors.secondary),
                ),
                title: kIsWeb
                    ? const Text('Subir archivo')
                    : const Text('Elegir de galería'),
                subtitle: Text(
                  kIsWeb
                      ? 'Selecciona un archivo de tu computadora'
                      : 'Seleccionar una foto existente',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  notifier.pickAndUpload();
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── MINIATURA DE FOTO ───────────────────────────────────
class _PhotoThumbnail extends ConsumerWidget {
  final PhotoEntity photo;
  final String reportId;
  final bool canDelete;
  final VoidCallback onTap;

  const _PhotoThumbnail({
    required this.photo,
    required this.reportId,
    required this.canDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ─── IMAGEN ────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(),
          ),

          // ─── BOTÓN ELIMINAR ────────────────────────────
          if (canDelete)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _confirmDelete(context, ref),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // ─── INDICADOR LOCAL (pendiente de subir) ──────
          if (photo.isLocal)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.syncPending,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                        size: 10, color: Colors.white),
                    SizedBox(width: 2),
                    Text('Local',
                        style:
                            TextStyle(color: Colors.white, fontSize: 9)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (photo.remoteUrl != null) {
      // Foto subida a Firebase Storage
      return Image.network(
        photo.remoteUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.surfaceVariant,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceVariant,
          child: const Icon(Icons.broken_image_outlined,
              color: AppColors.textDisabled),
        ),
      );
    } else if (photo.localPath != null && !kIsWeb) {
      // Foto local en el dispositivo
      return Image.file(
        File(photo.localPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.surfaceVariant,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    }

    // Placeholder si no hay imagen disponible
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.image_outlined, color: AppColors.textDisabled),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta evidencia? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(photoGalleryProvider(reportId).notifier)
                  .deletePhoto(photo);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ─── VISOR DE FOTOS A PANTALLA COMPLETA ──────────────────
class PhotoViewerPage extends StatefulWidget {
  final List<PhotoEntity> photos;
  final int initialIndex;

  const PhotoViewerPage({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends State<PhotoViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (photo.description != null)
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () => _showPhotoInfo(photo),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          final p = widget.photos[index];
          return InteractiveViewer(
            // Permite zoom hasta 4x con pellizco
            maxScale: 4.0,
            child: Center(
              child: _buildFullImage(p),
            ),
          );
        },
      ),
      // Información de la foto en la parte inferior
      bottomNavigationBar: Container(
        color: Colors.black87,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.white60),
              const SizedBox(width: 4),
              Text(
                photo.location != null ? photo.location.toString() : 'Sin GPS',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const Spacer(),
              const Icon(Icons.access_time, size: 14, color: Colors.white60),
              const SizedBox(width: 4),
              Text(
                '${photo.takenAt.day}/${photo.takenAt.month}/${photo.takenAt.year}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullImage(PhotoEntity photo) {
    if (photo.remoteUrl != null) {
      return Image.network(
        photo.remoteUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.error, color: Colors.white)),
      );
    }
    if (photo.localPath != null && !kIsWeb) {
      return Image.file(
        File(photo.localPath!),
        fit: BoxFit.contain,
      );
    }
    return const Center(
      child: Icon(Icons.image_not_supported, color: Colors.white54, size: 64),
    );
  }

  void _showPhotoInfo(PhotoEntity photo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Info de la foto',
            style: TextStyle(color: Colors.white)),
        content: Text(
          photo.description ?? 'Sin descripción',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}