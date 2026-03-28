import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart';
import '../models/reception_models.dart';
import 'pdf/pdf_base_service.dart';
import 'pdf/pdf_report_metadata.dart';
import 'pdf/pdf_styles.dart';
import 'pdf/pdf_builders/pdf_header_builder.dart';
import 'pdf/pdf_builders/pdf_job_info_builder.dart';
import 'pdf/pdf_builders/pdf_vehicle_info_builder.dart';
import 'pdf_web_helper_stub.dart' if (dart.library.html) 'pdf_web_helper.dart';

/// Araç Kabul Rapor Servisi
///
/// Araç kabul aşamasında yapılan ekspertiz ve fotoğraf çekimlerini içeren PDF raporu oluşturur.
/// İş Emri PDF yapısıyla görsel olarak uyumludur.
class ReceptionReportService {
  ReceptionReportService._();

  static const Map<String, String> _labelToAction = {
    'vuruk': 'tespit:vuruk',
    'göçük': 'tespit:gocuk',
    'gocuk': 'tespit:gocuk',
    'çizik': 'tespit:cizik',
    'cizik': 'tespit:cizik',
    'sürtme': 'tespit:surtuk',
    'sürtük': 'tespit:surtuk',
    'surtme': 'tespit:surtuk',
    'surtuk': 'tespit:surtuk',
    'leke': 'tespit:leke',
    'kırık': 'tespit:kirik',
    'kirik': 'tespit:kirik',
  };

  static String _normalizeActionOrLabel(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;

    if (value.contains(':')) return canonicalDamageActionKey(value);

    final mapped = _labelToAction[value.toLowerCase()];
    if (mapped != null) return canonicalDamageActionKey(mapped);

    return value;
  }

  static String _damageLabel(String raw) {
    final normalized = _normalizeActionOrLabel(raw);
    if (normalized.contains(':')) return damageActionLabel(normalized);
    return normalized;
  }

  static String _formatFallbackId(String rawId) {
    final clean = rawId.trim();
    if (clean.isEmpty) return 'Genel';
    return clean
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }

  static String _displayPartName({String? partName, String? partId}) {
    final id = (partId ?? '').trim();
    if (id.isNotEmpty) {
      final byId = VehiclePartsRegistry.byId(id);
      if (byId != null) return byId.name;
    }

    final name = (partName ?? '').trim();
    if (name.isNotEmpty) {
      final byName = VehiclePartsRegistry.byId(name);
      if (byName != null) return byName.name;

      final looksTechnical =
          name.contains('-') || name.contains('_') || name.startsWith('path');
      if (!looksTechnical) return name;
      return _formatFallbackId(name);
    }

    if (id.isNotEmpty) return _formatFallbackId(id);
    return 'Genel';
  }

  static Future<void> generateAndShowReport({
    required String plate,
    required String brand,
    required String model,
    required VehiclePartSelections selections,
    required List<ReceptionPhoto> photos,
    String? generalNotes,
  }) async {
    try {
      await PdfBaseService.ensureFontsLoaded();
      await PdfBaseService.ensureLogoLoaded();

      final regularFont = PdfBaseService.regularFont;
      final boldFont = PdfBaseService.boldFont;
      final logoImage = PdfBaseService.logoImage;

      final reportId = DateTime.now().millisecondsSinceEpoch.toString();
      final metadata = PdfReportMetadata(
        title: 'ARAÇ KABUL RAPORU',
        reportId: reportId.length >= 8 ? reportId.substring(reportId.length - 8) : reportId,
        createdAt: DateTime.now(),
        statusLabel: 'KABUL',
        statusColor: PdfColors.blue700,
        plate: plate,
        brand: brand,
        model: model,
      );

      final loadedPhotos = await Future.wait(
        photos.map(_loadPhotoBytes),
      );
      final photoProviders = loadedPhotos
          .whereType<Uint8List>()
          .map((bytes) => pw.MemoryImage(bytes))
          .toList();

      final pdf = pw.Document(theme: PdfBaseService.getTheme());
      final selectionCount = selections.values.fold<int>(
        0,
        (sum, value) => sum + (value as Iterable).length,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return [
              PdfHeaderBuilder.build(metadata, regularFont, boldFont, logoImage),
              pw.SizedBox(height: 20),
              PdfInfoSectionBuilder.build(
                title: 'Kabul Bilgileri',
                data: {
                  'Rapor Tarihi': DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
                  'Tespit Bölgesi': '${selections.length} parça',
                  'Toplam Tespit': '$selectionCount adet',
                  'Toplam Fotoğraf': '${photos.length} adet',
                },
                regularFont: regularFont,
                boldFont: boldFont,
              ),
              pw.SizedBox(height: 20),
              PdfVehicleInfoBuilder.build(
                plate: plate,
                brand: brand,
                model: model,
                regularFont: regularFont,
                boldFont: boldFont,
              ),
              if (selections.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildDamageSummarySection(selections, regularFont, boldFont),
              ],
              if (photos.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildPhotoSection(photos, photoProviders, regularFont, boldFont),
              ],
              if (generalNotes != null && generalNotes.trim().isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildNotesSection(generalNotes, regularFont, boldFont),
              ],
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();

      final filename = 'ekspertiz_${plate.replaceAll(' ', '_')}.pdf';

      // Öncelik: tüm platformlarda native print/layout akışını kullan.
      // Web'de popup blocker durumunda fallback olarak yeni sekmede aç.
      try {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: filename,
        );
      } catch (_) {
        if (kIsWeb) {
          openPdfInNewWindow(pdfBytes, filename);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('❌ Araç Kabul PDF hatası: $e');
      rethrow;
    }
  }

  static Future<Uint8List?> _loadPhotoBytes(ReceptionPhoto photo) async {
    try {
      final file = XFile(photo.displayPath);
      final bytes = await file.readAsBytes();
      if (bytes.isNotEmpty) return bytes;
    } catch (e) {
      debugPrint('⚠ XFile ile fotoğraf okunamadı (${photo.displayPath}): $e');
    }

    return null;
  }

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
            'Hasar Özeti',
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
              final damageLabels = (entry.value as Iterable)
                  .map((item) => _damageLabel(item.toString().split('.').last))
                  .toList()
                  .join(', ');
              final displayPartName = _displayPartName(partId: entry.key);

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
                              text: '$displayPartName: ',
                              style: PdfStyles.textStyle(
                                regularFont: regularFont,
                                boldFont: boldFont,
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.TextSpan(
                              text: damageLabels,
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

  static pw.Widget _buildPhotoSection(
    List<ReceptionPhoto> photoMetadata,
    List<pw.ImageProvider> loadedPhotos,
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
            final image = index < loadedPhotos.length ? loadedPhotos[index] : null;

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
                    _displayPartName(
                      partName: photo.partName,
                      partId: photo.partId,
                    ),
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
                      photo.damageTypes.map(_damageLabel).join(', '),
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
                              'Fotoğraf Yüklenemedi',
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
