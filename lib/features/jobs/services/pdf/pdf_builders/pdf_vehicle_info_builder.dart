/// PDF Vehicle Info Builder
///
/// PDF araç bilgileri bölümü builder'ı.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../models/job_models.dart';
import '../pdf_styles.dart';
import 'pdf_helper_widgets.dart';

/// PDF vehicle info builder sınıfı
class PdfVehicleInfoBuilder {
  PdfVehicleInfoBuilder._();

  /// Vehicle info widget'ı oluşturur
  static pw.Widget build(JobOrder job, pw.Font regularFont, pw.Font boldFont) {
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
            'Araç Bilgileri',
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          PdfHelperWidgets.buildInfoItem(
            'Marka',
            job.vehicle.brand,
            regularFont,
            boldFont,
          ),
          pw.SizedBox(height: 4),
          PdfHelperWidgets.buildInfoItem(
            'Model',
            job.vehicle.model,
            regularFont,
            boldFont,
          ),
          pw.SizedBox(height: 4),
          PdfHelperWidgets.buildInfoItem(
            'Plaka',
            job.vehicle.plate,
            regularFont,
            boldFont,
          ),
        ],
      ),
    );
  }
}
