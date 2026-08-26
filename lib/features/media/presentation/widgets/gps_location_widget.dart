// lib/features/media/presentation/widgets/gps_location_widget.dart
//
// Widget que muestra el estado del GPS y permite capturar
// la ubicación actual. Se usa en el formulario de nuevo reporte.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../providers/media_provider.dart';

class GpsLocationWidget extends ConsumerWidget {
  // Callback para que el formulario padre reciba la ubicación
  final ValueChanged<GeoLocation?> onLocationCaptured;
  final GeoLocation? currentLocation;

  const GpsLocationWidget({
    super.key,
    required this.onLocationCaptured,
    this.currentLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentLocation != null
            ? AppColors.successLight
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: currentLocation != null
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Icono de estado GPS
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getStatusColor(currentLocation, locationState).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: locationState.isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Icon(
                    currentLocation != null
                        ? Icons.gps_fixed
                        : Icons.gps_not_fixed,
                    color: _getStatusColor(currentLocation, locationState),
                    size: 24,
                  ),
          ),

          const SizedBox(width: 12),

          // Texto de estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentLocation != null
                      ? 'Ubicación capturada'
                      : locationState.error != null
                          ? 'Error de GPS'
                          : 'Sin ubicación',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(currentLocation, locationState),
                  ),
                ),
                if (currentLocation != null)
                  Text(
                    '${currentLocation!.latitude.toStringAsFixed(5)}, '
                    '${currentLocation!.longitude.toStringAsFixed(5)}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else if (locationState.error != null)
                  Text(
                    locationState.error!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                    maxLines: 2,
                  )
                else
                  Text(
                    'Toca el botón para capturar ubicación',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Botón de captura / actualizar
          OutlinedButton(
            onPressed: locationState.isLoading
                ? null
                : () async {
                    final location = await ref
                        .read(locationProvider.notifier)
                        .getLocation();
                    onLocationCaptured(location);
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              side: BorderSide(
                color: currentLocation != null
                    ? AppColors.success
                    : AppColors.primary,
              ),
            ),
            child: Text(
              currentLocation != null ? 'Actualizar' : 'Capturar',
              style: TextStyle(
                fontSize: 13,
                color: currentLocation != null
                    ? AppColors.success
                    : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(
      GeoLocation? location, LocationState locationState) {
    if (locationState.error != null) return AppColors.error;
    if (location != null) return AppColors.success;
    return AppColors.textSecondary;
  }
}