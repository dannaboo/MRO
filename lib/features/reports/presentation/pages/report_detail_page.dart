// lib/features/reports/presentation/pages/report_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../concepts/presentation/pages/concepts_page.dart';
import '../../../media/presentation/widgets/photo_gallery_widget.dart';
import '../../domain/entities/report_entity.dart';
import '../providers/report_provider.dart';
import '../widgets/report_items_widget.dart';
import '../providers/pdf_provider.dart';


class ReportDetailPage extends ConsumerWidget {
  final String reportId;
  const ReportDetailPage({super.key, required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportDetailProvider(reportId));
    final user = ref.watch(currentUserProvider);

    return reportAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('$e')),
      ),
      data: (report) {
        if (report == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Reporte no encontrado')),
          );
        }

        // canEdit: cualquier usuario puede editar SUS borradores.
        // Analistas y admins pueden editar cualquier borrador.
        final isOwner = report.createdBy == user?.uid;
        final isReviewer = user?.role.canReviewReports ?? false;
        final canEdit = report.isDraft && (isOwner || isReviewer);

        return Scaffold(
          appBar: AppBar(
            title: Text(report.reportNumber),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
           // En el AppBar de ReportDetailPage, reemplaza las actions:

actions: [
  if (report.isPendingSync)
    const Padding(
      padding: EdgeInsets.only(right: 8),
      child: Icon(Icons.cloud_off, color: Colors.white70),
    ),
  // Botón PDF (disponible en cualquier estado)
  Consumer(
    builder: (context, ref, _) {
      final pdfState = ref.watch(pdfProvider(reportId));
      return IconButton(
        icon: pdfState.isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.picture_as_pdf_outlined),
        tooltip: 'Generar PDF',
        onPressed: pdfState.isGenerating
            ? null
            : () => ref
                .read(pdfProvider(reportId).notifier)
                .generateAndShare(report),
      );
    },
  ),
],
          
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── STATUS ───────────────────────────────
              _StatusCard(report: report),
              const SizedBox(height: 16),

              // ─── UBICACIÓN ────────────────────────────
              _InfoSection(
                title: 'Ubicación',
                icon: Icons.location_on_outlined,
                children: [
                  _InfoRow('Carretera', report.highway),
                  _InfoRow('KM', report.kmRangeDisplay),
                  _InfoRow('Cuerpo', report.body.displayName),
                  _InfoRow('Lado', report.side.displayName),
                  _InfoRow('Tipo de vía', report.roadType.displayName),
                  if (report.speedLimit != null)
                    _InfoRow('Vel. límite',
                        '${report.speedLimit!.toInt()} km/h'),
                  if (report.location != null)
                    _InfoRow('GPS', report.location.toString()),
                ],
              ),
              const SizedBox(height: 16),

              // ─── ACCIDENTE ────────────────────────────
              _InfoSection(
                title: 'Datos del Accidente',
                icon: Icons.car_crash_outlined,
                children: [
                  _InfoRow('Fecha',
                      DateFormat('dd/MM/yyyy', 'es_MX')
                          .format(report.accidentDate)),
                  if (report.fatalitiesCount > 0)
                    _InfoRow('Muertos',
                        '${report.fatalitiesCount}',
                        valueColor: AppColors.error),
                  if (report.seriousInjuriesCount > 0)
                    _InfoRow('Heridos graves',
                        '${report.seriousInjuriesCount}',
                        valueColor: AppColors.warning),
                  if (report.minorInjuriesCount > 0)
                    _InfoRow('Heridos leves',
                        '${report.minorInjuriesCount}'),
                  if (report.probableCause != null)
                    _InfoRow('Causa probable', report.probableCause!),
                  _InfoRow('Cuadrilla', '#${report.squadNumber}'),
                  _InfoRow('Elaboró', report.createdByName),
                ],
              ),
              const SizedBox(height: 16),

              // ─── ACTIVIDAD ────────────────────────────
              _InfoSection(
                title: 'Actividad Realizada',
                icon: Icons.construction_outlined,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(report.observations,
                        style: AppTextStyles.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── CONCEPTOS DE DAÑO ────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.list_alt_outlined,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Conceptos de Daño',
                              style: AppTextStyles.h3),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${report.items.length}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      ReportItemsWidget(
                        reportId: reportId,
                        items: report.items,
                        canEdit: canEdit,
                      ),

                      // ─── BOTÓN AGREGAR CONCEPTO ───────
                      // Siempre visible para borradores,
                      // sin depender del bottomNavigationBar
                      if (canEdit) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final added =
                                  await Navigator.of(context)
                                      .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => ConceptsPage(
                                    reportId: reportId,
                                  ),
                                ),
                              );
                              if (added == true &&
                                  context.mounted) {
                                ref.invalidate(
                                    reportDetailProvider(
                                        reportId));
                              }
                            },
                            icon: const Icon(
                                Icons.add_circle_outline),
                            label: const Text(
                                'Agregar Concepto de Daño'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ─── RESUMEN FINANCIERO ───────────────────
              if (report.items.isNotEmpty) ...[
                const SizedBox(height: 16),
                _FinancialSummaryCard(report: report),
              ],

              // ─── EVIDENCIAS FOTOGRÁFICAS ──────────────
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PhotoGalleryWidget(
                    reportId: reportId,
                    canEdit: canEdit,
                  ),
                ),
              ),

              // ─── MOTIVO DE RECHAZO ────────────────────
              if (report.status == ReportStatus.rejected &&
                  report.rejectionReason != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.cancel_outlined,
                            color: AppColors.error),
                        const SizedBox(width: 8),
                        Text('Motivo de rechazo',
                            style: AppTextStyles.h3
                                .copyWith(color: AppColors.error)),
                      ]),
                      const SizedBox(height: 8),
                      Text(report.rejectionReason!,
                          style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ─── BOTÓN ENVIAR (al fondo del scroll) ───
              if (canEdit)
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _submitReport(context, ref, report),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Enviar a Revisión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusSubmitted,
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReport(
    BuildContext context,
    WidgetRef ref,
    DamageReportEntity report,
  ) async {
    if (report.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Agrega al menos un concepto antes de enviar'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar reporte'),
        content: const Text(
          '¿Enviar este reporte a revisión de oficina? '
          'Ya no podrás editarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ref
        .read(reportsProvider.notifier)
        .submitReport(reportId);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado a revisión'),
          backgroundColor: AppColors.success,
        ),
      );
      ref.invalidate(reportDetailProvider(reportId));
    } else {
      final error = ref.read(reportsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Error al enviar'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ─── WIDGETS REUTILIZABLES ───────────────────────────────

class _StatusCard extends StatelessWidget {
  final DamageReportEntity report;
  const _StatusCard({required this.report});

  Color get _color {
    switch (report.status) {
      case ReportStatus.draft:      return AppColors.statusDraft;
      case ReportStatus.submitted:  return AppColors.statusSubmitted;
      case ReportStatus.reviewing:  return AppColors.statusReviewing;
      case ReportStatus.approved:   return AppColors.statusApproved;
      case ReportStatus.rejected:   return AppColors.statusRejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: _color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado: ${report.status.displayName}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
                if (report.isPendingSync)
                  Text(
                    'Pendiente de sincronización con el servidor',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.syncPending),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _InfoSection(
      {required this.title,
      required this.icon,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.h3),
            ]),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.label),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: valueColor)),
          ),
        ],
      ),
    );
  }
}

