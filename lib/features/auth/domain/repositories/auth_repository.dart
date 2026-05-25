// lib/features/auth/domain/repositories/auth_repository.dart
//
// ¿Qué hace este archivo?
// Define el CONTRATO de autenticación.
// Es una clase abstracta (interfaz) que dice:
// "el sistema de auth puede hacer estas cosas,
// pero no me importa cómo las hace".
//
// Either<Failure, T>:
// - Left(Failure) → algo salió mal
// - Right(T)      → éxito, aquí está el resultado
//
// Esto reemplaza los try-catch y hace el código más predecible.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  // Iniciar sesión con email y contraseña.
  // Retorna el usuario autenticado o un Failure.
  Future<Either<Failure, UserEntity>> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  // Cerrar sesión.
  Future<Either<Failure, void>> logout();

  // Obtener el usuario actualmente autenticado.
  // Retorna null si no hay sesión activa.
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  // Stream que emite el usuario cuando cambia la sesión.
  // Emite null cuando cierra sesión, UserEntity cuando inicia.
  // Los streams son perfectos para este caso porque Firebase
  // notifica automáticamente cuando cambia el estado de auth.
  Stream<UserEntity?> get authStateChanges;

  // Cambiar contraseña (el admin puede resetear la de un empleado)
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });
}