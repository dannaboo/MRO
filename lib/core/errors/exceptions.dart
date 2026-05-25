// lib/core/errors/exceptions.dart
//
// ¿Qué hace este archivo?
// Define excepciones técnicas de la capa de datos.
// Las datasources lanzan estas excepciones cuando algo falla.
// Los repositories las capturan y las convierten en Failures.
// Así el dominio nunca ve excepciones técnicas.

class ServerException implements Exception {
  final String message;
  final String? code;
  const ServerException({required this.message, this.code});

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

class AuthException implements Exception {
  final String message;
  final String? code;
  const AuthException({required this.message, this.code});

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

class CacheException implements Exception {
  final String message;
  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  const NetworkException();

  @override
  String toString() => 'NetworkException: No internet connection';
}

class PermissionException implements Exception {
  final String message;
  const PermissionException({required this.message});

  @override
  String toString() => 'PermissionException: $message';
}