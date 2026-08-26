// lib/features/reports/domain/entities/report_entity.dart
//
// Modela exactamente los campos del formulario MROAM-F-MR-04
// y el formato FORMATO_SINIESTROS_2026.xlsx que usa la empresa.
// Esta entidad es puro Dart — sin Firebase, sin Flutter.

import 'package:equatable/equatable.dart';

// ─── ENUMS DEL DOMINIO ────────────────────────────────────

// Cuerpo de la carretera (del formulario: CPO. A / CPO. B)
enum RoadBody {
  a,
  b;

  String get displayName {
    switch (this) {
      case RoadBody.a: return 'Cuerpo A';
      case RoadBody.b: return 'Cuerpo B';
    }
  }

  String get value {
    switch (this) {
      case RoadBody.a: return 'A';
      case RoadBody.b: return 'B';
    }
  }

  static RoadBody fromString(String v) =>
      v.toUpperCase() == 'B' ? RoadBody.b : RoadBody.a;
}

// Lado de la carretera (del formulario: Derecho / Izquierdo)
enum RoadSide {
  right,
  left,
  both,
  central;

  String get displayName {
    switch (this) {
      case RoadSide.right:   return 'Derecho';
      case RoadSide.left:    return 'Izquierdo';
      case RoadSide.both:    return 'Ambos';
      case RoadSide.central: return 'Central';
    }
  }

  String get value {
    switch (this) {
      case RoadSide.right:   return 'right';
      case RoadSide.left:    return 'left';
      case RoadSide.both:    return 'both';
      case RoadSide.central: return 'central';
    }
  }

  static RoadSide fromString(String v) {
    switch (v.toLowerCase()) {
      case 'left':    return RoadSide.left;
      case 'both':    return RoadSide.both;
      case 'central': return RoadSide.central;
      default:        return RoadSide.right;
    }
  }
}

// Tipo de vía (del campo "Tipo de vía" del formato de siniestros)
enum RoadType {
  freeway,    // Autopista de Cuota
  highway,    // Carretera Federal
  state,      // Carretera Estatal
  urban;      // Vialidad Urbana

  String get displayName {
    switch (this) {
      case RoadType.freeway: return 'Autopista de Cuota';
      case RoadType.highway: return 'Carretera Federal';
      case RoadType.state:   return 'Carretera Estatal';
      case RoadType.urban:   return 'Vialidad Urbana';
    }
  }

  String get value => name;

  static RoadType fromString(String v) =>
      RoadType.values.firstWhere((e) => e.value == v, orElse: () => RoadType.highway);
}

// Estado del reporte — controla el flujo de aprobación
enum ReportStatus {
  draft,       // Borrador: solo en el dispositivo, no enviado
  submitted,   // Enviado: en cola para revisión de oficina
  reviewing,   // En revisión por analista
  approved,    // Aprobado: listo para aseguradora
  rejected;    // Rechazado: requiere correcciones

  String get displayName {
    switch (this) {
      case ReportStatus.draft:      return 'Borrador';
      case ReportStatus.submitted:  return 'Enviado';
      case ReportStatus.reviewing:  return 'En Revisión';
      case ReportStatus.approved:   return 'Aprobado';
      case ReportStatus.rejected:   return 'Rechazado';
    }
  }

  String get value => name;

  static ReportStatus fromString(String v) =>
      ReportStatus.values.firstWhere((e) => e.value == v,
          orElse: () => ReportStatus.draft);

  // Solo un admin puede cambiar a estos estados
  bool get isTerminal => this == ReportStatus.approved || this == ReportStatus.rejected;
}

// Estado de sincronización con Firebase
enum SyncStatus {
  synced,   // Guardado en Firestore
  pending,  // Pendiente de subir (sin internet)
  error;    // Error al sincronizar

  String get value => name;
  static SyncStatus fromString(String v) =>
      SyncStatus.values.firstWhere((e) => e.value == v,
          orElse: () => SyncStatus.pending);
}

// ─── ENTIDAD PRINCIPAL ────────────────────────────────────

class DamageReportEntity extends Equatable {
  // Identificadores
  final String id;
  final String reportNumber;      // MRO-2026-001234 (generado automáticamente)
  final String? sinisterNumber;   // Número de siniestro de la aseguradora

  // Estado del flujo
  final ReportStatus status;
  final SyncStatus syncStatus;

