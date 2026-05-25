// lib/core/theme/app_colors.dart
//
// ¿Qué hace este archivo?
// Define TODOS los colores del sistema en un solo lugar.
// Nunca escribas un color directamente en un widget.
// Siempre usa AppColors.nombre para que sea fácil cambiar
// el tema completo modificando solo este archivo.
//
// Decisiones de diseño para trabajo en campo:
// - Alto contraste para uso bajo el sol
// - Botones grandes con colores diferenciados por acción
// - Rojo/verde para estados críticos (aprobado/rechazado)

import 'package:flutter/material.dart';

class AppColors {
  // Constructor privado: esta clase no se instancia,
  // solo se usa para acceder a sus constantes estáticas.
  AppColors._();

  // ─── PRIMARIOS ──────────────────────────────────────
  // Azul corporativo MRO — usado en botones principales,
  // AppBar, y elementos de marca
  static const Color primary = Color(0xFF1565C0);      // Azul oscuro
  static const Color primaryLight = Color(0xFF1E88E5);  // Azul medio
  static const Color primaryDark = Color(0xFF0D47A1);   // Azul muy oscuro
  static const Color onPrimary = Color(0xFFFFFFFF);     // Texto sobre primario

  // ─── SECUNDARIOS ────────────────────────────────────
  // Naranja de acento — usado en elementos de acción secundaria
  // El naranja es visible bajo el sol y comunica "atención"
  static const Color secondary = Color(0xFFE65100);
  static const Color secondaryLight = Color(0xFFFF6D00);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // ─── ESTADOS DE REPORTE ─────────────────────────────
  // Cada estado tiene un color único para identificación visual rápida
  static const Color statusDraft = Color(0xFF9E9E9E);       // Gris — borrador
  static const Color statusSubmitted = Color(0xFF1976D2);   // Azul — enviado
  static const Color statusReviewing = Color(0xFFF57C00);   // Naranja — revisión
  static const Color statusApproved = Color(0xFF2E7D32);    // Verde — aprobado
  static const Color statusRejected = Color(0xFFC62828);    // Rojo — rechazado

  // ─── SUPERFICIE Y FONDO ─────────────────────────────
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF2F7);
  static const Color onBackground = Color(0xFF1A1A2E);
  static const Color onSurface = Color(0xFF1A1A2E);

  // ─── TEXTO ──────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);    // Texto principal
  static const Color textSecondary = Color(0xFF6B7280);  // Texto secundario
  static const Color textDisabled = Color(0xFFBDBDBD);   // Texto deshabilitado
  static const Color textOnDark = Color(0xFFFFFFFF);     // Texto sobre fondo oscuro

  // ─── BORDES Y DIVISORES ─────────────────────────────
  static const Color border = Color(0xFFE0E7FF);
  static const Color divider = Color(0xFFE5E7EB);

  // ─── ALERTAS Y FEEDBACK ─────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ─── SINCRONIZACIÓN (iconos de estado offline) ───────
  static const Color syncPending = Color(0xFFF57C00);   // Naranja — pendiente
  static const Color syncSynced = Color(0xFF2E7D32);    // Verde — sincronizado
  static const Color syncError = Color(0xFFC62828);     // Rojo — error

  // ─── TEMA OSCURO (para usar de noche en campo) ───────
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkBorder = Color(0xFF334155);
}