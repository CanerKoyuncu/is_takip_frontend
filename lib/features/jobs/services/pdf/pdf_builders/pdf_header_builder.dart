/// PDF Header Builder
///
/// PDF başlık bölümü builder'ı.

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../pdf_styles.dart';
import '../pdf_report_metadata.dart';

/// PDF header builder sınıfı
class PdfHeaderBuilder {
  PdfHeaderBuilder._();

  /// Header widget'ı oluşturur
  static pw.Widget build(
    PdfReportMetadata metadata,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.ImageProvider? logoImage,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo and title section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Logo
                if (logoImage != null) ...[
                  pw.Container(
                    width: 60,
                    height: 60,
                    constraints: const pw.BoxConstraints(
                      maxWidth: 60,
                      maxHeight: 60,
                    ),
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(width: 12),
                ] else ...[
                  // Debug: Show placeholder if logo not loaded
                  if (kDebugMode)
                    pw.Container(
                      width: 60,
                      height: 60,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.red),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'LOGO',
                          style: PdfStyles.textStyle(
                            regularFont: regularFont,
                            boldFont: boldFont,
                            fontSize: 8,
                            color: PdfColors.red,
                          ),
                        ),
                      ),
                    ),
                ],
                // Title
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      metadata.title,
                      style: PdfStyles.textStyle(
                        regularFont: regularFont,
                        boldFont: boldFont,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'No: ${metadata.reportId.toUpperCase()}',
                      style: PdfStyles.textStyle(
                        regularFont: regularFont,
                        boldFont: boldFont,
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Status badge (Optional)
            if (metadata.statusLabel != null)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: metadata.statusColor ?? PdfColors.grey600,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  metadata.statusLabel!,
                  style: PdfStyles.textStyle(
                    regularFont: regularFont,
                    boldFont: boldFont,
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        pw.Divider(height: 20, thickness: 0.5, color: PdfColors.grey400),
      ],
    );
  }
}
