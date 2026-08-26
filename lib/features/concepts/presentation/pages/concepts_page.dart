// lib/features/concepts/presentation/pages/concepts_page.dart
//
// Pantalla de búsqueda del catálogo con:
// - Barra de búsqueda en tiempo real
// - Chips de categoría
// - Lista de resultados con código, nombre y precio
// - Botón para cargar el catálogo inicial (solo admin)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/concept_entity.dart';
import '../providers/concept_provider.dart';
import 'concept_selector_page.dart';

class ConceptsPage extends ConsumerStatefulWidget {
  // Si no es null, estamos en modo "seleccionar para un reporte"
  final String? reportId;

  const ConceptsPage({super.key, this.reportId});

  @override
  ConsumerState<ConceptsPage> createState() => _ConceptsPageState();
}

class _ConceptsPageState extends ConsumerState<ConceptsPage> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conceptsProvider);
    final user = ref.watch(currentUserProvider);
    final currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$');

    // Mostrar errores
    ref.listen<ConceptsState>(conceptsProvider, (prev, next) {
      if (next.error != null && prev?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(conceptsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.reportId != null ? 'Seleccionar Concepto' : 'Catálogo',
        ),
        actions: [
          // Botón de seed solo visible para admin y solo si no hay conceptos
          if (user?.role == UserRole.admin && state.allConcepts.isEmpty)
            IconButton(
              icon: const Icon(Icons.upload_outlined),
              tooltip: 'Cargar catálogo inicial',
              onPressed: state.isSeeding
                  ? null
                  : () => ref.read(conceptsProvider.notifier).seedCatalog(),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── BARRA DE BÚSQUEDA ─────────────────────
          _SearchBar(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            onChanged: (q) =>
                ref.read(conceptsProvider.notifier).search(q),
            onClear: () {
              _searchCtrl.clear();
              ref.read(conceptsProvider.notifier).search('');
            },
          ),

          // ─── FILTROS DE CATEGORÍA ──────────────────
          if (state.categories.isNotEmpty)
            _CategoryChips(
              categories: state.categories,
              selected: state.selectedCategory,
              onSelected: (cat) =>
                  ref.read(conceptsProvider.notifier).filterByCategory(cat),
            ),

          // ─── BANNER DE SEED ─────────────────────────
          if (state.isSeeding || state.seedMessage != null)
            _SeedBanner(message: state.seedMessage ?? 'Procesando...'),

          // ─── CONTADOR DE RESULTADOS ────────────────
          if (!state.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '${state.filteredConcepts.length} conceptos',
                    style: AppTextStyles.bodySmall,
                  ),
                  if (state.searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      'para "${state.searchQuery}"',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // ─── LISTA DE CONCEPTOS ────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.allConcepts.isEmpty
                    ? _EmptyCatalog(
                        isAdmin: user?.role == UserRole.admin,
                        onSeed: () =>
                            ref.read(conceptsProvider.notifier).seedCatalog(),
                      )
                    : state.filteredConcepts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off,
                                    size: 64,
                                    color: AppColors.textDisabled),
                                const SizedBox(height: 12),
                                Text(
                                  'Sin resultados para\n"${state.searchQuery}"',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: state.filteredConcepts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, i) {
                              final concept = state.filteredConcepts[i];
                              return _ConceptCard(
                                concept: concept,
                                currency: currency,
                                onTap: () => _onConceptTap(context, concept),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  void _onConceptTap(BuildContext context, ConceptEntity concept) {
    if (widget.reportId != null) {
      // Modo selección: abre el formulario de medidas
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConceptSelectorPage(
            concept: concept,
            reportId: widget.reportId!,
          ),
        ),
      );
    } else {
      // Modo catálogo: muestra detalle
      _showConceptDetail(context, concept);
    }
  }

  void _showConceptDetail(BuildContext context, ConceptEntity concept) {
    final currency =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(concept.code, style: AppTextStyles.code),
            const SizedBox(height: 8),
            Text(concept.name, style: AppTextStyles.h2),
            const SizedBox(height: 16),
            _DetailRow('Categoría', concept.category),
            if (concept.subcategory != null)
              _DetailRow('Subcategoría', concept.subcategory!),
            _DetailRow('Unidad', concept.unit.displayName),
            _DetailRow(
              'P.U. sin IVA',
              currency.format(concept.unitPriceWithoutTax),
            ),
            _DetailRow(
              'P.U. con IVA',
              currency.format(concept.unitPriceWithTax),
              valueColor: AppColors.success,
              bold: true,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('Medidas requeridas:',
                style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: concept.requiredMeasurements
                  .map((m) => Chip(
                        label: Text(m.label),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _DetailRow(this.label, this.value,
      {this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: AppTextStyles.label),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── WIDGETS AUXILIARES ──────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, clave... (defensa, D.1.1...)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textInputAction: TextInputAction.search,
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'Todos',
            isSelected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  label: cat,
                  isSelected: selected == cat,
                  onTap: () => onSelected(cat),
                ),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color:
                isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ConceptCard extends StatelessWidget {
  final ConceptEntity concept;
  final NumberFormat currency;
  final VoidCallback onTap;

  const _ConceptCard({
    required this.concept,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Código
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  concept.code,
                  style: AppTextStyles.code.copyWith(fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              // Nombre y categoría
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concept.name,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${concept.category} · ${concept.unit.displayName}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Precio
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currency.format(concept.unitPriceWithTax),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'c/IVA',
                    style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeedBanner extends StatelessWidget {
  final String message;
  const _SeedBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.infoLight,
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onSeed;

  const _EmptyCatalog({required this.isAdmin, required this.onSeed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books_outlined,
                size: 72, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              'Catálogo vacío',
              style: AppTextStyles.h3.copyWith(
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'Carga el catálogo inicial del tabulador MRO 2021'
                  : 'El catálogo aún no ha sido configurado.\nContacta al administrador.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isAdmin) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onSeed,
                icon: const Icon(Icons.upload_outlined),
                label: const Text('Cargar Catálogo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}