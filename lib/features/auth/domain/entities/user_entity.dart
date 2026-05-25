// lib/features/auth/domain/entities/user_entity.dart
//
// ¿Qué hace este archivo?
// Define qué es un "Usuario" para el negocio MRO.
// Esta clase NO sabe nada de Firebase, Firestore, ni Flutter.
// Es puro Dart. Si mañana cambias Firebase por otro backend,
// esta clase no cambia.
//
// Usamos Equatable para que dos objetos UserEntity con los
// mismos datos sean considerados "iguales" por Dart.
// Sin Equatable, dos objetos con los mismos datos son
// diferentes porque Dart compara referencias de memoria.

import 'package:equatable/equatable.dart';

// Enum: define los roles posibles del sistema.
// Usar enum en lugar de String evita errores de tipeo.
// Si escribes UserRole.adimn → error de compilación.
// Si escribes "adimn" → error silencioso en producción.
enum UserRole {
  fieldWorker,  // Cuadrillero de campo
  supervisor,   // Supervisor de cuadrilla
  analyst,      // Analista de oficina
  admin,        // Administrador del sistema
  manager,      // Gerente (solo lectura)
}

// Extensión que agrega utilidades al enum UserRole.
// extension permite agregar métodos a un tipo existente
// sin modificar la clase original.
extension UserRoleExtension on UserRole {
  // Convierte el enum a String para guardar en Firestore.
  // fieldWorker → "field_worker"
  String get value {
    switch (this) {
      case UserRole.fieldWorker:
        return 'field_worker';
      case UserRole.supervisor:
        return 'supervisor';
      case UserRole.analyst:
        return 'analyst';
      case UserRole.admin:
        return 'admin';
      case UserRole.manager:
        return 'manager';
    }
  }

  // Nombre legible en español para mostrar en la UI
  String get displayName {
    switch (this) {
      case UserRole.fieldWorker:
        return 'Cuadrillero';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.analyst:
        return 'Analista';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.manager:
        return 'Gerente';
    }
  }

  // Convierte String de Firestore de vuelta al enum.
  // Método estático porque no necesita una instancia.
  static UserRole fromString(String value) {
    switch (value) {
      case 'field_worker':
        return UserRole.fieldWorker;
      case 'supervisor':
        return UserRole.supervisor;
      case 'analyst':
        return UserRole.analyst;
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      default:
        // Si viene un rol desconocido, asignamos el menos privilegiado
        return UserRole.fieldWorker;
    }
  }

  // Permisos: qué puede hacer cada rol
  bool get canCreateReports =>
      this == UserRole.fieldWorker || this == UserRole.supervisor;

  bool get canReviewReports =>
      this == UserRole.analyst ||
      this == UserRole.admin ||
      this == UserRole.manager;

  bool get canApproveReports =>
      this == UserRole.admin;

  bool get canManageConcepts =>
      this == UserRole.admin;

  bool get canManageUsers =>
      this == UserRole.admin;

  bool get canViewDashboard =>
      this == UserRole.analyst ||
      this == UserRole.admin ||
      this == UserRole.manager;

  bool get canViewAllReports =>
      this == UserRole.analyst ||
      this == UserRole.admin ||
      this == UserRole.manager;
}

// La entidad principal. Extiende Equatable para
// comparación por valor (no por referencia).
class UserEntity extends Equatable {
  final String uid;           // ID único de Firebase Auth
  final String email;
  final String displayName;
  final String employeeId;    // Número de empleado MRO
  final String? phone;
  final UserRole role;
  final bool isActive;        // Si está desactivado, no puede entrar
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.employeeId,
    this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  // props: lista de campos que Equatable usa para comparar.
  // Dos UserEntity son iguales si tienen el mismo uid.
  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        employeeId,
        phone,
        role,
        isActive,
        createdAt,
        updatedAt,
      ];

  // copyWith: crea una copia con algunos campos modificados.
  // Útil para actualizar solo el nombre sin recrear todo el objeto.
  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? employeeId,
    String? phone,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      employeeId: employeeId ?? this.employeeId,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'UserEntity(uid: $uid, email: $email, role: ${role.value})';
}