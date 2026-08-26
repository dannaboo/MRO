// lib/features/reports/presentation/widgets/report_items_widget.dart
//
// Lista los conceptos de un reporte con la opción
// de eliminar cada uno (deslizando a la izquierda).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/report_entity.dart';
import '../providers/report_provider.dart';

class ReportItemsWidget extends ConsumerWidget {
  final String reportId;
  final List<ReportItemEntity> items;
  final bool canEdit;

  const ReportItemsWidget({
    super.key,
    required this.reportId,
    required this.items,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final numFormat = NumberFormat('#,##0.##', 'es_MX');

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.playlist_add_outlined,
                size: 48,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 8),
              Text(
                'Sin conceptos de daño',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (canEdit)
                Text(
                  'Usa el botón "Agregar Concepto" para comenzar',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Encabezado de la tabla
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'Concepto',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'Cantidad',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 90,
                child: Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Lista de ítems
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final tile = _ItemTile(
                item: item,
                currency: currency,
                numFormat: numFormat,
              );

              // Deslizar para eliminar (solo si puede editar)
              if (!canEdit) return tile;

              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppColors.error,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline,
                          color: Colors.white),
                      Text(
                        'Eliminar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (_) => showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Eliminar concepto'),
                    content: Text(
                      '¿Eliminar "${item.conceptCode} - ${item.conceptName}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        onPressed: () =>
                            Navigator.pop(context, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                ),
                onDismissed: (_) async {
                  await ref
                      .read(reportRepositoryProvider)
                      .removeItemFromReport(
                        reportId: reportId,
                        itemId: item.id,
                      );
                  ref.invalidate(
                      reportDetailProvider(reportId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('${item.conceptCode} eliminado'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: tile,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ReportItemEntity item;
  final NumberFormat currency;
  final NumberFormat numFormat;

  const _ItemTile({
    required this.item,
    required this.currency,
    required this.numFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Código del concepto
                Text(
                  item.conceptCode,
                  style: AppTextStyles.code,
                ),
                const SizedBox(height: 2),
                // Nombre completo
                Text(
                  item.conceptName,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Medidas ingresadas
                if (_hasMeasures) ...[
                  const SizedBox(height: 4),
                  Text(
                    _measuresText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
                // Localización del ítem
                if (item.itemKmStart != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 10,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _formatKm(item.itemKmStart!),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.itemBody != null)
                        Text(
                          ' · ${item.itemBody!.displayName}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Cantidad
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  numFormat.format(item.quantity),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
                Text(
                  item.unit,
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          // Subtotal
          SizedBox(
            width: 90,
            child: Text(
              currency.format(item.subtotal),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasMeasures =>
      item.measureLength != null ||
      item.measureWidth != null ||
      item.measureHeight != null ||
      item.measurePieces != null;

  String get _measuresText {
    final parts = <String>[];
    if (item.measureLength != null) {
      parts.add('L: ${item.measureLength}m');
    }
    if (item.measureWidth != null) {
      parts.add('A: ${item.measureWidth}m');
    }
    if (item.measureHeight != null) {
      parts.add('H: ${item.measureHeight}m');
    }
    if (item.measurePieces != null) {
      parts.add('${item.measurePieces} pzas');
    }
    return parts.join(' · ');
  }

  String _formatKm(double km) {
    final whole = km.floor();
    final decimal = ((km - whole) * 1000).round();
    return '$whole+${decimal.toString().padLeft(3, '0')}';
  }
}