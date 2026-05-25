// lib/features/auth/data/models/user_model.dart
//
// ¿Qué hace este archivo?
// Extiende UserEntity con la capacidad de serialización.
// fromFirestore(): convierte el documento de Firestore → UserModel
// toFirestore(): convierte UserModel → Map para guardar en Firestore
//
// Separar Entity del Model permite que el dominio sea puro
// y que la serialización viva solo en la capa de datos.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    required super.employeeId,
    super.phone,
    required super.role,
    required super.isActive,
    required super.createdAt,
    super.updatedAt,
  });

  // Factory constructor: crea un UserModel desde un DocumentSnapshot de Firestore.
  // DocumentSnapshot es el objeto que Firestore devuelve cuando lees un documento.
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      employeeId: data['employeeId'] as String? ?? '',
      phone: data['phone'] as String?,
      // Convertimos el String de Firestore al enum UserRole
      role: UserRoleExtension.fromString(data['role'] as String? ?? 'field_worker'),
      isActive: data['isActive'] as bool? ?? true,
      // Firestore guarda timestamps como Timestamp, los convertimos a DateTime
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convierte el modelo a un Map para guardarlo en Firestore.
  // No incluimos uid porque Firestore lo usa como ID del documento.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'employeeId': employeeId,
      'phone': phone,
      'role': role.value,        // Guardamos el String "field_worker", no el enum
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Crea un UserModel desde un UserEntity.
  // Útil cuando tienes una entidad y necesitas un modelo.
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      displayName: entity.displayName,
      employeeId: entity.employeeId,
      phone: entity.phone,
      role: entity.role,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}