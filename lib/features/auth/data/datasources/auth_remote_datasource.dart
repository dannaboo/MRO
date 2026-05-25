// lib/features/auth/data/datasources/auth_remote_datasource.dart
//
// ¿Qué hace este archivo?
// Contiene TODA la lógica de comunicación con Firebase Auth
// y Firestore para operaciones de autenticación.
// 
// Este es el único lugar en toda la app donde usamos
// FirebaseAuth y FirebaseFirestore directamente para auth.
// Si Firebase cambia su API, solo modificamos este archivo.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

// Interfaz abstracta del datasource.
// Permite hacer mocks (datos de prueba) en los tests.
abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;

  Future<void> sendPasswordResetEmail({required String email});
}

// Implementación real que usa Firebase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Paso 1: Autenticar con Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthException(
          message: 'Error al autenticar. Intenta de nuevo.',
          code: 'null-user',
        );
      }

      // Paso 2: Obtener el perfil completo desde Firestore
      // Firebase Auth solo guarda email y uid.
      // El rol, nombre completo y número de empleado están en Firestore.
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        // El usuario existe en Auth pero no tiene perfil en Firestore.
        // Esto no debería pasar en producción, pero lo manejamos.
        throw AuthException(
          message: 'Perfil de usuario no encontrado. '
              'Contacta al administrador.',
          code: 'profile-not-found',
        );
      }

      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      // Traducimos los códigos de error de Firebase a mensajes
      // legibles para el usuario final.
      throw AuthException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    } on AuthException {
      rethrow; // Re-lanzamos nuestras propias excepciones
    } catch (e) {
      throw AuthException(
        message: 'Error inesperado al iniciar sesión.',
        code: 'unknown',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw const AuthException(
        message: 'Error al cerrar sesión.',
        code: 'logout-error',
      );
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) return null;
      return UserModel.fromFirestore(userDoc);
    } catch (e) {
      throw AuthException(
        message: 'Error al obtener usuario actual.',
        code: 'get-user-error',
      );
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    // Firebase emite un evento cada vez que cambia el estado de auth.
    // Nosotros transformamos ese stream de User? a UserModel?
    // usando asyncMap para hacer la consulta a Firestore.
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final userDoc = await _firestore
            .collection(AppConstants.collectionUsers)
            .doc(firebaseUser.uid)
            .get();

        if (!userDoc.exists) return null;
        return UserModel.fromFirestore(userDoc);
      } catch (e) {
        return null;
      }
    });
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: _getAuthErrorMessage(e.code),
        code: e.code,
      );
    }
  }

  // Traduce códigos de error de Firebase a mensajes humanos en español.
  // Firebase devuelve códigos como "wrong-password", "user-not-found", etc.
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta ha sido desactivada.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      case 'invalid-email':
        return 'El formato del correo no es válido.';
      default:
        return 'Error de autenticación. Intenta de nuevo.';
    }
  }
}