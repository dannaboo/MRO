// lib/features/reports/domain/usecases/generate_pdf_usecase.dart

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/constants/app_constants.dart';
import '../entities/report_entity.dart';

class GeneratePdfUseCase {
  // Colores reutilizables como constantes de clase
  static final _white = PdfColors.white;
  // PdfColors no tiene white70, usamos PdfColor con opacidad
  static final _white70 = PdfColor(1, 1, 1, 0.7);
  static final _primary = PdfColor.fromHex('#1565C0');

  static final _lightGray = PdfColor.fromHex('#F5F7FA');
  static final _borderGray = PdfColor.fromHex('#E0E7FF');
  static final _successGreen = PdfColor.fromHex('#2E7D32');
  static final _textSecondary = PdfColor.fromHex('#6B7280');
  static final _yellowAccent = PdfColor.fromHex('#FFD54F');

  Future<Uint8List> call(DamageReportEntity report) async {
    final pdf = pw.Document();
    final currency =
        NumberFormat.currency(locale: 'es_MX', symbol: '\$');
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_MX');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        header: (context) =>
            _buildHeader(report, dateFormat),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // ─── DATOS DEL SINIESTRO ────────────────────
          _sectionTitle('DATOS DEL SINIESTRO'),
          pw.SizedBox(height: 8),
          _infoTable([
            [
              'Carretera / Ruta',
              report.highway,
              'Fecha del Siniestro',
              dateFormat.format(report.accidentDate),
            ],
            [
              'KM Inicial',
              _kmDisplay(report.kmStart),
              'KM Final',
              _kmDisplay(report.kmEnd),
            ],
            [
              'Cuerpo',
              report.body.displayName,
              'Lado',
              report.side.displayName,
            ],
            [
              'Tipo de Vía',
              report.roadType.displayName,
              'Vel. Límite',
              report.speedLimit != null
                  ? '${report.speedLimit!.toInt()} km/h'
                  : 'N/E',
            ],
          ]),
          pw.SizedBox(height: 12),

          // ─── AFECTACIONES ───────────────────────────
          if (report.fatalitiesCount > 0 ||
              report.seriousInjuriesCount > 0 ||
              report.vehicles.isNotEmpty) ...[
            _sectionTitle('AFECTACIONES'),
            pw.SizedBox(height: 8),
            _infoTable([
              [
                'Muertos',
                '${report.fatalitiesCount}',
                'Heridos Graves',
                '${report.seriousInjuriesCount}',
              ],
              [
                'Heridos Leves',
                '${report.minorInjuriesCount}',
                'Ilesos',
                '${report.uninjuredCount}',
              ],
              if (report.probableCause != null)
                ['Causa Probable', report.probableCause!, '', ''],
            ]),
            pw.SizedBox(height: 12),
          ],

          // ─── ACTIVIDAD REALIZADA ────────────────────
          _sectionTitle('ACTIVIDAD REALIZADA'),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _lightGray,
              border: pw.Border.all(color: _borderGray),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              report.observations,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.SizedBox(height: 12),

          // ─── CONCEPTOS DE DAÑO ──────────────────────
          if (report.items.isNotEmpty) ...[
            _sectionTitle('CONCEPTOS DE DAÑO Y REPARACIÓN'),
            pw.SizedBox(height: 8),
            _itemsTable(report.items, currency),
            pw.SizedBox(height: 12),
            _totalsTable(report, currency),
            pw.SizedBox(height: 16),
          ],

          // ─── RESPONSABLES ───────────────────────────
          _sectionTitle('RESPONSABLES'),
          pw.SizedBox(height: 8),
          _infoTable([
            [
              'No. Cuadrilla',
              '#${report.squadNumber}',
              'Elaboró',
              report.createdByName,
            ],
            [
              'Estado',
              report.status.displayName,
              'Cuadrillero ID',
              report.createdBy.length > 8
                  ? report.createdBy.substring(0, 8)
                  : report.createdBy,
            ],
          ]),
          pw.SizedBox(height: 24),

          // ─── FIRMAS ─────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _signatureLine('Elaboró', report.createdByName),
              _signatureLine('Revisó', '_____________________'),
              _signatureLine('Autorizó', '_____________________'),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ─── HEADER ──────────────────────────────────────────

  pw.Widget _buildHeader(
    DamageReportEntity report,
    DateFormat dateFormat,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MRO',
                  style: pw.TextStyle(
                    color: _white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  AppConstants.companyName,
                  style: pw.TextStyle(color: _white70, fontSize: 7),
                ),
                pw.Text(
                  'Contrato: ${AppConstants.contractNumber}',
                  style: pw.TextStyle(color: _white70, fontSize: 7),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'REPORTE DE SINIESTRO',
                style: pw.TextStyle(
                  color: _white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                report.reportNumber,
                style: pw.TextStyle(
                  color: _yellowAccent,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Fecha: ${dateFormat.format(report.createdAt)}',
                style: pw.TextStyle(color: _white70, fontSize: 8),
              ),
              pw.SizedBox(height: 4),
              _statusBadge(report.status),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _statusBadge(ReportStatus status) {
    final colors = {
      ReportStatus.draft:      PdfColors.grey,
      ReportStatus.submitted:  PdfColor.fromHex('#1976D2'),
      ReportStatus.reviewing:  PdfColor.fromHex('#F57C00'),
      ReportStatus.approved:   PdfColor.fromHex('#2E7D32'),
      ReportStatus.rejected:   PdfColor.fromHex('#C62828'),
    };
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: colors[status] ?? PdfColors.grey,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text(
        status.displayName.toUpperCase(),
        style: pw.TextStyle(
          color: _white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  // ─── FOOTER ──────────────────────────────────────────

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Sistema MRO Damage Report · Generado automáticamente',
            style: pw.TextStyle(fontSize: 7, color: _textSecondary),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 7, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── SECCIÓN TÍTULO ──────────────────────────────────

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: _white,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  // ─── TABLA DE INFORMACIÓN ────────────────────────────

  pw.Widget _infoTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      children: rows.map((row) {
        return pw.TableRow(
          children: List.generate(
            row.length,
            (i) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8, vertical: 5),
              color: i.isEven ? _lightGray : PdfColors.white,
              child: pw.Text(
                row[i],
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: i.isEven
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  color: i.isEven ? _primary : PdfColors.black,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── TABLA DE ÍTEMS ──────────────────────────────────

  pw.Widget _itemsTable(
    List<ReportItemEntity> items,
    NumberFormat currency,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _borderGray, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FixedColumnWidth(50),
        2: const pw.FlexColumnWidth(3),
        3: const pw.FixedColumnWidth(35),
        4: const pw.FixedColumnWidth(50),
        5: const pw.FixedColumnWidth(70),
        6: const pw.FixedColumnWidth(75),
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _primary),
          children: ['#', 'Clave', 'Concepto', 'Ud.',
                     'Cant.', 'P.U. c/IVA', 'Importe']
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4, vertical: 5),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      color: _white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              )
              .toList(),
        ),
        // Filas de datos
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final bgColor = i.isEven ? _lightGray : PdfColors.white;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bgColor),
            children: [
              _cell('${i + 1}', center: true),
              _cell(item.conceptCode,
                  bold: true, color: _primary),
              _cell(item.conceptName, small: true),
              _cell(item.unit, center: true),
              _cell(
                NumberFormat('#,##0.##', 'es_MX')
                    .format(item.quantity),
                center: true,
              ),
              _cell(currency.format(item.unitPrice), right: true),
              _cell(currency.format(item.subtotal),
                  right: true, bold: true),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _cell(
    String text, {
    bool center = false,
    bool right = false,
    bool bold = false,
    bool small = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: small ? 7 : 9,
          fontWeight:
              bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
        textAlign: center
            ? pw.TextAlign.center
            : right
                ? pw.TextAlign.right
                : pw.TextAlign.left,
        maxLines: small ? 2 : 1,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  // ─── TABLA DE TOTALES ────────────────────────────────

  pw.Widget _totalsTable(
    DamageReportEntity report,
    NumberFormat currency,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
                color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              _totalRow(
                'Subtotal sin IVA:',
                currency.format(report.total / 1.16),
                _lightGray,
              ),
              _totalRow(
                'IVA (16%):',
                currency.format(report.tax),
                _lightGray,
              ),
              _totalRow(
                'TOTAL CON IVA:',
                currency.format(report.total),
                PdfColor.fromHex('#E8F5E9'),
                bold: true,
                valueColor: _successGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _totalRow(
    String label,
    String value,
    PdfColor bg, {
    bool bold = false,
    PdfColor? valueColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      color: bg,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: bold ? 10 : 9,
              fontWeight: bold
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: bold ? 11 : 9,
              fontWeight: bold
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              color: valueColor ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ─── LÍNEA DE FIRMA ──────────────────────────────────

  pw.Widget _signatureLine(String role, String name) {
    return pw.Column(
      children: [
        pw.Container(width: 140, height: 1, color: _primary),
        pw.SizedBox(height: 4),
        pw.Text(name, style: const pw.TextStyle(fontSize: 8)),
        pw.Text(
          role,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
          ),
        ),
      ],
    );
  }

  // ─── UTILIDADES ──────────────────────────────────────

  String _kmDisplay(double km) {
    final whole = km.floor();
    final decimal = ((km - whole) * 1000).round();
    return '$whole+${decimal.toString().padLeft(3, '0')}';
  }
}