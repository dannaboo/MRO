// lib/core/theme/app_text_styles.dart
//
// ¿Qué hace este archivo?
// Define todos los estilos de texto del sistema.
// Usar estilos consistentes hace la app más profesional
// y facilita cambiar tipografía en toda la app desde aquí.
//
// Usamos la fuente Inter: moderna, legible, y funciona
// perfectamente en pantallas de diferentes tamaños y
// bajo luz solar.

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ─── HEADINGS (Títulos) ──────────────────────────────

  // H1: Títulos de pantalla principal
  // Ejemplo: "Nuevo Reporte"
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // H2: Títulos de sección
  // Ejemplo: "Información de Ubicación"
  static const TextStyle h2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.3,
  );

  // H3: Subtítulos de tarjetas
  static const TextStyle h3 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ─── BODY (Cuerpo de texto) ──────────────────────────

  // Body Large: Texto principal de contenido
  // Ejemplo: descripciones, observaciones
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  // Body Medium: Texto de formularios y listas
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // Body Small: Texto secundario, metadatos
  // Ejemplo: "Hace 2 horas · KM 133"
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ─── LABELS (Etiquetas) ──────────────────────────────

  // Label para campos de formulario
  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  // Label para botones
  static const TextStyle buttonLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.0,
  );

  // ─── ESPECIALES ──────────────────────────────────────

  // Para mostrar montos y totales
  static const TextStyle amount = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: -0.5,
  );

  // Para códigos (claves de conceptos: D.1.2, A.1.1)
  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    letterSpacing: 0.5,
  );

  // Para el número de reporte: MRO-2026-001234
  static const TextStyle reportNumber = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 1.0,
  );
}
