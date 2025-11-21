/// PDF Footer Builder
///
/// PDF footer bölümü builder'ı.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../models/job_models.dart';
import 'pdf_helper_widgets.dart';

/// PDF footer builder sınıfı
class PdfFooterBuilder {
  PdfFooterBuilder._();

  /// Footer widget'ı oluşturur
  static pw.Widget build(
    JobOrder job,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    final pendingCount = job.tasks
        .where((t) => t.status == JobTaskStatus.pending)
        .length;
    final inProgressCount = job.tasks
        .where((t) => t.status == JobTaskStatus.inProgress)
        .length;
    final completedCount = job.tasks
        .where((t) => t.status == JobTaskStatus.completed)
        .length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          PdfHelperWidgets.buildStatItem(
            'Beklemede',
            pendingCount,
            regularFont,
            boldFont,
          ),
          PdfHelperWidgets.buildStatItem(
            'Devam Ediyor',
            inProgressCount,
            regularFont,
            boldFont,
          ),
          PdfHelperWidgets.buildStatItem(
            'Tamamlandı',
            completedCount,
            regularFont,
            boldFont,
          ),
        ],
      ),
    );
  }
}

