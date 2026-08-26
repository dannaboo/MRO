// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── CORPORATIVO MRO ────────────────────────────────
  static const Color brandDark    = Color(0xFF0D2137); // Azul marino — headers, nav
  static const Color primary      = Color(0xFF1565C0); // Azul MRO — acción principal
  static const Color primaryLight = Color(0xFF1E88E5);
  static const Color primaryDark  = Color(0xFF0D47A1);
  static const Color onPrimary    = Color(0xFFFFFFFF);

  // ─── ACENTO ──────────────────────────────────────────
  static const Color secondary      = Color(0xFFE65100); // Naranja — urgente / acento
  static const Color secondaryLight = Color(0xFFFF6D00);
  static const Color onSecondary    = Color(0xFFFFFFFF);

  // ─── SUPERFICIES ─────────────────────────────────────
  static const Color background     = Color(0xFFF4F6FA); // Fondo general
  static const Color surface        = Color(0xFFFFFFFF); // Cards
  static const Color surfaceVariant = Color(0xFFEEF2F7); // Campos, chips
  static const Color onBackground   = Color(0xFF0D2137);
  static const Color onSurface      = Color(0xFF0D2137);

  // ─── TEXTO ───────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0D2137);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled  = Color(0xFFBDBDBD);
  static const Color textOnDark    = Color(0xFFFFFFFF);

  // ─── BORDES ──────────────────────────────────────────
  static const Color border  = Color(0xFFE0E9FF);
  static const Color divider = Color(0xFFE8F0FE);

  // ─── ESTADOS DE REPORTE ──────────────────────────────
  static const Color statusDraft     = Color(0xFF64748B);
  static const Color statusSubmitted = Color(0xFF1D4ED8);
  static const Color statusReviewing = Color(0xFFD97706);
  static const Color statusApproved  = Color(0xFF15803D);
  static const Color statusRejected  = Color(0xFFB91C1C);

  // ─── SEMÁNTICOS ──────────────────────────────────────
  static const Color success      = Color(0xFF15803D);
  static const Color successLight = Color(0xFFF0FDF4);
  static const Color warning      = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error        = Color(0xFFB91C1C);
  static const Color errorLight   = Color(0xFFFEF2F2);
  static const Color info         = Color(0xFF1565C0);
  static const Color infoLight    = Color(0xFFEFF6FF);

  // ─── SINCRONIZACIÓN ──────────────────────────────────
  static const Color syncPending = Color(0xFFD97706);
  static const Color syncSynced  = Color(0xFF15803D);
  static const Color syncError   = Color(0xFFB91C1C);

  // ─── TEMA OSCURO ─────────────────────────────────────
  static const Color darkBackground   = Color(0xFF0A1929);
  static const Color darkSurface      = Color(0xFF0D2137);
  static const Color darkSurfaceVar   = Color(0xFF132D4A);
  static const Color darkOnSurface    = Color(0xFFF1F5F9);
  static const Color darkBorder       = Color(0xFF1E3A5F);
}