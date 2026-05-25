// lib/features/auth/presentation/providers/auth_provider.dart
//
// ¿Qué hace este archivo?
// Define los providers de Riverpod para autenticación.
// Los providers son "fuentes de verdad" reactivas:
// cuando el estado cambia, todos los widgets que lo usan
// se reconstruyen automáticamente.
//
// FLUJO:
// Provider de Firebase → Provider de DataSource →
// Provider de Repositorio → Provider de UseCase →
// Provider de Estado (AuthNotifier)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';

// ─── PROVIDERS DE INFRAESTRUCTURA ───────────────────────
// Estos providers exponen las instancias de Firebase.
// Provider crea una instancia única (singleton) en toda la app.

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// ─── PROVIDERS DE CAPA DE DATOS ─────────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

// ─── PROVIDERS DE CASOS DE USO ──────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

// ─── ESTADO DE AUTENTICACIÓN ────────────────────────────

// Define los posibles estados de la sesión
enum AuthStatus {
  initial,         // App recién abierta, verificando sesión
  authenticated,   // Usuario logueado correctamente
  unauthenticated, // No hay sesión activa
  loading,         // Procesando (login, logout)
  error,           // Error durante auth
}

// Clase que encapsula todo el estado de autenticación
class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  // Estado inicial al abrir la app
  const AuthState.initial() : this(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      // Para borrar el user (al logout), pasamos user: null explícitamente
      user: status == AuthStatus.unauthenticated ? null : (user ?? this.user),
      errorMessage: errorMessage,
    );
  }

  // Getters de conveniencia
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
}

// AuthNotifier: controla la lógica de cambios de estado de auth.
// Extiende AsyncNotifier para manejar operaciones asíncronas.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Al construirse, verificamos si ya hay una sesión activa.
    // Esto es lo que hace que si el usuario ya inició sesión
    // y abre la app, no tenga que hacer login de nuevo.
    _checkCurrentSession();

    // También escuchamos cambios en el stream de Firebase Auth.
    // Si el token expira o se revoca, el stream emite null
    // y el usuario es deslogueado automáticamente.
    ref.watch(authRepositoryProvider).authStateChanges.listen((user) {
      if (user != null && state.status != AuthStatus.loading) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        );
      }
    });

    return const AuthState.initial();
  }

  Future<void> _checkCurrentSession() async {
    final result = await ref.read(getCurrentUserUseCaseProvider).call();
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.unauthenticated,
      ),
      (user) {
        if (user != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
          );
        }
      },
    );
  }

  // Iniciar sesión
  Future<void> login({
    required String email,
    required String password,
  }) async {
    // Actualizamos el estado a "cargando" para mostrar el spinner
    state = state.copyWith(status: AuthStatus.loading);

    final result = await ref.read(loginUseCaseProvider).call(
          LoginParams(email: email, password: password),
        );

    // fold() maneja ambos casos (Left=falla, Right=éxito)
    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (user) => state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  // Cerrar sesión
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);

    final result = await ref.read(logoutUseCaseProvider).call();

    result.fold(
      (failure) => state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(status: AuthStatus.unauthenticated),
    );
  }

  // Limpiar el error después de mostrarlo
  void clearError() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }
}

// Provider del notifier. Toda la app accede al estado de auth aquí.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// Provider conveniente para obtener el usuario actual directamente.
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authProvider).user;
});