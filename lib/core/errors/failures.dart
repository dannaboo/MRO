// lib/core/errors/failures.dart
//
// ¿Qué hace este archivo?
// Define los tipos de "falla" que puede tener el sistema.
// Un Failure es diferente a una Exception:
// - Exception: error técnico de bajo nivel (Firebase, red, etc.)
// - Failure: error del dominio con significado para el negocio
//
// Usamos el patrón Either de la librería dartz:
// Either<Failure, T> significa "puede ser un Failure O un T exitoso"
// Esto elimina los try-catch espagueti en toda la app.

import 'package:equatable/equatable.dart';

// Clase base abstracta. Todos los tipos de falla la extienden.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

// ─── FALLAS DE AUTENTICACIÓN ────────────────────────────

class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.code});
}

// Email o contraseña incorrectos
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure()
      : super(
          message: 'Correo o contraseña incorrectos.',
          code: 'invalid-credentials',
        );
}

// El usuario fue desactivado por un administrador
class UserDisabledFailure extends AuthFailure {
  const UserDisabledFailure()
      : super(
          message: 'Tu cuenta ha sido desactivada. Contacta al administrador.',
          code: 'user-disabled',
        );
}

// No hay sesión activa
class NotAuthenticatedFailure extends AuthFailure {
  const NotAuthenticatedFailure()
      : super(
          message: 'No has iniciado sesión.',
          code: 'not-authenticated',
        );
}

// ─── FALLAS DE RED ───────────────────────────────────────

class NetworkFailure extends Failure {
  const NetworkFailure()
      : super(
          message: 'Sin conexión a internet. Trabajando en modo offline.',
          code: 'no-internet',
        );
}

// ─── FALLAS DE SERVIDOR / FIREBASE ──────────────────────

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

// ─── FALLAS DE CACHÉ / LOCAL ─────────────────────────────

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

// ─── FALLAS DE PERMISOS ──────────────────────────────────

class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

// ─── FALLAS DE VALIDACIÓN ───────────────────────────────

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}