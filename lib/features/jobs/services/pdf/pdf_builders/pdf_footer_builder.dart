/// PDF Footer Builder
///
/// PDF footer bölümü builder'ı.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_helper_widgets.dart';

/// PDF footer builder sınıfı
class PdfFooterBuilder {
  PdfFooterBuilder._();

  /// Footer widget'ı oluşturur
  static pw.Widget build({
    required Map<String, int> stats,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: stats.entries.map((entry) {
          return PdfHelperWidgets.buildStatItem(
            entry.key,
            entry.value,
            regularFont,
            boldFont,
          );
        }).toList(),
      ),
    );
  }
}
