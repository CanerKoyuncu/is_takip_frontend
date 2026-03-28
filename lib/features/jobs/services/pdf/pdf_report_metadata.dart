import 'package:pdf/pdf.dart';

/// PDF Rapor Meta Verileri
/// 
/// Tüm raporlar için ortak kullanılan veri yapısı.
class PdfReportMetadata {
  final String title;
  final String reportId;
  final DateTime createdAt;
  final String? statusLabel;
  final PdfColor? statusColor;
  
  // Araç Bilgileri
  final String plate;
  final String brand;
  final String model;
  
  // Opsiyonel Genel Bilgiler
  final Map<String, String> additionalInfo;

  const PdfReportMetadata({
    required this.title,
    required this.reportId,
    required this.createdAt,
    this.statusLabel,
    this.statusColor,
    required this.plate,
    required this.brand,
    required this.model,
    this.additionalInfo = const {},
  });
}
