// lib/features/auth/domain/usecases/login_usecase.dart
//
// ¿Qué hace este archivo?
// Implementa el caso de uso "Iniciar sesión".
// Orquesta la lógica: valida parámetros, llama al repositorio,
// verifica que el usuario esté activo.
//
// ¿Por qué no llamar directamente al repositorio desde la UI?
// Porque la UI no debería saber las reglas de negocio.
// Por ejemplo: "un usuario desactivado no puede entrar aunque
// su contraseña sea correcta" es una regla de negocio,
// no una regla de UI.

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// Parámetros del caso de uso encapsulados en una clase.
// Ventaja: si en el futuro agregas un campo (como deviceId),
// solo modificas LoginParams sin cambiar la firma del método.
class LoginParams {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });
}

class LoginUseCase {
  // El caso de uso SOLO conoce el repositorio abstracto.
  // No sabe si usa Firebase, una API REST, o datos de prueba.
  final AuthRepository _repository;

  // Constructor: recibe el repositorio por inyección de dependencias.
  const LoginUseCase(this._repository);

  // call() permite usar el objeto como función: loginUseCase(params)
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    // ─── VALIDACIÓN DE NEGOCIO ─────────────────────────
    // Validamos antes de llamar al servidor para ahorrar
    // una llamada de red innecesaria.
    if (params.email.isEmpty || params.password.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Email y contraseña son requeridos.'),
      );
    }

    if (!_isValidEmail(params.email)) {
      return const Left(
        ValidationFailure(message: 'El formato del email no es válido.'),
      );
    }

    if (params.password.length < 6) {
      return const Left(
        ValidationFailure(
          message: 'La contraseña debe tener al menos 6 caracteres.',
        ),
      );
    }

    // ─── LLAMADA AL REPOSITORIO ────────────────────────
    final result = await _repository.loginWithEmailAndPassword(
      email: params.email.trim().toLowerCase(),
      password: params.password,
    );

    // ─── REGLA DE NEGOCIO: usuario inactivo ───────────
    // El repositorio puede devolver éxito (auth correcto)
    // pero nosotros aún podemos rechazarlo si está inactivo.
    return result.fold(
      // Si hubo un Failure, lo pasamos tal cual
      (failure) => Left(failure),
      // Si el login fue exitoso, verificamos que esté activo
      (user) {
        if (!user.isActive) {
          return const Left(UserDisabledFailure());
        }
        return Right(user);
      },
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }
}