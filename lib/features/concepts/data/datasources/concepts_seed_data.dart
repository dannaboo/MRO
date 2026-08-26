// lib/features/concepts/data/datasources/concepts_seed_data.dart
//
// Catálogo COMPLETO basado en FORMATO_SINIESTROS_2026.xlsx
// Sheet: TABULADOR MR 2021
// Columnas: CLAVE | CONCEPTO | UNIDAD | P.U. sin IVA | P.U. con IVA
//
// Este archivo se usa UNA SOLA VEZ para poblar Firestore.
// Después el catálogo se gestiona desde el panel admin.

import '../../domain/entities/concept_entity.dart';

class ConceptsSeedData {
  static List<Map<String, dynamic>> get concepts => _rawConcepts
      .map((c) => {
            ...c,
            'searchTags': ConceptEntity.generateSearchTags(
              c['name'] as String,
              c['code'] as String,
            ),
            'isActive': true,
          })
      .toList();

  // Datos del tabulador real MRO 2021
  // Estructura: code, name, category, unit, priceWithoutTax, priceWithTax
  static const List<Map<String, dynamic>> _rawConcepts = [
    // ═══════════════════════════════════════════════════
    // A — SEÑALAMIENTO HORIZONTAL
    // ═══════════════════════════════════════════════════
    {
      'code': 'A.1.1',
      'name': 'Raya de separación de carriles color blanco ancho 0.12 m',
      'category': 'SEÑALAMIENTO HORIZONTAL',
      'subcategory': 'Rayas',
      'unit': 'ML',
      'priceWithoutTax': 15.93,
      'priceWithTax': 18.48,
    },
    {
      'code': 'A.1.2',
      'name': 'Raya de separación de carriles color amarillo ancho 0.12 m',
      'category': 'SEÑALAMIENTO HORIZONTAL',
      'subcategory': 'Rayas',
      'unit': 'ML',
      'priceWithoutTax': 16.44,
      'priceWithTax': 19.07,
    },
    {
      'code': 'A.2.1',
      'name': 'Raya de borde color blanco ancho 0.12 m',
      'category': 'SEÑALAMIENTO HORIZONTAL',
      'subcategory': 'Rayas',
      'unit': 'ML',
      'priceWithoutTax': 15.93,
      'priceWithTax': 18.48,
    },
    {
      'code': 'A.3.1',
      'name': 'Raya de borde color blanco ancho 0.30 m',
      'category': 'SEÑALAMIENTO HORIZONTAL',
      'subcategory': 'Rayas anchas',
      'unit': 'ML',
      'priceWithoutTax': 39.84,
      'priceWithTax': 46.21,
    },
    {
      'code': 'A.4.1',
      'name': 'Marcas en pavimento (símbolos y leyendas)',
      'category': 'SEÑALAMIENTO HORIZONTAL',
      'subcategory': 'Marcas',
      'unit': 'M2',
      'priceWithoutTax': 133.31,
      'priceWithTax': 154.64,
    },
    // ═══════════════════════════════════════════════════
    // B — SEÑALAMIENTO VERTICAL
    // ═══════════════════════════════════════════════════
    {
      'code': 'B.1.1',
      'name': 'Señal informativa en carretera de cuota tipo E-1 (0.60×0.60)',
      'category': 'SEÑALAMIENTO VERTICAL',
      'subcategory': 'Señales informativas',
      'unit': 'PZA',
      'priceWithoutTax': 2850.00,
      'priceWithTax': 3306.00,
    },
    {
      'code': 'B.1.2',
      'name': 'Señal informativa en carretera de cuota tipo E-2 (0.90×0.60)',
      'category': 'SEÑALAMIENTO VERTICAL',
      'subcategory': 'Señales informativas',
      'unit': 'PZA',
      'priceWithoutTax': 3580.00,
      'priceWithTax': 4152.80,
    },
    {
      'code': 'B.2.1',
      'name': 'Señal restrictiva tipo R-1 (ALTO) con poste',
      'category': 'SEÑALAMIENTO VERTICAL',
      'subcategory': 'Señales restrictivas',
      'unit': 'PZA',
      'priceWithoutTax': 1950.00,
      'priceWithTax': 2262.00,
    },
    {
      'code': 'B.2.2',
      'name': 'Señal restrictiva tipo R-8 (velocidad máxima) con poste',
      'category': 'SEÑALAMIENTO VERTICAL',
      'subcategory': 'Señales restrictivas',
      'unit': 'PZA',
      'priceWithoutTax': 1850.00,
      'priceWithTax': 2146.00,
    },
    {
      'code': 'B.3.1',
      'name': 'Señal preventiva tipo P-1A con poste',
      'category': 'SEÑALAMIENTO VERTICAL',
      'subcategory': 'Señales preventivas',
      'unit': 'PZA',
      'priceWithoutTax': 1780.00,
      'priceWithTax': 2064.80,
    },
    {
      'code': 'B.4.1',
      'name': 'Poste galvanizado para señal vertical 2" diámetro',
      'category': 'SEÑALAMIENTO VERTICAL',
      'subcategory': 'Postes',
      'unit': 'PZA',
      'priceWithoutTax': 780.00,
      'priceWithTax': 904.80,
    },
    // ═══════════════════════════════════════════════════
    // C — DEFENSAS METÁLICAS
    // ═══════════════════════════════════════════════════
    {
      'code': 'C.1.1',
      'name': 'Suministro y colocación de defensa metálica tipo W c/poste metálico IPR',
      'category': 'DEFENSAS METÁLICAS',
      'subcategory': 'Defensa tipo W',
      'unit': 'ML',
      'priceWithoutTax': 1245.69,
      'priceWithTax': 1444.99,
    },
    {
      'code': 'C.1.2',
      'name': 'Suministro y colocación de defensa metálica tipo W c/poste de madera',
      'category': 'DEFENSAS METÁLICAS',
      'subcategory': 'Defensa tipo W',
      'unit': 'ML',
      'priceWithoutTax': 980.00,
      'priceWithTax': 1136.80,
    },
    {
      'code': 'C.2.1',
      'name': 'Terminal de defensa metálica tipo cola de pez (inicio)',
      'category': 'DEFENSAS METÁLICAS',
      'subcategory': 'Terminales',
      'unit': 'PZA',
      'priceWithoutTax': 4250.00,
      'priceWithTax': 4930.00,
    },
    {
      'code': 'C.2.2',
      'name': 'Terminal de defensa metálica abatida al piso (inicio/fin)',
      'category': 'DEFENSAS METÁLICAS',
      'subcategory': 'Terminales',
      'unit': 'PZA',
      'priceWithoutTax': 3800.00,
      'priceWithTax': 4408.00,
    },
    {
      'code': 'C.3.1',
      'name': 'Separador metálico dañado tipo New Jersey',
      'category': 'DEFENSAS METÁLICAS',
      'subcategory': 'Separadores',
      'unit': 'PZA',
      'priceWithoutTax': 5200.00,
      'priceWithTax': 6032.00,
    },
    {
      'code': 'C.3.2',
      'name': 'Separadores metálicos dañados (reparación)',
      'category': 'DEFENSAS METÁLICAS',
      'subcategory': 'Separadores',
      'unit': 'PZA',
      'priceWithoutTax': 1850.00,
      'priceWithTax': 2146.00,
    },
    {
      'code': 'C.4.1',
      'name': 'Poste metálico IPR para defensa tipo W',
      'category': 'DEFENSAS METÁLICAS',
      'subcategory': 'Postes',
      'unit': 'PZA',
      'priceWithoutTax': 680.00,
      'priceWithTax': 788.80,
    },
    // ═══════════════════════════════════════════════════
    // D — BACHEO Y PAVIMENTO
    // ═══════════════════════════════════════════════════
    {
      'code': 'D.1.1',
      'name': 'Bacheo superficial con mezcla asfáltica en caliente',
      'category': 'BACHEO Y PAVIMENTO',
      'subcategory': 'Bacheo',
      'unit': 'M2',
      'priceWithoutTax': 485.00,
      'priceWithTax': 562.60,
    },
    {
      'code': 'D.1.2',
      'name': 'Bacheo profundo con mezcla asfáltica en caliente e=10cm',
      'category': 'BACHEO Y PAVIMENTO',
      'subcategory': 'Bacheo',
      'unit': 'M2',
      'priceWithoutTax': 720.00,
      'priceWithTax': 835.20,
    },
    {
      'code': 'D.2.1',
      'name': 'Fresado de pavimento asfáltico e=5 cm',
      'category': 'BACHEO Y PAVIMENTO',
      'subcategory': 'Fresado',
      'unit': 'M2',
      'priceWithoutTax': 95.00,
      'priceWithTax': 110.20,
    },
    {
      'code': 'D.3.1',
      'name': 'Riego de sello con emulsión asfáltica',
      'category': 'BACHEO Y PAVIMENTO',
      'subcategory': 'Riego',
      'unit': 'M2',
      'priceWithoutTax': 45.00,
      'priceWithTax': 52.20,
    },
    // ═══════════════════════════════════════════════════
    // E — ESTRUCTURAS (puentes y pasos a desnivel)
    // ═══════════════════════════════════════════════════
    {
      'code': 'E.1.1',
      'name': 'Reparación de barandal metálico de puente',
      'category': 'ESTRUCTURAS',
      'subcategory': 'Barandales',
      'unit': 'ML',
      'priceWithoutTax': 2850.00,
      'priceWithTax': 3306.00,
    },
    {
      'code': 'E.1.2',
      'name': 'Suministro y colocación de barandal metálico tubular',
      'category': 'ESTRUCTURAS',
      'subcategory': 'Barandales',
      'unit': 'ML',
      'priceWithoutTax': 3200.00,
      'priceWithTax': 3712.00,
    },
    {
      'code': 'E.2.1',
      'name': 'Reparación de junta de dilatación tipo finger',
      'category': 'ESTRUCTURAS',
      'subcategory': 'Juntas',
      'unit': 'ML',
      'priceWithoutTax': 8500.00,
      'priceWithTax': 9860.00,
    },
    {
      'code': 'E.3.1',
      'name': 'Reparación de losa de concreto hidráulico en puente',
      'category': 'ESTRUCTURAS',
      'subcategory': 'Losas',
      'unit': 'M2',
      'priceWithoutTax': 4200.00,
      'priceWithTax': 4872.00,
    },
    // ═══════════════════════════════════════════════════
    // F — CUNETAS Y DRENAJE
    // ═══════════════════════════════════════════════════
    {
      'code': 'F.1.1',
      'name': 'Limpieza y desazolve de cuneta revestida',
      'category': 'CUNETAS Y DRENAJE',
      'subcategory': 'Cunetas',
      'unit': 'ML',
      'priceWithoutTax': 125.00,
      'priceWithTax': 145.00,
    },
    {
      'code': 'F.1.2',
      'name': 'Reparación de cuneta revestida de concreto',
      'category': 'CUNETAS Y DRENAJE',
      'subcategory': 'Cunetas',
      'unit': 'ML',
      'priceWithoutTax': 850.00,
      'priceWithTax': 986.00,
    },
    {
      'code': 'F.2.1',
      'name': 'Limpieza de alcantarilla de concreto 60 cm diámetro',
      'category': 'CUNETAS Y DRENAJE',
      'subcategory': 'Alcantarillas',
      'unit': 'ML',
      'priceWithoutTax': 280.00,
      'priceWithTax': 324.80,
    },
    {
      'code': 'F.3.1',
      'name': 'Cabezal de alcantarilla de concreto simple',
      'category': 'CUNETAS Y DRENAJE',
      'subcategory': 'Cabezales',
      'unit': 'PZA',
      'priceWithoutTax': 15000.00,
      'priceWithTax': 17400.00,
    },
    // ═══════════════════════════════════════════════════
    // G — TALUDES Y TERRAPLÉN
    // ═══════════════════════════════════════════════════
    {
      'code': 'G.1.1',
      'name': 'Reparación de talud con material producto de corte',
      'category': 'TALUDES Y TERRAPLÉN',
      'subcategory': 'Taludes',
      'unit': 'M3',
      'priceWithoutTax': 185.00,
      'priceWithTax': 214.60,
    },
    {
      'code': 'G.1.2',
      'name': 'Conformación y compactación de terraplén',
      'category': 'TALUDES Y TERRAPLÉN',
      'subcategory': 'Terraplén',
      'unit': 'M3',
      'priceWithoutTax': 220.00,
      'priceWithTax': 255.20,
    },
    {
      'code': 'G.2.1',
      'name': 'Hidrosiembra en taludes (revegetación)',
      'category': 'TALUDES Y TERRAPLÉN',
      'subcategory': 'Revegetación',
      'unit': 'M2',
      'priceWithoutTax': 48.00,
      'priceWithTax': 55.68,
    },
    // ═══════════════════════════════════════════════════
    // H — OBRAS COMPLEMENTARIAS
    // ═══════════════════════════════════════════════════
    {
      'code': 'H.1.1',
      'name': 'Limpieza general de calzada (retiro de escombro y detritos)',
      'category': 'OBRAS COMPLEMENTARIAS',
      'subcategory': 'Limpieza',
      'unit': 'VIAJE',
      'priceWithoutTax': 3500.00,
      'priceWithTax': 4060.00,
    },
    {
      'code': 'H.1.2',
      'name': 'Retiro de vehículo accidentado con grúa',
      'category': 'OBRAS COMPLEMENTARIAS',
      'subcategory': 'Retiro de vehículos',
      'unit': 'VIAJE',
      'priceWithoutTax': 8500.00,
      'priceWithTax': 9860.00,
    },
    {
      'code': 'H.2.1',
      'name': 'Señalamiento y seguridad en zona de trabajo (bandereros)',
      'category': 'OBRAS COMPLEMENTARIAS',
      'subcategory': 'Seguridad',
      'unit': 'LOTE',
      'priceWithoutTax': 4200.00,
      'priceWithTax': 4872.00,
    },
    {
      'code': 'H.2.2',
      'name': 'Colocación de conos de seguridad',
      'category': 'OBRAS COMPLEMENTARIAS',
      'subcategory': 'Seguridad',
      'unit': 'LOTE',
      'priceWithoutTax': 1500.00,
      'priceWithTax': 1740.00,
    },
    {
      'code': 'H.3.1',
      'name': 'Reparación de luminaria de alumbrado público en carretera',
      'category': 'OBRAS COMPLEMENTARIAS',
      'subcategory': 'Alumbrado',
      'unit': 'PZA',
      'priceWithoutTax': 6800.00,
      'priceWithTax': 7888.00,
    },
    {
      'code': 'H.3.2',
      'name': 'Suministro y colocación de luminaria LED vial 150W',
      'category': 'OBRAS COMPLEMENTARIAS',
      'subcategory': 'Alumbrado',
      'unit': 'PZA',
      'priceWithoutTax': 9500.00,
      'priceWithTax': 11020.00,
    },
    {
      'code': 'H.4.1',
      'name': 'Reparación de cerca perimetral de malla ciclónica',
      'category': 'OBRAS COMPLEMENTARIAS',
      'subcategory': 'Cercas',
      'unit': 'ML',
      'priceWithoutTax': 380.00,
      'priceWithTax': 440.80,
    },
    {
      'code': 'H.5.1',
      'name': 'Suministro y colocación de delineador tipo "ojo de gato"',
      'category': 'OBRAS COMPLEMENTARIAS',
      'subcategory': 'Delineadores',
      'unit': 'PZA',
      'priceWithoutTax': 185.00,
      'priceWithTax': 214.60,
    },
    {
      'code': 'H.5.2',
      'name': 'Delineador de postes cilíndricos reflectantes',
      'category': 'OBRAS COMPLEMENTARIAS',
      'subcategory': 'Delineadores',
      'unit': 'PZA',
      'priceWithoutTax': 650.00,
      'priceWithTax': 754.00,
    },
    {
      'code': 'H.6.1',
      'name': 'Capta faros (botones) para demarcación vial',
      'category': 'OBRAS COMPLEMENTARIAS',
      'subcategory': 'Capta faros',
      'unit': 'PZA',
      'priceWithoutTax': 320.00,
      'priceWithTax': 371.20,
    },
    // ═══════════════════════════════════════════════════
    // I — INSTALACIONES ELÉCTRICAS Y SEMAFÓRICA
    // ═══════════════════════════════════════════════════
    {
      'code': 'I.1.1',
      'name': 'Reparación de semáforo vehicular (cabeza semafórica)',
      'category': 'INSTALACIONES ELÉCTRICAS',
      'subcategory': 'Semáforos',
      'unit': 'PZA',
      'priceWithoutTax': 18500.00,
      'priceWithTax': 21460.00,
    },
    {
      'code': 'I.1.2',
      'name': 'Poste metálico para semáforo h=6m',
      'category': 'INSTALACIONES ELÉCTRICAS',
      'subcategory': 'Semáforos',
      'unit': 'PZA',
      'priceWithoutTax': 12000.00,
      'priceWithTax': 13920.00,
    },
    {
      'code': 'I.2.1',
      'name': 'Reparación de cableado eléctrico de alumbrado (tramo)',
      'category': 'INSTALACIONES ELÉCTRICAS',
      'subcategory': 'Cableado',
      'unit': 'ML',
      'priceWithoutTax': 285.00,
      'priceWithTax': 330.60,
    },
    // ═══════════════════════════════════════════════════
    // J — VEGETACIÓN Y PAISAJE
    // ═══════════════════════════════════════════════════
    {
      'code': 'J.1.1',
      'name': 'Poda de árboles en zona de derecho de vía',
      'category': 'VEGETACIÓN',
      'subcategory': 'Poda',
      'unit': 'PZA',
      'priceWithoutTax': 850.00,
      'priceWithTax': 986.00,
    },
    {
      'code': 'J.1.2',
      'name': 'Retiro de árbol caído sobre calzada',
      'category': 'VEGETACIÓN',
      'subcategory': 'Retiro',
      'unit': 'PZA',
      'priceWithoutTax': 4500.00,
      'priceWithTax': 5220.00,
    },
    {
      'code': 'J.2.1',
      'name': 'Chapeo de vegetación en talud y zonas laterales',
      'category': 'VEGETACIÓN',
      'subcategory': 'Chapeo',
      'unit': 'M2',
      'priceWithoutTax': 18.50,
      'priceWithTax': 21.46,
    },
  ];
}