  // Ubicación — campos del formulario MROAM-F-MR-04
  final String highway;           // Nombre/código de carretera (MEX-57)
  final double kmStart;           // KM Inicial (21+525 → 21.525)
  final double kmEnd;             // KM Final   (21+530 → 21.530)
  final RoadBody body;            // Cuerpo A o B
  final RoadSide side;            // Derecho / Izquierdo / Ambos
  final RoadType roadType;        // Tipo de vía
  final double? speedLimit;       // Velocidad límite (110 km/h)

  // Datos del accidente — del formato de siniestros
  final DateTime accidentDate;    // Fecha del accidente
  final DateTime? accidentTime;   // Hora del siniestro
  final String? incidentDescription; // Descripción / narración del accidente

  // Vehículos involucrados (lista porque pueden ser varios)
  final List<VehicleInfo> vehicles;

  // Víctimas
  final int fatalitiesCount;
  final int seriousInjuriesCount;
  final int minorInjuriesCount;
  final int uninjuredCount;
  final String? probableCause;    // Causa probable del accidente

  // Condiciones del accidente
  final String? weatherCondition;
  final String? surfaceCondition;
  final String? lightCondition;

  // Observaciones generales (del campo "ACTIVIDAD REALIZADA")
  final String observations;

  // GPS
  final GeoLocation? location;     // Coordenadas exactas donde se capturó
  final String? locationAddress;   // Dirección legible

  // Cuadrilla
  final String squadNumber;        // No. de cuadrilla (del formulario: #03)
  final String createdBy;          // userId del cuadrillero
  final String createdByName;      // Nombre legible
  final String? assignedTo;        // userId del analista asignado
  final String? approvedBy;        // userId del administrador
  final String? rejectionReason;   // Motivo de rechazo (si aplica)

  // Conceptos e ítems del reporte
  final List<ReportItemEntity> items;

  // Totales calculados
  final double subtotal;
  final double tax;
  final double total;

  // Firma digital del cuadrillero/supervisor (base64 PNG)
  final String? signatureBase64;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;

  const DamageReportEntity({
    required this.id,
    required this.reportNumber,
    this.sinisterNumber,
    required this.status,
    required this.syncStatus,
    required this.highway,
    required this.kmStart,
    required this.kmEnd,
    required this.body,
    required this.side,
    required this.roadType,
    this.speedLimit,
    required this.accidentDate,
    this.accidentTime,
    this.incidentDescription,
    this.vehicles = const [],
    this.fatalitiesCount = 0,
    this.seriousInjuriesCount = 0,
    this.minorInjuriesCount = 0,
    this.uninjuredCount = 0,
    this.probableCause,
    this.weatherCondition,
    this.surfaceCondition,
    this.lightCondition,
    required this.observations,
    this.location,
    this.locationAddress,
    required this.squadNumber,
    required this.createdBy,
    required this.createdByName,
    this.assignedTo,
    this.approvedBy,
    this.rejectionReason,
    this.items = const [],
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.total = 0.0,
    this.signatureBase64,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.approvedAt,
  });

  // Calcula el rango de KM en formato legible: "21+525 — 21+530"
  String get kmRangeDisplay {
    return '${_kmToDisplay(kmStart)} — ${_kmToDisplay(kmEnd)}';
  }

  // Convierte 21.525 → "21+525"
  String _kmToDisplay(double km) {
    final whole = km.floor();
    final decimal = ((km - whole) * 1000).round();
    return '$whole+${decimal.toString().padLeft(3, '0')}';
  }

  // Convierte "21+525" → 21.525
  static double kmFromDisplay(String display) {
    // Acepta formato "21+525" o "21.525"
    if (display.contains('+')) {
      final parts = display.split('+');
      final whole = double.tryParse(parts[0]) ?? 0;
      final decimal = double.tryParse(parts[1]) ?? 0;
      return whole + (decimal / 1000);
    }
    return double.tryParse(display) ?? 0;
  }

  bool get isDraft => status == ReportStatus.draft;
  bool get isSubmitted => status == ReportStatus.submitted;
  bool get isPendingSync => syncStatus == SyncStatus.pending;

  int get totalItems => items.length;

