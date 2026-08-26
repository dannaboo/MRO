// lib/features/concepts/presentation/providers/concept_provider.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/concept_local_datasource.dart';
import '../../data/datasources/concept_remote_datasource.dart';
import '../../data/datasources/concepts_seed_script.dart';
import '../../data/repositories/concept_repository_impl.dart';
import '../../domain/entities/concept_entity.dart';
import '../../domain/repositories/concept_repository.dart';

// ─── PROVIDERS DE INFRAESTRUCTURA ───────────────────────

final conceptRemoteDataSourceProvider =
    Provider<ConceptRemoteDataSource>((ref) {
  return ConceptRemoteDataSourceImpl(
    firestore: ref.watch(firestoreProvider),
  );
});

final conceptLocalDataSourceProvider =
    Provider<ConceptLocalDataSource>((ref) {
  return ConceptLocalDataSourceImpl();
});

final conceptRepositoryProvider = Provider<ConceptRepository>((ref) {
  return ConceptRepositoryImpl(
    remote: ref.watch(conceptRemoteDataSourceProvider),
    local: ref.watch(conceptLocalDataSourceProvider),
    connectivity: Connectivity(),
  );
});

final conceptsSeedScriptProvider = Provider<ConceptsSeedScript>((ref) {
  return ConceptsSeedScript(ref.watch(firestoreProvider));
});

// ─── ESTADO DEL CATÁLOGO ────────────────────────────────

class ConceptsState {
  final List<ConceptEntity> allConcepts;
  final List<ConceptEntity> filteredConcepts;
  final List<String> categories;
  final String searchQuery;
  final String? selectedCategory;
  final bool isLoading;
  final bool isSeeding;    // Cargando catálogo inicial
  final String? error;
  final String? seedMessage;

  const ConceptsState({
    this.allConcepts = const [],
    this.filteredConcepts = const [],
    this.categories = const [],
    this.searchQuery = '',
    this.selectedCategory,
    this.isLoading = false,
    this.isSeeding = false,
    this.error,
    this.seedMessage,
  });

  ConceptsState copyWith({
    List<ConceptEntity>? allConcepts,
    List<ConceptEntity>? filteredConcepts,
    List<String>? categories,
    String? searchQuery,
    Object? selectedCategory = _kUnset,
    bool? isLoading,
    bool? isSeeding,
    String? error,
    String? seedMessage,
  }) {
    return ConceptsState(
      allConcepts: allConcepts ?? this.allConcepts,
      filteredConcepts: filteredConcepts ?? this.filteredConcepts,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory == _kUnset
          ? this.selectedCategory
          : selectedCategory as String?,
      isLoading: isLoading ?? this.isLoading,
      isSeeding: isSeeding ?? this.isSeeding,
      error: error,
      seedMessage: seedMessage,
    );
  }
}

const _kUnset = Object();

class ConceptsNotifier extends Notifier<ConceptsState> {
  @override
  ConceptsState build() {
    Future.microtask(() => loadConcepts());
    return const ConceptsState(isLoading: true);
  }

  Future<void> loadConcepts() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await ref.read(conceptRepositoryProvider).getAllConcepts();
    final catResult =
        await ref.read(conceptRepositoryProvider).getCategories();

    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (concepts) {
        final cats = catResult.getOrElse(() => []);
        state = state.copyWith(
          isLoading: false,
          allConcepts: concepts,
          filteredConcepts: concepts,
          categories: cats,
        );
      },
    );
  }

  // Búsqueda en tiempo real (se llama en cada keystroke)
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query, selectedCategory: null);

    if (query.trim().isEmpty) {
      state = state.copyWith(filteredConcepts: state.allConcepts);
      return;
    }

    // Búsqueda local instantánea (sin esperar red)
    final result =
        await ref.read(conceptRepositoryProvider).searchConcepts(query);

    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (concepts) => state = state.copyWith(filteredConcepts: concepts),
    );
  }

  // Filtrar por categoría
  Future<void> filterByCategory(String? category) async {
    state = state.copyWith(
      selectedCategory: category,
      searchQuery: '',
    );

    if (category == null) {
      state = state.copyWith(filteredConcepts: state.allConcepts);
      return;
    }

    final result = await ref
        .read(conceptRepositoryProvider)
        .getConceptsByCategory(category);

    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (concepts) => state = state.copyWith(filteredConcepts: concepts),
    );
  }

  // Carga el catálogo inicial en Firestore (solo admin, una vez)
  Future<void> seedCatalog() async {
    state = state.copyWith(isSeeding: true, seedMessage: 'Iniciando carga...');

    try {
      final script = ref.read(conceptsSeedScriptProvider);
      final alreadyLoaded = await script.isCatalogLoaded();

      if (alreadyLoaded) {
        state = state.copyWith(
          isSeeding: false,
          seedMessage: 'El catálogo ya existe en Firestore.',
        );
        return;
      }

      final count = await script.seedConcepts(
        onProgress: (msg) => state = state.copyWith(seedMessage: msg),
      );

      state = state.copyWith(
        isSeeding: false,
        seedMessage: '✓ $count conceptos cargados exitosamente.',
      );

      // Recargamos para mostrar el catálogo recién cargado
      await loadConcepts();
    } catch (e) {
      state = state.copyWith(
        isSeeding: false,
        error: 'Error al cargar catálogo: $e',
      );
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final conceptsProvider =
    NotifierProvider<ConceptsNotifier, ConceptsState>(() {
  return ConceptsNotifier();
});