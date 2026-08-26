// lib/features/reports/presentation/providers/pdf_provider.dart


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../reports/domain/entities/report_entity.dart';
import '../../../reports/domain/usecases/generate_pdf_usecase.dart';

final generatePdfUseCaseProvider = Provider<GeneratePdfUseCase>((ref) {
  return GeneratePdfUseCase();
});

class PdfState {
  final bool isGenerating;
  final String? error;
  const PdfState({this.isGenerating = false, this.error});
}

class PdfNotifier extends FamilyNotifier<PdfState, String> {
  @override
  PdfState build(String arg) => const PdfState();

  Future<void> generateAndShare(DamageReportEntity report) async {
    state = const PdfState(isGenerating: true);
    try {
      final bytes = await ref
          .read(generatePdfUseCaseProvider)
          .call(report);
      // Abre el diálogo nativo de impresión/compartir
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${report.reportNumber}.pdf',
      );
      state = const PdfState();
    } catch (e) {
      state = PdfState(error: 'Error al generar PDF: $e');
    }
  }

  Future<void> printReport(DamageReportEntity report) async {
    state = const PdfState(isGenerating: true);
    try {
      final bytes = await ref
          .read(generatePdfUseCaseProvider)
          .call(report);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: report.reportNumber,
      );
      state = const PdfState();
    } catch (e) {
      state = PdfState(error: 'Error al imprimir: $e');
    }
  }
}

final pdfProvider =
    NotifierProviderFamily<PdfNotifier, PdfState, String>(
  () => PdfNotifier(),
);