  DamageReportEntity copyWith({
    String? id,
    String? reportNumber,
    String? sinisterNumber,
    ReportStatus? status,
    SyncStatus? syncStatus,
    String? highway,
    double? kmStart,
    double? kmEnd,
    RoadBody? body,
    RoadSide? side,
    RoadType? roadType,
    double? speedLimit,
    DateTime? accidentDate,
    DateTime? accidentTime,
    String? incidentDescription,
    List<VehicleInfo>? vehicles,
    int? fatalitiesCount,
    int? seriousInjuriesCount,
    int? minorInjuriesCount,
    int? uninjuredCount,
    String? probableCause,
    String? weatherCondition,
    String? surfaceCondition,
    String? lightCondition,
    String? observations,
    GeoLocation? location,
    String? locationAddress,
    String? squadNumber,
    String? createdBy,
    String? createdByName,
    String? assignedTo,
    String? approvedBy,
    String? rejectionReason,
    List<ReportItemEntity>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? signatureBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? approvedAt,
  }) {
    return DamageReportEntity(
      id: id ?? this.id,
      reportNumber: reportNumber ?? this.reportNumber,
      sinisterNumber: sinisterNumber ?? this.sinisterNumber,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      highway: highway ?? this.highway,
      kmStart: kmStart ?? this.kmStart,
      kmEnd: kmEnd ?? this.kmEnd,
      body: body ?? this.body,
      side: side ?? this.side,
      roadType: roadType ?? this.roadType,
      speedLimit: speedLimit ?? this.speedLimit,
      accidentDate: accidentDate ?? this.accidentDate,
      accidentTime: accidentTime ?? this.accidentTime,
      incidentDescription: incidentDescription ?? this.incidentDescription,
      vehicles: vehicles ?? this.vehicles,
      fatalitiesCount: fatalitiesCount ?? this.fatalitiesCount,
      seriousInjuriesCount: seriousInjuriesCount ?? this.seriousInjuriesCount,
      minorInjuriesCount: minorInjuriesCount ?? this.minorInjuriesCount,
      uninjuredCount: uninjuredCount ?? this.uninjuredCount,
      probableCause: probableCause ?? this.probableCause,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      surfaceCondition: surfaceCondition ?? this.surfaceCondition,
      lightCondition: lightCondition ?? this.lightCondition,
      observations: observations ?? this.observations,
      location: location ?? this.location,
      locationAddress: locationAddress ?? this.locationAddress,
      squadNumber: squadNumber ?? this.squadNumber,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      assignedTo: assignedTo ?? this.assignedTo,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  @override
  List<Object?> get props => [id, reportNumber, status, syncStatus, updatedAt];
}

// ─── ENTIDADES AUXILIARES ─────────────────────────────────

// Ítem del reporte: un concepto del catálogo aplicado con sus medidas
class ReportItemEntity extends Equatable {
  final String id;
  final String conceptId;
  final String conceptCode;       // D.1.2 (del tabulador)
  final String conceptName;       // "Suministro y colocación de Defensa Metálica..."
  final String unit;              // M, PZA, M2, M3
  final double quantity;          // Resultado del generador
  final double unitPrice;         // Del tabulador
  final double subtotal;          // quantity × unitPrice

  // Medidas del generador (del sheet GENERADORES)
  final double? measureLength;    // LARGO
  final double? measureWidth;     // ANCHO
  final double? measureHeight;    // ALTO
  final int? measurePieces;       // PIEZAS
  // Localización específica del ítem
  final double? itemKmStart;
  final double? itemKmEnd;
  final RoadBody? itemBody;
  final String? itemLane;         // LADO / CARRIL

  final String? notes;

  const ReportItemEntity({
    required this.id,
    required this.conceptId,
    required this.conceptCode,
    required this.conceptName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.measureLength,
    this.measureWidth,
    this.measureHeight,
    this.measurePieces,
    this.itemKmStart,
    this.itemKmEnd,
    this.itemBody,
    this.itemLane,
    this.notes,
  });

  @override
  List<Object?> get props => [id, conceptId, quantity, subtotal];
}

// Información de un vehículo involucrado en el accidente
class VehicleInfo extends Equatable {
  final String vehicleType;   // Tipo de vehículo
  final String? model;
  final String? color;
  final String? licensePlate;

  const VehicleInfo({
    required this.vehicleType,
    this.model,
    this.color,
    this.licensePlate,
  });

  @override
  List<Object?> get props => [vehicleType, licensePlate];
}

// Coordenadas GPS
class GeoLocation extends Equatable {
  final double latitude;
  final double longitude;
  final double? accuracy;   // Precisión en metros

  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  @override
  List<Object?> get props => [latitude, longitude];

  @override
  String toString() => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}
