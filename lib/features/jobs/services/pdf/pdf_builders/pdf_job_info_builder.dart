/// PDF Info Section Builder
///
/// PDF bilgi bölümleri (İş Emri Bilgileri, Kabul Bilgileri vb.) için builder.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../pdf_styles.dart';
import 'pdf_helper_widgets.dart';

/// PDF bilgi bölümü builder sınıfı
class PdfInfoSectionBuilder {
  PdfInfoSectionBuilder._();

  /// Bilgi bölümü widget'ı oluşturur
  static pw.Widget build({
    required String title,
    required Map<String, String> data,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    final entries = data.entries.toList();

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 0,
            runSpacing: 4,
            children: entries.map((entry) {
              return pw.Container(
                width: 240, // Two columns roughly
                child: PdfHelperWidgets.buildInfoItem(
                  entry.key,
                  entry.value,
                  regularFont,
                  boldFont,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