class _FinancialSummaryCard extends StatelessWidget {
  final DamageReportEntity report;
  const _FinancialSummaryCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final byCategory = <String, double>{};
    for (final item in report.items) {
      final cat = item.conceptCode.isNotEmpty
          ? item.conceptCode[0].toUpperCase()
          : '?';
      byCategory[cat] = (byCategory[cat] ?? 0) + item.subtotal;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Resumen Financiero', style: AppTextStyles.h3),
            ]),
            const SizedBox(height: 14),
            if (byCategory.length > 1) ...[
              ...byCategory.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Expanded(
                          child: Text(_catName(e.key),
                              style: AppTextStyles.bodySmall)),
                      Text(currency.format(e.value),
                          style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600)),
                    ]),
                  )),
              const Divider(height: 12),
            ],
            _Row('Subtotal sin IVA:',
                currency.format(report.total / 1.16)),
            _Row('IVA (16%):', currency.format(report.tax),
                color: AppColors.textSecondary),
            const Divider(height: 10),
            _Row('TOTAL:', currency.format(report.total),
                bold: true, color: AppColors.success),
          ],
        ),
      ),
    );
  }

  String _catName(String l) {
    const m = {
      'A': 'Señalamiento Horizontal',
      'B': 'Señalamiento Vertical',
      'C': 'Defensas Metálicas',
      'D': 'Bacheo y Pavimento',
      'E': 'Estructuras',
      'F': 'Cunetas y Drenaje',
      'G': 'Taludes',
      'H': 'Obras Complementarias',
    };
    return m[l] ?? 'Otros';
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _Row(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: bold
                    ? AppTextStyles.h3
                    : AppTextStyles.bodyMedium)),
        Text(value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color,
              fontSize: bold ? 20 : 15,
            )),
      ]),
    );
  }
}
