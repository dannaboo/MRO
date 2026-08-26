// lib/features/reports/data/models/report_model.dart
//
// Extiende la entidad con serialización para Firestore.
// fromFirestore(): Firestore → DamageReportModel
// toFirestore(): DamageReportModel → Map para guardar

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/report_entity.dart';

class ReportItemModel extends ReportItemEntity {
  const ReportItemModel({
    required super.id,
    required super.conceptId,
    required super.conceptCode,
    required super.conceptName,
    required super.unit,
    required super.quantity,
    required super.unitPrice,
    required super.subtotal,
    super.measureLength,
    super.measureWidth,
    super.measureHeight,
    super.measurePieces,
    super.itemKmStart,
    super.itemKmEnd,
    super.itemBody,
    super.itemLane,
    super.notes,
  });

  factory ReportItemModel.fromMap(Map<String, dynamic> map) {
    return ReportItemModel(
      id: map['id'] as String? ?? const Uuid().v4(),
      conceptId: map['conceptId'] as String? ?? '',
      conceptCode: map['conceptCode'] as String? ?? '',
      conceptName: map['conceptName'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      measureLength: (map['measureLength'] as num?)?.toDouble(),
      measureWidth: (map['measureWidth'] as num?)?.toDouble(),
      measureHeight: (map['measureHeight'] as num?)?.toDouble(),
      measurePieces: map['measurePieces'] as int?,
      itemKmStart: (map['itemKmStart'] as num?)?.toDouble(),
      itemKmEnd: (map['itemKmEnd'] as num?)?.toDouble(),
      itemBody: map['itemBody'] != null
          ? RoadBody.fromString(map['itemBody'] as String)
          : null,
      itemLane: map['itemLane'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'conceptId': conceptId,
        'conceptCode': conceptCode,
        'conceptName': conceptName,
        'unit': unit,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'subtotal': subtotal,
        'measureLength': measureLength,
        'measureWidth': measureWidth,
        'measureHeight': measureHeight,
        'measurePieces': measurePieces,
        'itemKmStart': itemKmStart,
        'itemKmEnd': itemKmEnd,
        'itemBody': itemBody?.value,
        'itemLane': itemLane,
        'notes': notes,
      };
      // Agrega dentro de la clase ReportItemModel, después de toMap():

factory ReportItemModel.fromEntity(ReportItemEntity entity) {
  return ReportItemModel(
    id: entity.id,
    conceptId: entity.conceptId,
    conceptCode: entity.conceptCode,
    conceptName: entity.conceptName,
    unit: entity.unit,
    quantity: entity.quantity,
    unitPrice: entity.unitPrice,
    subtotal: entity.subtotal,
    measureLength: entity.measureLength,
    measureWidth: entity.measureWidth,
    measureHeight: entity.measureHeight,
    measurePieces: entity.measurePieces,
    itemKmStart: entity.itemKmStart,
    itemKmEnd: entity.itemKmEnd,
    itemBody: entity.itemBody,
    itemLane: entity.itemLane,
    notes: entity.notes,
  );
}
}

class DamageReportModel extends DamageReportEntity {
  const DamageReportModel({
    required super.id,
    required super.reportNumber,
    super.sinisterNumber,
    required super.status,
    required super.syncStatus,
    required super.highway,
    required super.kmStart,
    required super.kmEnd,
    required super.body,
    required super.side,
    required super.roadType,
    super.speedLimit,
    required super.accidentDate,
    super.accidentTime,
    super.incidentDescription,
    super.vehicles,
    super.fatalitiesCount,
    super.seriousInjuriesCount,
    super.minorInjuriesCount,
    super.uninjuredCount,
    super.probableCause,
    super.weatherCondition,
    super.surfaceCondition,
    super.lightCondition,
    required super.observations,
    super.location,
    super.locationAddress,
    required super.squadNumber,
    required super.createdBy,
    required super.createdByName,
    super.assignedTo,
    super.approvedBy,
    super.rejectionReason,
    super.items,
    super.subtotal,
    super.tax,
    super.total,
    super.signatureBase64,
    required super.createdAt,
    required super.updatedAt,
    super.submittedAt,
    super.approvedAt,
  });

  // Crea un DamageReportModel desde un DocumentSnapshot de Firestore
  factory DamageReportModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return DamageReportModel(
      id: doc.id,
      reportNumber: d['reportNumber'] as String? ?? '',
      sinisterNumber: d['sinisterNumber'] as String?,
      status: ReportStatus.fromString(d['status'] as String? ?? 'draft'),
      syncStatus: SyncStatus.synced, // Si viene de Firestore, está sincronizado
      highway: d['highway'] as String? ?? '',
      kmStart: (d['kmStart'] as num?)?.toDouble() ?? 0,
      kmEnd: (d['kmEnd'] as num?)?.toDouble() ?? 0,
      body: RoadBody.fromString(d['body'] as String? ?? 'A'),
      side: RoadSide.fromString(d['side'] as String? ?? 'right'),
      roadType: RoadType.fromString(d['roadType'] as String? ?? 'highway'),
      speedLimit: (d['speedLimit'] as num?)?.toDouble(),
      accidentDate: (d['accidentDate'] as Timestamp).toDate(),
      accidentTime: (d['accidentTime'] as Timestamp?)?.toDate(),
      incidentDescription: d['incidentDescription'] as String?,
      vehicles: (d['vehicles'] as List<dynamic>? ?? [])
          .map((v) => _vehicleFromMap(v as Map<String, dynamic>))
          .toList(),
      fatalitiesCount: d['fatalitiesCount'] as int? ?? 0,
      seriousInjuriesCount: d['seriousInjuriesCount'] as int? ?? 0,
      minorInjuriesCount: d['minorInjuriesCount'] as int? ?? 0,
      uninjuredCount: d['uninjuredCount'] as int? ?? 0,
      probableCause: d['probableCause'] as String?,
      weatherCondition: d['weatherCondition'] as String?,
      surfaceCondition: d['surfaceCondition'] as String?,
      lightCondition: d['lightCondition'] as String?,
      observations: d['observations'] as String? ?? '',
      location: d['location'] != null
          ? _geoFromMap(d['location'] as Map<String, dynamic>)
          : null,
      locationAddress: d['locationAddress'] as String?,
      squadNumber: d['squadNumber'] as String? ?? '',
      createdBy: d['createdBy'] as String? ?? '',
      createdByName: d['createdByName'] as String? ?? '',
      assignedTo: d['assignedTo'] as String?,
      approvedBy: d['approvedBy'] as String?,
      rejectionReason: d['rejectionReason'] as String?,
      // Los ítems se guardan en sub-colección, pueden venir vacíos aquí
      items: (d['items'] as List<dynamic>? ?? [])
          .map((i) => ReportItemModel.fromMap(i as Map<String, dynamic>))
          .toList(),
      subtotal: (d['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (d['tax'] as num?)?.toDouble() ?? 0,
      total: (d['total'] as num?)?.toDouble() ?? 0,
      signatureBase64: d['signatureBase64'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate(),
      approvedAt: (d['approvedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Crea un DamageReportModel desde un Map (para Hive)
  factory DamageReportModel.fromMap(Map<String, dynamic> d) {
    return DamageReportModel(
      id: d['id'] as String,
      reportNumber: d['reportNumber'] as String? ?? '',
      sinisterNumber: d['sinisterNumber'] as String?,
      status: ReportStatus.fromString(d['status'] as String? ?? 'draft'),
      syncStatus: SyncStatus.fromString(d['syncStatus'] as String? ?? 'pending'),
      highway: d['highway'] as String? ?? '',
      kmStart: (d['kmStart'] as num?)?.toDouble() ?? 0,
      kmEnd: (d['kmEnd'] as num?)?.toDouble() ?? 0,
      body: RoadBody.fromString(d['body'] as String? ?? 'A'),
      side: RoadSide.fromString(d['side'] as String? ?? 'right'),
      roadType: RoadType.fromString(d['roadType'] as String? ?? 'highway'),
      speedLimit: (d['speedLimit'] as num?)?.toDouble(),
      accidentDate: DateTime.parse(d['accidentDate'] as String),
      accidentTime: d['accidentTime'] != null
          ? DateTime.parse(d['accidentTime'] as String)
          : null,
      incidentDescription: d['incidentDescription'] as String?,
      vehicles: (d['vehicles'] as List<dynamic>? ?? [])
          .map((v) => _vehicleFromMap(v as Map<String, dynamic>))
          .toList(),
      fatalitiesCount: d['fatalitiesCount'] as int? ?? 0,
      seriousInjuriesCount: d['seriousInjuriesCount'] as int? ?? 0,
      minorInjuriesCount: d['minorInjuriesCount'] as int? ?? 0,
      uninjuredCount: d['uninjuredCount'] as int? ?? 0,
      probableCause: d['probableCause'] as String?,
      weatherCondition: d['weatherCondition'] as String?,
      surfaceCondition: d['surfaceCondition'] as String?,
      lightCondition: d['lightCondition'] as String?,
      observations: d['observations'] as String? ?? '',
      location: d['location'] != null
          ? _geoFromMap(d['location'] as Map<String, dynamic>)
          : null,
      locationAddress: d['locationAddress'] as String?,
      squadNumber: d['squadNumber'] as String? ?? '',
      createdBy: d['createdBy'] as String? ?? '',
      createdByName: d['createdByName'] as String? ?? '',
      assignedTo: d['assignedTo'] as String?,
      approvedBy: d['approvedBy'] as String?,
      rejectionReason: d['rejectionReason'] as String?,
      items: (d['items'] as List<dynamic>? ?? [])
          .map((i) => ReportItemModel.fromMap(i as Map<String, dynamic>))
          .toList(),
      subtotal: (d['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (d['tax'] as num?)?.toDouble() ?? 0,
      total: (d['total'] as num?)?.toDouble() ?? 0,
      signatureBase64: d['signatureBase64'] as String?,
      createdAt: DateTime.parse(d['createdAt'] as String),
      updatedAt: DateTime.parse(d['updatedAt'] as String),
      submittedAt: d['submittedAt'] != null
          ? DateTime.parse(d['submittedAt'] as String)
          : null,
      approvedAt: d['approvedAt'] != null
          ? DateTime.parse(d['approvedAt'] as String)
          : null,
    );
  }
  // Dentro de la clase DamageReportModel, agrega este factory:

/// Convierte una DamageReportEntity pura en un DamageReportModel.
/// Lo necesitamos porque el UseCase trabaja con la entidad del dominio
/// pero el repositorio necesita el modelo para serializar.
factory DamageReportModel.fromEntity(DamageReportEntity e) {
  return DamageReportModel(
    id: e.id,
    reportNumber: e.reportNumber,
    sinisterNumber: e.sinisterNumber,
    status: e.status,
    syncStatus: e.syncStatus,
    highway: e.highway,
    kmStart: e.kmStart,
    kmEnd: e.kmEnd,
    body: e.body,
    side: e.side,
    roadType: e.roadType,
    speedLimit: e.speedLimit,
    accidentDate: e.accidentDate,
    accidentTime: e.accidentTime,
    incidentDescription: e.incidentDescription,
    vehicles: e.vehicles,
    fatalitiesCount: e.fatalitiesCount,
    seriousInjuriesCount: e.seriousInjuriesCount,
    minorInjuriesCount: e.minorInjuriesCount,
    uninjuredCount: e.uninjuredCount,
    probableCause: e.probableCause,
    weatherCondition: e.weatherCondition,
    surfaceCondition: e.surfaceCondition,
    lightCondition: e.lightCondition,
    observations: e.observations,
    location: e.location,
    locationAddress: e.locationAddress,
    squadNumber: e.squadNumber,
    createdBy: e.createdBy,
    createdByName: e.createdByName,
    assignedTo: e.assignedTo,
    approvedBy: e.approvedBy,
    rejectionReason: e.rejectionReason,
    items: e.items,
    subtotal: e.subtotal,
    tax: e.tax,
    total: e.total,
    signatureBase64: e.signatureBase64,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
    submittedAt: e.submittedAt,
    approvedAt: e.approvedAt,
  );
}

  // Serializa para Firestore
  Map<String, dynamic> toFirestore() => {
        'reportNumber': reportNumber,
        'sinisterNumber': sinisterNumber,
        'status': status.value,
        'highway': highway,
        'kmStart': kmStart,
        'kmEnd': kmEnd,
        'body': body.value,
        'side': side.value,
        'roadType': roadType.value,
        'speedLimit': speedLimit,
        'accidentDate': Timestamp.fromDate(accidentDate),
        'accidentTime':
            accidentTime != null ? Timestamp.fromDate(accidentTime!) : null,
        'incidentDescription': incidentDescription,
        'vehicles': vehicles.map(_vehicleToMap).toList(),
        'fatalitiesCount': fatalitiesCount,
        'seriousInjuriesCount': seriousInjuriesCount,
        'minorInjuriesCount': minorInjuriesCount,
        'uninjuredCount': uninjuredCount,
        'probableCause': probableCause,
        'weatherCondition': weatherCondition,
        'surfaceCondition': surfaceCondition,
        'lightCondition': lightCondition,
        'observations': observations,
        'location': location != null ? _geoToMap(location!) : null,
        'locationAddress': locationAddress,
        'squadNumber': squadNumber,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'assignedTo': assignedTo,
        'approvedBy': approvedBy,
        'rejectionReason': rejectionReason,
        'items': items
            .map((i) => (i as ReportItemModel).toMap())
            .toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'signatureBase64': signatureBase64,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'submittedAt':
            submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
        'approvedAt':
            approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      };

  // Serializa para Hive (Map con tipos básicos de Dart)
  Map<String, dynamic> toMap() => {
        'id': id,
        'reportNumber': reportNumber,
        'sinisterNumber': sinisterNumber,
        'status': status.value,
        'syncStatus': syncStatus.value,
        'highway': highway,
        'kmStart': kmStart,
        'kmEnd': kmEnd,
        'body': body.value,
        'side': side.value,
        'roadType': roadType.value,
        'speedLimit': speedLimit,
        'accidentDate': accidentDate.toIso8601String(),
        'accidentTime': accidentTime?.toIso8601String(),
        'incidentDescription': incidentDescription,
        'vehicles': vehicles.map(_vehicleToMap).toList(),
        'fatalitiesCount': fatalitiesCount,
        'seriousInjuriesCount': seriousInjuriesCount,
        'minorInjuriesCount': minorInjuriesCount,
        'uninjuredCount': uninjuredCount,
        'probableCause': probableCause,
        'weatherCondition': weatherCondition,
        'surfaceCondition': surfaceCondition,
        'lightCondition': lightCondition,
        'observations': observations,
        'location': location != null ? _geoToMap(location!) : null,
        'locationAddress': locationAddress,
        'squadNumber': squadNumber,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'assignedTo': assignedTo,
        'approvedBy': approvedBy,
        'rejectionReason': rejectionReason,
        'items': items
            .map((i) => (i as ReportItemModel).toMap())
            .toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'signatureBase64': signatureBase64,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'submittedAt': submittedAt?.toIso8601String(),
        'approvedAt': approvedAt?.toIso8601String(),
      };

  static VehicleInfo _vehicleFromMap(Map<String, dynamic> m) => VehicleInfo(
        vehicleType: m['vehicleType'] as String? ?? '',
        model: m['model'] as String?,
        color: m['color'] as String?,
        licensePlate: m['licensePlate'] as String?,
      );

  static Map<String, dynamic> _vehicleToMap(VehicleInfo v) => {
        'vehicleType': v.vehicleType,
        'model': v.model,
        'color': v.color,
        'licensePlate': v.licensePlate,
      };

  static GeoLocation _geoFromMap(Map<String, dynamic> m) => GeoLocation(
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        accuracy: (m['accuracy'] as num?)?.toDouble(),
      );

  static Map<String, dynamic> _geoToMap(GeoLocation g) => {
        'latitude': g.latitude,
        'longitude': g.longitude,
        'accuracy': g.accuracy,
      };
}