/// PDF Helper Widgets
///
/// PDF builder'lar için ortak yardımcı widget'lar.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../pdf_styles.dart';

/// PDF helper widget'ları
class PdfHelperWidgets {
  PdfHelperWidgets._();

  /// Info item widget'ı (label + value)
  static pw.Widget buildInfoItem(
    String label,
    String value,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            '$label:',
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 10,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  /// Stat item widget'ı (sayı + label)
  static pw.Widget buildStatItem(
    String label,
    int count,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          '$count',
          style: PdfStyles.textStyle(
            regularFont: regularFont,
            boldFont: boldFont,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: PdfStyles.textStyle(
            regularFont: regularFont,
            boldFont: boldFont,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

