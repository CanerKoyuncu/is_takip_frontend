/// PDF Vehicle Info Builder
///
/// PDF araç bilgileri bölümü builder'ı.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../pdf_styles.dart';
import 'pdf_helper_widgets.dart';

/// PDF vehicle info builder sınıfı
class PdfVehicleInfoBuilder {
  PdfVehicleInfoBuilder._();

  /// Vehicle info widget'ı oluşturur
  static pw.Widget build({
    required String plate,
    required String brand,
    required String model,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
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
            'Araç Bilgileri',
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: PdfHelperWidgets.buildInfoItem(
                  'Plaka',
                  plate,
                  regularFont,
                  boldFont,
                ),
              ),
              pw.Expanded(
                child: PdfHelperWidgets.buildInfoItem(
                  'Marka/Model',
                  '$brand $model',
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
