import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart';
import '../models/reception_models.dart';
import 'pdf/pdf_styles.dart';
import 'pdf/pdf_base_service.dart';
import 'pdf/pdf_report_metadata.dart';
import 'pdf/pdf_builders/pdf_header_builder.dart';
import 'pdf/pdf_builders/pdf_job_info_builder.dart';
import 'pdf/pdf_builders/pdf_vehicle_info_builder.dart';
import 'pdf/pdf_builders/pdf_footer_builder.dart';

/// Araç Kabul Rapor Servisi
///
/// Araç kabul aşamasında yapılan ekspertiz ve fotoğraf çekimlerini içeren PDF raporu oluşturur.
/// İş Emri PDF yapısıyla görsel olarak uyumludur.
class ReceptionReportService {
  ReceptionReportService._();

  static Future<void> generateAndShowReport({
    required String plate,
    required String brand,
    required String model,
    required VehiclePartSelections selections,
    required List<ReceptionPhoto> photos,
    String? generalNotes,
  }) async {
    try {
      // 1. Kaynakları yükle
      await PdfBaseService.ensureFontsLoaded();
      await PdfBaseService.ensureLogoLoaded();

      final regularFont = PdfBaseService.regularFont;
      final boldFont = PdfBaseService.boldFont;
      final logoImage = PdfBaseService.logoImage;

      // 2. PDF Dokümanı oluştur
      final pdf = pw.Document(theme: PdfBaseService.getTheme());

      // 3. Meta verileri hazırla
      final metadata = PdfReportMetadata(
        title: 'ARAÇ KABUL VE EKSPERTİZ RAPORU',
        reportId:
            'KABUL-${DateFormat('yyyyMMdd').format(DateTime.now())}-${plate.replaceAll(' ', '')}',
        createdAt: DateTime.now(),
        statusLabel: 'YENİ KABUL',
        statusColor: PdfColors.blue600,
        plate: plate,
        brand: brand,
        model: model,
      );

      // 4. Fotoğrafları yükle (1:1 eşleşme için null ekleyerek)
      final List<pw.ImageProvider?> loadedPhotos = [];
      debugPrint(
        '📸 Araç Kabul fotoğrafları yükleniyor (${photos.length} adet)...',
      );

      for (int i = 0; i < photos.length; i++) {
        final photo = photos[i];
        final bytes = await _loadPhotoBytes(photo);
        if (bytes != null) {
          loadedPhotos.add(pw.MemoryImage(bytes));
          debugPrint('✓ Fotoğraf $i yüklendi: ${photo.displayPath}');
        } else {
          loadedPhotos.add(null);
          debugPrint('⚠ Fotoğraf $i yüklenemedi: ${photo.displayPath}');
        }
      }

      // 5. PDF Sayfası oluştur
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Başlık (Logo ve Başlık)
              PdfHeaderBuilder.build(
                metadata,
                regularFont,
                boldFont,
                logoImage,
              ),
              pw.SizedBox(height: 15),

              // Kabul Bilgileri
              PdfInfoSectionBuilder.build(
                title: 'Kabul Bilgileri',
                data: {
                  'Kabul Tarihi': DateFormat(
                    'dd.MM.yyyy HH:mm',
                  ).format(DateTime.now()),
                  'Tespit Sayısı': '${selections.length} bölge',
                  'Fotoğraf Sayısı': '${photos.length} adet',
                },
                regularFont: regularFont,
                boldFont: boldFont,
              ),
              pw.SizedBox(height: 15),

              // Araç Bilgileri
              PdfVehicleInfoBuilder.build(
                plate: plate,
                brand: brand,
                model: model,
                regularFont: regularFont,
                boldFont: boldFont,
              ),
              pw.SizedBox(height: 15),

              // Hasar Özeti
              if (selections.isNotEmpty) ...[
                _buildDamageSummarySection(selections, regularFont, boldFont),
                pw.SizedBox(height: 15),
              ],

              // Genel Notlar
              if (generalNotes != null && generalNotes.isNotEmpty) ...[
                _buildNotesSection(generalNotes, regularFont, boldFont),
                pw.SizedBox(height: 15),
              ],

              // Fotoğraflı Tespitler
              if (photos.isNotEmpty) ...[
                _buildPhotoSection(photos, loadedPhotos, regularFont, boldFont),
                pw.SizedBox(height: 15),
              ],

              // Alt Bilgi
              PdfFooterBuilder.build(
                stats: {
                  'İşaretli Bölge': selections.length,
                  'Fotoğraflar': photos.length,
                },
                regularFont: regularFont,
                boldFont: boldFont,
              ),
            ];
          },
        ),
      );

      // 6. PDF'i göster/paylaş
      final filename = 'ekspertiz_${plate.replaceAll(' ', '_')}.pdf';
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: filename,
      );
    } catch (e) {
      debugPrint('❌ Araç Kabul PDF hatası: $e');
    }
  }

  /// Fotoğraf verisini yükler
  static Future<Uint8List?> _loadPhotoBytes(ReceptionPhoto photo) async {
    try {
      if (kIsWeb) {
        // Web'de genellikle blob URL veya base64 kullanılır
        return null;
      } else {
        // file:// protokolünü temizle
        String path = photo.displayPath;
        if (path.startsWith('file://')) {
          path = Uri.parse(path).toFilePath();
        }

        final file = File(path);
        if (await file.exists()) {
          return await file.readAsBytes();
        } else {
          debugPrint('⚠ Dosya bulunamadı: $path');
        }
      }
    } catch (e) {
      debugPrint('Fotoğraf yükleme hatası (${photo.displayPath}): $e');
    }
    return null;
  }

  /// Hasar Özeti Bölümü
  static pw.Widget _buildDamageSummarySection(
    VehiclePartSelections selections,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Hasar Haritası Tespiti',
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 12,
            runSpacing: 6,
            children: selections.entries.map((entry) {
              return pw.Container(
                width: 240,
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 4, right: 6),
                      width: 4,
                      height: 4,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue700,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            pw.TextSpan(
                              text: '${entry.key}: ',
                              style: PdfStyles.textStyle(
                                regularFont: regularFont,
                                boldFont: boldFont,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(
                              text: entry.value.join(', '),
                              style: PdfStyles.textStyle(
                                regularFont: regularFont,
                                boldFont: boldFont,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Notlar Bölümü
  static pw.Widget _buildNotesSection(
    String notes,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
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
            'Genel Notlar',
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            notes,
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Fotoğraf Bölümü
  static pw.Widget _buildPhotoSection(
    List<ReceptionPhoto> photoMetadata,
    List<pw.ImageProvider?> loadedPhotos, // Nullable yapıldı
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Fotoğraflı Tespitler',
          style: PdfStyles.textStyle(
            regularFont: regularFont,
            boldFont: boldFont,
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(photoMetadata.length, (index) {
            final photo = photoMetadata[index];
            final image = index < loadedPhotos.length
                ? loadedPhotos[index]
                : null;

            return pw.Container(
              width: 165,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    photo.partName ?? 'Genel Görünüm',
                    style: PdfStyles.textStyle(
                      regularFont: regularFont,
                      boldFont: boldFont,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                  if (photo.damageTypes.isNotEmpty)
                    pw.Text(
                      photo.damageTypes.join(', '),
                      style: PdfStyles.textStyle(
                        regularFont: regularFont,
                        boldFont: boldFont,
                        fontSize: 8,
                        color: PdfColors.blue700,
                      ),
                      maxLines: 1,
                    ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    height: 100,
                    width: 153,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: image != null
                        ? pw.Image(image, fit: pw.BoxFit.cover)
                        : pw.Center(
                            child: pw.Text(
                              'Fotoğraf Yok',
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.grey500,
                              ),
                            ),
                          ),
                  ),
                  if (photo.note != null && photo.note!.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      photo.note!,
                      style: PdfStyles.textStyle(
                        regularFont: regularFont,
                        boldFont: boldFont,
                        fontSize: 7,
                        color: PdfColors.grey700,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
