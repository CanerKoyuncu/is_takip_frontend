/// PDF Header Builder
///
/// PDF başlık bölümü builder'ı.

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../models/job_models.dart';
import '../pdf_styles.dart';

/// PDF header builder sınıfı
class PdfHeaderBuilder {
  PdfHeaderBuilder._();

  /// Header widget'ı oluşturur
  static pw.Widget build(
    JobOrder job,
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
                      'İŞ EMRİ RAPORU',
                      style: PdfStyles.textStyle(
                        regularFont: regularFont,
                        boldFont: boldFont,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'İş Emri No: ${job.id.length >= 8 ? job.id.substring(0, 8).toUpperCase() : job.id.toUpperCase()}',
                      style: PdfStyles.textStyle(
                        regularFont: regularFont,
                        boldFont: boldFont,
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Status badge
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: PdfStyles.getStatusColor(job.status),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                job.status.label,
                style: PdfStyles.textStyle(
                  regularFont: regularFont,
                  boldFont: boldFont,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        pw.Divider(height: 20),
      ],
    );
  }
}
