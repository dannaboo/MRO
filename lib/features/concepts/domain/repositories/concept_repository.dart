// lib/features/concepts/domain/repositories/concept_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/concept_entity.dart';

abstract class ConceptRepository {
  Future<Either<Failure, List<ConceptEntity>>> getAllConcepts();
  Future<Either<Failure, List<ConceptEntity>>> searchConcepts(String query);
  Future<Either<Failure, List<ConceptEntity>>> getConceptsByCategory(String category);
  Future<Either<Failure, List<String>>> getCategories();
  Future<Either<Failure, ConceptEntity>> getConceptById(String id);
  Future<Either<Failure, void>> syncCatalog(); // Descarga y cachea todo
}