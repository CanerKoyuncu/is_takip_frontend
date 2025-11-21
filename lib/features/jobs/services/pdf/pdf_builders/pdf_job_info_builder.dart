/// PDF Job Info Builder
///
/// PDF iş emri bilgileri bölümü builder'ı.

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../models/job_models.dart';
import '../pdf_styles.dart';
import 'pdf_helper_widgets.dart';

/// PDF job info builder sınıfı
class PdfJobInfoBuilder {
  PdfJobInfoBuilder._();

  /// Job info widget'ı oluşturur
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
            'İş Emri Bilgileri',
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: PdfHelperWidgets.buildInfoItem(
                  'Oluşturulma Tarihi',
                  DateFormat('dd.MM.yyyy HH:mm').format(job.createdAt),
                  regularFont,
                  boldFont,
                ),
              ),
              pw.Expanded(
                child: PdfHelperWidgets.buildInfoItem(
                  'Toplam Görev',
                  '${job.tasks.length} görev',
                  regularFont,
                  boldFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

