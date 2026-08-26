// lib/features/concepts/presentation/pages/concept_selector_page.dart
//
// Versión actualizada que usa CalculationEngine
// para mostrar desglose en tiempo real mientras el
// cuadrillero ingresa las medidas.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../calculation/presentation/providers/calculation_provider.dart';
import '../../../calculation/presentation/widgets/calculation_breakdown_widget.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../../../reports/presentation/providers/report_provider.dart';
import '../../domain/entities/concept_entity.dart';

class ConceptSelectorPage extends ConsumerStatefulWidget {
  final ConceptEntity concept;
  final String reportId;

  const ConceptSelectorPage({
    super.key,
    required this.concept,
    required this.reportId,
  });

  @override
  ConsumerState<ConceptSelectorPage> createState() =>
      _ConceptSelectorPageState();
}

class _ConceptSelectorPageState extends ConsumerState<ConceptSelectorPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de medidas
  final _lengthCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _piecesCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();

  // Localización del ítem
  final _kmStartCtrl = TextEditingController();
  final _kmEndCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  RoadBody _itemBody = RoadBody.a;

  bool _isSaving = false;

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _piecesCtrl.dispose();
    _quantityCtrl.dispose();
    _kmStartCtrl.dispose();
    _kmEndCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // Dispara el cálculo en tiempo real
  void _triggerCalculation() {
    ref.read(calculatorProvider(widget.concept).notifier).calculate(
          length: double.tryParse(_lengthCtrl.text),
          width: double.tryParse(_widthCtrl.text),
          height: double.tryParse(_heightCtrl.text),
          pieces: int.tryParse(_piecesCtrl.text),
          quantity: double.tryParse(_quantityCtrl.text),
        );
  }

  Future<void> _addToReport() async {
    if (!_formKey.currentState!.validate()) return;

    final calcState = ref.read(calculatorProvider(widget.concept));
    if (!calcState.hasCalculated || calcState.result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa las medidas para calcular el subtotal'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    FocusScope.of(context).unfocus();

    final result = calcState.result!;

    final item = ReportItemEntity(
      id: const Uuid().v4(),
      conceptId: widget.concept.id,
      conceptCode: widget.concept.code,
      conceptName: widget.concept.name,
      unit: widget.concept.unit.displayName,
      quantity: result.calculatedQuantity,
      unitPrice: result.unitPrice,
      subtotal: result.totalWithTax,
      measureLength: result.inputLength,
      measureWidth: result.inputWidth,
      measureHeight: result.inputHeight,
      measurePieces: result.inputPieces,
      itemKmStart: _kmStartCtrl.text.isNotEmpty
          ? DamageReportEntity.kmFromDisplay(_kmStartCtrl.text)
          : null,
      itemKmEnd: _kmEndCtrl.text.isNotEmpty
          ? DamageReportEntity.kmFromDisplay(_kmEndCtrl.text)
          : null,
      itemBody: _itemBody,
      notes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
    );

    final addResult = await ref
        .read(reportRepositoryProvider)
        .addItemToReport(reportId: widget.reportId, item: item);

    setState(() => _isSaving = false);

    if (!mounted) return;

    addResult.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.error,
        ),
      ),
      (_) {
        // Limpiar el cálculo del provider
        ref.read(calculatorProvider(widget.concept).notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ ${widget.concept.code} agregado al reporte',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final calcState = ref.watch(calculatorProvider(widget.concept));
    final fields = widget.concept.requiredMeasurements;
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Concepto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ─── INFO DEL CONCEPTO ─────────────────────
            _ConceptHeader(
              concept: widget.concept,
              currency: currency,
            ),

            const SizedBox(height: 20),

            // ─── LOCALIZACIÓN DEL ÍTEM ─────────────────
            _SectionTitle(
              icon: Icons.location_on_outlined,
              title: 'Localización del daño',
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kmStartCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d+.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'KM Inicial',
                      hintText: '21+525',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _kmEndCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[\d+.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'KM Final',
                      hintText: '21+530',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Selector de cuerpo
            Row(
              children: RoadBody.values.map((b) {
                final sel = b == _itemBody;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _itemBody = b),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        height: 44,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            b.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ─── MEDIDAS DEL GENERADOR ─────────────────
            _SectionTitle(
              icon: Icons.straighten_outlined,
              title: 'Medidas del generador',
              subtitle: 'Del sheet GENERADORES del tabulador',
            ),
            const SizedBox(height: 12),

            // Campos según la unidad del concepto
            ...fields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _controllerFor(field),
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: field.isDecimal,
                  ),
                  inputFormatters: field.isDecimal
                      ? [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'))
                        ]
                      : [FilteringTextInputFormatter.digitsOnly],
                  // El cálculo se dispara en cada cambio
                  onChanged: (_) => _triggerCalculation(),
                  decoration: InputDecoration(
                    labelText: '${field.label} *',
                    hintText: field.isDecimal ? '0.00' : '0',
                    prefixIcon: Icon(_iconFor(field)),
                    helperText: _helperFor(field, widget.concept.code),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return '${field.label} es requerido';
                    }
                    final n = double.tryParse(v);
                    if (n == null || n <= 0) {
                      return 'Debe ser mayor a 0';
                    }
                    return null;
                  },
                ),
              ),
            ),

            // ─── ERROR DE CÁLCULO ──────────────────────
            if (calcState.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        calcState.error!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ─── RESULTADO DEL CÁLCULO ─────────────────
            if (calcState.hasCalculated && calcState.result != null) ...[
              const SizedBox(height: 16),
              CalculationBreakdownWidget(result: calcState.result!),
            ],

            const SizedBox(height: 16),

            // ─── NOTAS ────────────────────────────────
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Observaciones del daño...',
                prefixIcon: Icon(Icons.note_outlined),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 32),

            // ─── BOTÓN AGREGAR ─────────────────────────
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed:
                    _isSaving || !calcState.hasCalculated
                        ? null
                        : _addToReport,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add_circle_outline),
                label: Text(
                  _isSaving
                      ? 'Agregando...'
                      : !calcState.hasCalculated
                          ? 'Ingresa las medidas para continuar'
                          : 'Agregar al Reporte',
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────

  TextEditingController _controllerFor(MeasurementField field) {
    switch (field) {
      case MeasurementField.length:   return _lengthCtrl;
      case MeasurementField.width:    return _widthCtrl;
      case MeasurementField.height:   return _heightCtrl;
      case MeasurementField.pieces:   return _piecesCtrl;
      case MeasurementField.quantity: return _quantityCtrl;
    }
  }

  IconData _iconFor(MeasurementField field) {
    switch (field) {
      case MeasurementField.length:   return Icons.straighten_outlined;
      case MeasurementField.width:    return Icons.width_normal_outlined;
      case MeasurementField.height:   return Icons.height_outlined;
      case MeasurementField.pieces:   return Icons.tag_outlined;
      case MeasurementField.quantity: return Icons.calculate_outlined;
    }
  }

  // Texto de ayuda contextual según el concepto
  String? _helperFor(MeasurementField field, String conceptCode) {
    if (field == MeasurementField.length) {
      switch (conceptCode) {
        case 'C.1.1':
        case 'C.1.2':
          return 'Metros lineales de defensa dañada. Tramos de 3.81 m c/u';
        case 'E.1.1':
          return 'Metros lineales de barandal. Tramos de 2.0 m c/u';
        case 'A.1.1':
        case 'A.1.2':
        case 'A.2.1':
          return 'Metros lineales de raya';
      }
    }
    if (field == MeasurementField.width) {
      if (conceptCode.startsWith('D.')) {
        return 'Ancho del área de bacheo (generalmente 1 carril = 3.5 m)';
      }
    }
    return null;
  }
}

// ─── WIDGETS AUXILIARES ──────────────────────────────────

class _ConceptHeader extends StatelessWidget {
  final ConceptEntity concept;
  final NumberFormat currency;

  const _ConceptHeader({required this.concept, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  concept.code,
                  style: AppTextStyles.code.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  concept.category,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(concept.name, style: AppTextStyles.h3),
          const SizedBox(height: 10),
          Row(
            children: [
              _InfoChip(
                concept.unit.displayName,
                Icons.straighten_outlined,
              ),
              const SizedBox(width: 8),
              _InfoChip(
                '${currency.format(concept.unitPriceWithTax)} c/IVA',
                Icons.attach_money,
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoChip(this.label, this.icon,
      {this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h3),
            if (subtitle != null)
              Text(subtitle!, style: AppTextStyles.bodySmall),
          ],
        ),
      ],
    );
  }
}