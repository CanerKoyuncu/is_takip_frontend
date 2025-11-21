/// PDF Notes Builder
///
/// PDF genel notlar bölümü builder'ı.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../models/job_models.dart';
import '../pdf_styles.dart';

/// PDF notes builder sınıfı
class PdfNotesBuilder {
  PdfNotesBuilder._();

  /// Notes section widget'ı oluşturur
  static pw.Widget build(
    JobOrder job,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Genel Notlar',
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            job.generalNotes!,
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

