/// PDF Tasks Builder
///
/// PDF görevler bölümü builder'ı.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../models/job_models.dart';
import '../../../models/vehicle_area.dart';
import '../pdf_styles.dart';

/// PDF tasks builder sınıfı
class PdfTasksBuilder {
  PdfTasksBuilder._();

  /// Tasks section widget'ı oluşturur
  static pw.Widget build(
    JobOrder job,
    pw.Font regularFont,
    pw.Font boldFont,
    Map<String, List<pw.ImageProvider>> taskPhotos,
    Map<String, List<TaskPhoto>> taskPhotoMetadata,
  ) {
    if (job.tasks.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'Bu iş emrinde görev bulunmuyor.',
          style: PdfStyles.textStyle(
            regularFont: regularFont,
            boldFont: boldFont,
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
      );
    }

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
            'Görevler (${job.tasks.length})',
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          // Show each task with its photos
          ...job.tasks.map((task) {
            final hasPhotos =
                taskPhotos.containsKey(task.id) &&
                taskPhotos[task.id]!.isNotEmpty;
            final photos = hasPhotos
                ? taskPhotos[task.id]!
                : <pw.ImageProvider>[];
            final photoMetadata =
                hasPhotos && taskPhotoMetadata.containsKey(task.id)
                ? taskPhotoMetadata[task.id]!
                : <TaskPhoto>[];

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Task info row
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Task details
                      pw.Expanded(
                        flex: 3,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              task.area.label,
                              style: PdfStyles.textStyle(
                                regularFont: regularFont,
                                boldFont: boldFont,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              task.operationType.label,
                              style: PdfStyles.textStyle(
                                regularFont: regularFont,
                                boldFont: boldFont,
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfStyles.getTaskStatusColor(task.status),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          task.status.label,
                          style: PdfStyles.textStyle(
                            regularFont: regularFont,
                            boldFont: boldFont,
                            fontSize: 9,
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Task note if exists
                  if (task.note != null && task.note!.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        task.note!,
                        style: PdfStyles.textStyle(
                          regularFont: regularFont,
                          boldFont: boldFont,
                          fontSize: 9,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ),
                  ],
                  // Photos if available
                  if (hasPhotos) ...[
                    pw.SizedBox(height: 10),
                    pw.Divider(),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Fotoğraflar (${photos.length})',
                      style: PdfStyles.textStyle(
                        regularFont: regularFont,
                        boldFont: boldFont,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: photos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final photo = entry.value;
                        final metadata = index < photoMetadata.length
                            ? photoMetadata[index]
                            : null;

                        // Get photo type label
                        String photoTypeLabel = 'Fotoğraf';
                        if (metadata != null) {
                          switch (metadata.type) {
                            case TaskPhotoType.damage:
                              photoTypeLabel = 'Hasar Fotoğrafı';
                              break;
                            case TaskPhotoType.completion:
                              photoTypeLabel =
                                  'Tamamlanmış Haline Ait Fotoğraf';
                              break;
                            case TaskPhotoType.onRepair:
                              photoTypeLabel = 'Onarım Anında Fotoğraf';
                              break;
                            case TaskPhotoType.onPaint:
                              photoTypeLabel = 'Boya Fotoğrafı';
                              break;
                            case TaskPhotoType.onClean:
                              photoTypeLabel = 'Temizleme Fotoğrafı';
                              break;
                          }
                        }

                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Container(
                              width: 120,
                              height: 120,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                  color: PdfColors.grey400,
                                  width: 1,
                                ),
                                borderRadius: pw.BorderRadius.circular(4),
                                boxShadow: [
                                  pw.BoxShadow(
                                    color: PdfColors.grey300,
                                    blurRadius: 2,
                                    offset: const PdfPoint(1, 1),
                                  ),
                                ],
                              ),
                              child: pw.ClipRRect(
                                child: pw.Image(photo, fit: pw.BoxFit.cover),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey100,
                                borderRadius: pw.BorderRadius.circular(3),
                                border: pw.Border.all(
                                  color: PdfColors.grey300,
                                  width: 0.5,
                                ),
                              ),
                              child: pw.Text(
                                photoTypeLabel,
                                style: PdfStyles.textStyle(
                                  regularFont: regularFont,
                                  boldFont: boldFont,
                                  fontSize: 8,
                                  color: PdfColors.grey800,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
