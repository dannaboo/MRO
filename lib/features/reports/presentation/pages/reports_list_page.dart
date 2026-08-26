// lib/features/reports/presentation/pages/reports_list_page.dart
//
// Lista de reportes con:
// - Filtros por estado (chips horizontales)
// - Indicador de sincronización
// - Card de reporte con información clave
// - FAB para crear nuevo reporte
// - Pull-to-refresh

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/report_entity.dart';
import '../providers/report_provider.dart';

class ReportsListPage extends ConsumerWidget {
  const ReportsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
        actions: [
          // Indicador de sincronización pendiente
          if (state.reports.any((r) => r.isPendingSync))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.sync, size: 16, color: Colors.white),
                label: Text(
                  '${state.reports.where((r) => r.isPendingSync).length} pendientes',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: AppColors.syncPending,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),

      // ─── FILTROS POR ESTADO ──────────────────────────
      body: Column(
        children: [
          _StatusFilterBar(
            selected: state.filterStatus,
            onSelected: (status) {
              ref.read(reportsProvider.notifier).loadReports(status: status);
            },
          ),

          // ─── LISTA ────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.reports.isEmpty
                    ? _EmptyState(
                        filterStatus: state.filterStatus,
                        onCreateTap: () => context.push('/reports/new'),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(reportsProvider.notifier).loadReports(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.reports.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final report = state.reports[index];
                            return _ReportCard(
                              report: report,
                              onTap: () =>
                                  context.push('/reports/${report.id}'),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),

      // ─── BOTÓN CREAR NUEVO REPORTE ───────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/reports/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Reporte'),
      ),
    );
  }
}

// ─── FILTROS DE ESTADO ───────────────────────────────────
class _StatusFilterBar extends StatelessWidget {
  final ReportStatus? selected;
  final ValueChanged<ReportStatus?> onSelected;

  const _StatusFilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: AppColors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Chip "Todos"
          _FilterChip(
            label: 'Todos',
            isSelected: selected == null,
            color: AppColors.primary,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...ReportStatus.values.map((status) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: status.displayName,
                  isSelected: selected == status,
                  color: _statusColor(status),
                  onTap: () => onSelected(status),
                ),
              )),
        ],
      ),
    );
  }

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.draft:      return AppColors.statusDraft;
      case ReportStatus.submitted:  return AppColors.statusSubmitted;
      case ReportStatus.reviewing:  return AppColors.statusReviewing;
      case ReportStatus.approved:   return AppColors.statusApproved;
      case ReportStatus.rejected:   return AppColors.statusRejected;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── CARD DE REPORTE ─────────────────────────────────────
class _ReportCard extends StatelessWidget {
  final DamageReportEntity report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_MX');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── FILA SUPERIOR ───────────────────────
              Row(
                children: [
                  // Número de reporte
                  Expanded(
                    child: Text(
                      report.reportNumber,
                      style: AppTextStyles.reportNumber,
                    ),
                  ),
                  // Estado del reporte
                  _StatusBadge(status: report.status),
                ],
              ),

              const SizedBox(height: 12),

              // ─── CARRETERA Y KM ──────────────────────
              Row(
                children: [
                  const Icon(Icons.route, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    report.highway,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    report.kmRangeDisplay,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // ─── CUERPO Y LADO ───────────────────────
              Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 16,
                      color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${report.body.displayName} · ${report.side.displayName}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const Spacer(),
                  // Fecha del accidente
                  Text(
                    dateFormat.format(report.accidentDate),
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // ─── FILA INFERIOR ────────────────────────
              Row(
                children: [
                  // Cuadrilla
                  Icon(Icons.people_outline, size: 14,
                      color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Cuadrilla #${report.squadNumber}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const Spacer(),
                  // Total del reporte
                  if (report.total > 0)
                    Text(
                      '\$${report.total.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  // Indicador de sincronización pendiente
                  if (report.isPendingSync) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.cloud_off, size: 16,
                        color: AppColors.syncPending),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── BADGE DE ESTADO ─────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final ReportStatus status;

  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}

// ─── ESTADO VACÍO ────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final ReportStatus? filterStatus;
  final VoidCallback onCreateTap;

  const _EmptyState({this.filterStatus, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filterStatus == null ? Icons.description_outlined : Icons.filter_list,
              size: 72,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              filterStatus == null
                  ? 'No tienes reportes aún'
                  : 'No hay reportes ${filterStatus!.displayName.toLowerCase()}s',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (filterStatus == null) ...[
              const SizedBox(height: 8),
              Text(
                'Crea tu primer reporte de daños',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onCreateTap,
                icon: const Icon(Icons.add),
                label: const Text('Crear Reporte'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}