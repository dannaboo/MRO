// lib/features/concepts/data/repositories/concept_repository_impl.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/concept_entity.dart';
import '../../domain/repositories/concept_repository.dart';
import '../datasources/concept_local_datasource.dart';
import '../datasources/concept_remote_datasource.dart';

class ConceptRepositoryImpl implements ConceptRepository {
  final ConceptRemoteDataSource _remote;
  final ConceptLocalDataSource _local;
  final Connectivity _connectivity;

  const ConceptRepositoryImpl({
    required ConceptRemoteDataSource remote,
    required ConceptLocalDataSource local,
    required Connectivity connectivity,
  })  : _remote = remote,
        _local = local,
        _connectivity = connectivity;

    Future<bool> get _hasInternet async {
  final result = await _connectivity.checkConnectivity();
  if (result.isEmpty) return false;
  return result.first != ConnectivityResult.none;
}
  @override
  Future<Either<Failure, List<ConceptEntity>>> getAllConcepts() async {
    if (await _hasInternet) {
      try {
        final concepts = await _remote.getAllConcepts();
        await _local.cacheConcepts(concepts);
        return Right(concepts);
      } on ServerException {
        // Fallback al caché
      }
    }
    try {
      final cached = await _local.getCachedConcepts();
      return Right(cached);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<ConceptEntity>>> searchConcepts(
      String query) async {
    // La búsqueda siempre en local para ser instantánea
    // (el caché ya está actualizado desde getAllConcepts)
    try {
      final hasCached = await _local.hasCachedConcepts();
      if (hasCached) {
        final results = await _local.searchLocal(query);
        return Right(results);
      }

      // Si no hay caché, buscar en remoto
      if (await _hasInternet) {
        final results = await _remote.searchConcepts(query);
        return Right(results);
      }

      return const Right([]);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, List<ConceptEntity>>> getConceptsByCategory(
      String category) async {
    try {
      final all = await _local.getCachedConcepts();
      final filtered =
          all.where((c) => c.category == category).toList();
      return Right(filtered);
    } catch (_) {
      if (await _hasInternet) {
        try {
          final results = await _remote.getConceptsByCategory(category);
          return Right(results);
        } on ServerException catch (e) {
          return Left(ServerFailure(message: e.message));
        }
      }
      return const Right([]);
    }
  }

  @override
  Future<Either<Failure, List<String>>> getCategories() async {
    try {
      final all = await _local.getCachedConcepts();
      final cats =
          all.map((c) => c.category).toSet().toList()..sort();
      if (cats.isNotEmpty) return Right(cats);
    } catch (_) {}

    if (await _hasInternet) {
      try {
        final cats = await _remote.getCategories();
        return Right(cats);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    }
    return const Right([]);
  }

  @override
  Future<Either<Failure, ConceptEntity>> getConceptById(String id) async {
    try {
      final cached = await _local.getCachedConcepts();
      final found = cached.where((c) => c.id == id).firstOrNull;
      if (found != null) return Right(found);
    } catch (_) {}

    if (await _hasInternet) {
      try {
        final concept = await _remote.getConceptById(id);
        return Right(concept);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    }
    return const Left(CacheFailure(message: 'Concepto no encontrado'));
  }

  @override
  Future<Either<Failure, void>> syncCatalog() async {
    if (!await _hasInternet) return const Left(NetworkFailure());
    try {
      final concepts = await _remote.getAllConcepts();
      await _local.cacheConcepts(concepts);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}