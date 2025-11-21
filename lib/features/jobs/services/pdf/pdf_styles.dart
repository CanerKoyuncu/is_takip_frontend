/// PDF Styles
///
/// PDF oluşturma için stil tanımları ve yardımcı fonksiyonlar.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/job_models.dart';

/// PDF stil yardımcı fonksiyonları
class PdfStyles {
  PdfStyles._();

  /// Türkçe karakter desteği ile TextStyle oluşturur
  ///
  /// Noto Sans font'unu kullanarak Türkçe karakterlerin doğru görüntülenmesini sağlar.
  static pw.TextStyle textStyle({
    required pw.Font regularFont,
    required pw.Font boldFont,
    double fontSize = 12,
    pw.FontWeight? fontWeight,
    PdfColor? color,
  }) {
    // Font kalınlığına göre font seç
    final font = fontWeight == pw.FontWeight.bold ? boldFont : regularFont;

    return pw.TextStyle(
      font: font,
      fontSize: fontSize,
      fontWeight: fontWeight ?? pw.FontWeight.normal,
      color: color ?? PdfColors.black,
    );
  }

  /// Job status rengini döndürür
  static PdfColor getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.hazirlik:
        return PdfColors.grey600;
      case JobStatus.kaporta:
        return PdfColors.orange600;
      case JobStatus.boya:
        return PdfColors.blue600;
      case JobStatus.tamamlandi:
        return PdfColors.green600;
    }
  }

  /// Task status rengini döndürür
  static PdfColor getTaskStatusColor(JobTaskStatus status) {
    switch (status) {
      case JobTaskStatus.pending:
        return PdfColors.grey600;
      case JobTaskStatus.inProgress:
        return PdfColors.blue600;
      case JobTaskStatus.paused:
        return PdfColors.orange600;
      case JobTaskStatus.completed:
        return PdfColors.green600;
    }
  }
}
