// lib/features/dashboard/presentation/pages/admin_dashboard_page.dart
//
// Panel central del administrador:
// - Estadísticas en tiempo real (tarjetas)
// - Lista de reportes pendientes de revisión
// - Acciones rápidas: aprobar / rechazar
// - Filtros por estado y fecha
// Diseñado para pantalla de escritorio (Flutter Web).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../../../reports/presentation/providers/report_provider.dart';
import '../providers/dashboard_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashState = ref.watch(dashboardProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    // Solo admin/manager/analyst acceden aquí
    if (user == null || !user.role.canViewDashboard) {
      return const Scaffold(
        body: Center(
          child: Text('No tienes permiso para ver esta pantalla'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel Administrativo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () =>
                ref.read(dashboardProvider.notifier).refresh(),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: dashState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(dashboardProvider.notifier).refresh(),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWide ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── SALUDO ────────────────────────
                    Text(
                      'Buenos días, ${user.displayName.split(' ').first}',
                      style: AppTextStyles.h2,
                    ),
                    Text(
                      'Aquí está el resumen de hoy',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),

                    // ─── TARJETAS DE ESTADÍSTICAS ──────
                    _StatsGrid(
                      stats: dashState.stats,
                      isWide: isWide,
                    ),
                    const SizedBox(height: 24),

                    // ─── REPORTES PENDIENTES ───────────
                    if (user.role.canReviewReports) ...[
                      Row(
                        children: [
                          Text(
                            'Reportes Pendientes de Revisión',
                            style: AppTextStyles.h3,
                          ),
                          const SizedBox(width: 8),
                          if (dashState.pendingReports.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${dashState.pendingReports.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (dashState.pendingReports.isEmpty)
                        _EmptyPending()
                      else
                        ...dashState.pendingReports.map(
                          (r) => _AdminReportCard(
                            report: r,
                            canApprove:
                                user.role.canApproveReports,
                            onView: () =>
                                context.push('/reports/${r.id}'),
                            onApprove: () =>
                                _approveReport(context, ref, r),
                            onReject: () =>
                                _rejectReport(context, ref, r),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],

                    // ─── TODOS LOS REPORTES ────────────
                    Row(
                      children: [
                        Text('Todos los Reportes',
                            style: AppTextStyles.h3),
                        const Spacer(),
                        // Filtro de estado
                        _StatusFilterDropdown(
                          selected: dashState.filterStatus,
                          onChanged: (s) => ref
                              .read(dashboardProvider.notifier)
                              .filterByStatus(s),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...dashState.allReports.map(
                      (r) => _AdminReportCard(
                        report: r,
                        canApprove: user.role.canApproveReports,
                        onView: () =>
                            context.push('/reports/${r.id}'),
                        onApprove: r.status ==
                                ReportStatus.submitted
                            ? () =>
                                _approveReport(context, ref, r)
                            : null,
                        onReject: r.status ==
                                ReportStatus.submitted
                            ? () =>
                                _rejectReport(context, ref, r)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _approveReport(
    BuildContext context,
    WidgetRef ref,
    DamageReportEntity report,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aprobar reporte'),
        content: Text(
            '¿Aprobar el reporte ${report.reportNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await ref
        .read(reportRepositoryProvider)
        .updateReportStatus(
          reportId: report.id,
          newStatus: ReportStatus.approved,
        );

    if (context.mounted) {
      result.fold(
        (f) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(f.message),
              backgroundColor: AppColors.error),
        ),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte aprobado'),
              backgroundColor: AppColors.success,
            ),
          );
          ref.read(dashboardProvider.notifier).refresh();
        },
      );
    }
  }

  Future<void> _rejectReport(
    BuildContext context,
    WidgetRef ref,
    DamageReportEntity report,
  ) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rechazar reporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reporte: ${report.reportNumber}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo de rechazo *',
                hintText: 'Describe el motivo...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonCtrl.text.trim().isEmpty) {
      return;
    }

    final result = await ref
        .read(reportRepositoryProvider)
        .updateReportStatus(
          reportId: report.id,
          newStatus: ReportStatus.rejected,
          rejectionReason: reasonCtrl.text.trim(),
        );

    if (context.mounted) {
      result.fold(
        (f) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(f.message),
              backgroundColor: AppColors.error),
        ),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte rechazado'),
              backgroundColor: AppColors.warning,
            ),
          );
          ref.read(dashboardProvider.notifier).refresh();
        },
      );
    }
  }
}

// ─── GRID DE ESTADÍSTICAS ────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  final bool isWide;

  const _StatsGrid({required this.stats, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        title: 'Total Reportes',
        value: '${stats.total}',
        icon: Icons.description_outlined,
        color: AppColors.primary,
      ),
      _StatCard(
        title: 'Pendientes',
        value: '${stats.submitted}',
        icon: Icons.pending_actions_outlined,
        color: AppColors.warning,
        urgent: stats.submitted > 0,
      ),
      _StatCard(
        title: 'Aprobados',
        value: '${stats.approved}',
        icon: Icons.check_circle_outlined,
        color: AppColors.success,
      ),
      _StatCard(
        title: 'Total Facturado',
        value: NumberFormat.compactCurrency(
          locale: 'es_MX',
          symbol: '\$',
          decimalDigits: 0,
        ).format(stats.totalAmount),
        icon: Icons.attach_money,
        color: AppColors.secondary,
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map((c) => Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: c,
                )))
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: cards,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool urgent;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (urgent) ...[
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTextStyles.h1.copyWith(color: color),
            ),
            Text(title,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── CARD DE REPORTE EN ADMIN ────────────────────────────

class _AdminReportCard extends StatelessWidget {
  final DamageReportEntity report;
  final bool canApprove;
  final VoidCallback onView;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _AdminReportCard({
    required this.report,
    required this.canApprove,
    required this.onView,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final date = DateFormat('dd/MM/yy HH:mm', 'es_MX');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(report.reportNumber,
                            style: AppTextStyles.reportNumber),
                        const SizedBox(width: 8),
                        _StatusPill(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.highway} · ${report.kmRangeDisplay} · '
                      '${report.body.displayName} ${report.side.displayName}',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      'Cuadrilla #${report.squadNumber} · '
                      '${report.createdByName} · '
                      '${date.format(report.createdAt)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // Total
              if (report.total > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  child: Text(
                    currency.format(report.total),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

              // Acciones (solo admin)
              if (canApprove &&
                  (onApprove != null || onReject != null))
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onApprove != null)
                      IconButton(
                        icon: const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success),
                        tooltip: 'Aprobar',
                        onPressed: onApprove,
                      ),
                    if (onReject != null)
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined,
                            color: AppColors.error),
                        tooltip: 'Rechazar',
                        onPressed: onReject,
                      ),
                  ],
                ),

              // Flecha de navegación
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ReportStatus status;
  const _StatusPill({required this.status});

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
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _color),
      ),
    );
  }
}

class _EmptyPending extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.success, size: 32),
          const SizedBox(width: 16),
          Text(
            'No hay reportes pendientes de revisión',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterDropdown extends StatelessWidget {
  final ReportStatus? selected;
  final ValueChanged<ReportStatus?> onChanged;

  const _StatusFilterDropdown(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<ReportStatus?>(
      value: selected,
      hint: const Text('Todos los estados'),
      underline: const SizedBox(),
      items: [
        const DropdownMenuItem(
            value: null, child: Text('Todos los estados')),
        ...ReportStatus.values.map(
          (s) => DropdownMenuItem(
              value: s, child: Text(s.displayName)),
        ),
      ],
      onChanged: onChanged,
    );
  }
}