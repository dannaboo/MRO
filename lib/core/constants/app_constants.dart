// lib/core/constants/app_constants.dart
//
// ¿Qué hace este archivo?
// Centraliza todos los valores constantes del negocio.
// Si el IVA cambia de 16% a 8%, cambias UN número aquí
// y se actualiza en todo el sistema automáticamente.
// Si hardcodeas "0.16" en 50 archivos diferentes,
// tienes que buscarlos y cambiarlos uno por uno.

class AppConstants {
  AppConstants._();

  // ─── EMPRESA ────────────────────────────────────────
  static const String companyName = 'MRO Estado de Mexico-Michoacan SAPI de CV';
  static const String contractNumber = 'BNO-GO-03-2019-01-MRO';
  static const String reportPrefix = 'MRO';

  // ─── FINANCIERO ─────────────────────────────────────
  // Tasa de IVA según el tabulador real de la empresa
  static const double taxRate = 0.16;  // 16%
  // Factor de precio (del tabulador: precio con IVA = precio × factor)
  // Nota: en el tabulador vemos que precio sin IVA ≈ precio × 0.82
  static const double priceFactorWithoutTax = 0.82;

  // ─── REPORTE ────────────────────────────────────────
  // Número máximo de fotos por reporte
  static const int maxPhotosPerReport = 20;
  // Número máximo de conceptos por reporte
  static const int maxItemsPerReport = 50;
  // Tamaño máximo de foto en MB
  static const int maxPhotoSizeMB = 10;

  // ─── OFFLINE ────────────────────────────────────────
  // Nombre de la caja Hive para reportes locales
  static const String hiveBoxReports = 'reports_box';
  static const String hiveBoxConcepts = 'concepts_box';
  static const String hiveBoxSyncQueue = 'sync_queue_box';
  static const String hiveBoxUser = 'user_box';

  // ─── FIRESTORE COLECCIONES ───────────────────────────
  // Nombres exactos de las colecciones en Firestore.
  // Si cambias un nombre aquí, cambia en toda la app.
  static const String collectionUsers = 'users';
  static const String collectionReports = 'reports';
  static const String collectionConcepts = 'concepts';
  static const String collectionCategories = 'categories';
  static const String collectionHighways = 'highways';
  static const String collectionAppConfig = 'app_config';

  // ─── FIRESTORE SUB-COLECCIONES ───────────────────────
  static const String subCollectionItems = 'items';
  static const String subCollectionPhotos = 'photos';
  static const String subCollectionTimeline = 'timeline';

  // ─── ROLES ──────────────────────────────────────────
  static const String roleFieldWorker = 'field_worker';
  static const String roleSupervisor = 'supervisor';
  static const String roleAnalyst = 'analyst';
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';

  // ─── ESTADOS DE REPORTE ─────────────────────────────
  static const String statusDraft = 'draft';
  static const String statusSubmitted = 'submitted';
  static const String statusReviewing = 'reviewing';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // ─── GPS ────────────────────────────────────────────
  // Tiempo de espera para obtener coordenadas GPS (segundos)
  static const int gpsTimeoutSeconds = 30;
  // Precisión mínima aceptable del GPS (metros)
  static const double gpsMinAccuracyMeters = 50;

  // ─── GENERADORES (motor de cálculo) ─────────────────
  // Longitud de tramo de defensa metálica estándar
  static const double defensaMetalicaTramoLength = 3.81; // metros (12.5 ft)
  // Tornillos por tramo de defensa
  static const int defensaMetalicaTornillosPorTramo = 8;
}