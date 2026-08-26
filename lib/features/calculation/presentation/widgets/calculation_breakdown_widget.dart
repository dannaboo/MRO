// lib/features/calculation/presentation/widgets/calculation_breakdown_widget.dart
//
// Muestra el desglose completo de un cálculo:
// - Cada componente con su cantidad, costo unitario y subtotal
// - Totales: sin IVA, IVA, con IVA
// Diseñado para parecer una mini-factura profesional.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/calculation_entity.dart';

class CalculationBreakdownWidget extends StatelessWidget {
  final CalculationResult result;
  final bool showComponents; // false en vista resumida

  const CalculationBreakdownWidget({
    super.key,
    required this.result,
    this.showComponents = true,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final numFormat = NumberFormat('#,##0.##', 'es_MX');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── HEADER ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calculate_outlined,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resultado del cálculo',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const Spacer(),
                // Badge con la cantidad calculada
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${numFormat.format(result.calculatedQuantity)} ${result.unit}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── MEDIDAS INGRESADAS ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medidas ingresadas:', style: AppTextStyles.label),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (result.inputLength != null)
                      _MeasureBadge(
                        'Largo',
                        '${numFormat.format(result.inputLength!)} m',
                      ),
                    if (result.inputWidth != null)
                      _MeasureBadge(
                        'Ancho',
                        '${numFormat.format(result.inputWidth!)} m',
                      ),
                    if (result.inputHeight != null)
                      _MeasureBadge(
                        'Alto',
                        '${numFormat.format(result.inputHeight!)} m',
                      ),
                    if (result.inputPieces != null)
                      _MeasureBadge(
                        'Piezas',
                        '${result.inputPieces}',
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ─── DESGLOSE DE COMPONENTES ─────────────────
          if (showComponents && result.hasComponents) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Desglose de componentes:',
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: 8),

                  // Encabezado de la tabla
                  _TableHeader(),

                  const Divider(height: 8),

                  // Filas de componentes
                  ...result.components.map(
                    (c) => _ComponentRow(
                      component: c,
                      currency: currency,
                      numFormat: numFormat,
                    ),
                  ),

                  const Divider(height: 8),

                  // Nota explicativa
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.infoLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'El precio final usa el tabulador MRO '
                            '(ya negociado con la aseguradora).',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ─── TOTALES ──────────────────────────────────
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _TotalRow(
                  label:
                      '${numFormat.format(result.calculatedQuantity)} ${result.unit} × ${currency.format(result.unitPrice)}',
                  value: currency.format(result.totalWithTax),
                  isSubtotal: true,
                ),
                const SizedBox(height: 4),
                _TotalRow(
                  label: 'Subtotal sin IVA:',
                  value: currency.format(result.subtotalWithoutTax),
                ),
                _TotalRow(
                  label: 'IVA (16%):',
                  value: currency.format(result.taxAmount),
                  valueColor: AppColors.textSecondary,
                ),
                const Divider(height: 12),
                _TotalRow(
                  label: 'TOTAL CON IVA:',
                  value: currency.format(result.totalWithTax),
                  isBold: true,
                  valueColor: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WIDGETS AUXILIARES ──────────────────────────────────

class _MeasureBadge extends StatelessWidget {
  final String label;
  final String value;
  const _MeasureBadge(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text('Concepto', style: AppTextStyles.label),
        ),
        SizedBox(
          width: 60,
          child: Text(
            'Cant.',
            style: AppTextStyles.label,
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(
          width: 70,
          child: Text(
            'P.U.',
            style: AppTextStyles.label,
            textAlign: TextAlign.right,
          ),
        ),
        SizedBox(
          width: 80,
          child: Text(
            'Importe',
            style: AppTextStyles.label,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ComponentRow extends StatelessWidget {
  final CalculationComponent component;
  final NumberFormat currency;
  final NumberFormat numFormat;

  const _ComponentRow({
    required this.component,
    required this.currency,
    required this.numFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (component.formula != null)
                  Text(
                    component.formula!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              '${numFormat.format(component.quantity)} ${component.unit}',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              currency.format(component.unitCost),
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              currency.format(component.subtotal),
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isSubtotal;
  final Color? valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isSubtotal = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: isSubtotal
                  ? AppTextStyles.bodySmall
                  : isBold
                      ? AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        )
                      : AppTextStyles.bodyMedium,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight:
                  isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ??
                  (isBold
                      ? AppColors.success
                      : AppColors.textPrimary),
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}