import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart';
import '../../../../core/config/api_config.dart';
import '../../models/reception_models.dart';
import 'pdf_base_service.dart';
import 'pdf_report_metadata.dart';
import 'pdf_styles.dart';
import 'pdf_builders/pdf_header_builder.dart';
import 'pdf_builders/pdf_job_info_builder.dart';
import 'pdf_builders/pdf_vehicle_info_builder.dart';
import 'pdf_web_helper_stub.dart' if (dart.library.html) 'pdf_web_helper.dart';

/// Araç Kabul Rapor Servisi
///
/// Araç kabul aşamasında yapılan ekspertiz ve fotoğraf çekimlerini içeren PDF raporu oluşturur.
/// İş Emri PDF yapısıyla görsel olarak uyumludur.
class ReceptionReportService {
  ReceptionReportService._();

  static const int _photoLoadBatchSize = 4;
  static const Duration _photoReadTimeout = Duration(seconds: 6);
  static const Duration _photoProviderLoadTimeout = Duration(seconds: 35);
  static const Duration _pdfBuildTimeout = Duration(seconds: 20);
  static const Duration _layoutTimeout = Duration(seconds: 15);

  // Kabul raporundaki fotoğraf kartı ölçüleri.
  // Görsel boyutlarını değiştirmek için bu sabitleri güncellemek yeterlidir.
  static const double _photoCardWidth = 250;
  static const double _photoCardPadding = 6;
  static const double _photoPreviewHeight = 100;

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
    String? deliveredBy,
    String? receivedBy,
    String? defects,
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
        reportId: reportId.length >= 8
            ? reportId.substring(reportId.length - 8)
            : reportId,
        createdAt: DateTime.now(),
        statusLabel: '',
        statusColor: PdfColors.blue700,
        plate: plate,
        brand: brand,
        model: model,
      );

      final photoProviders = await _loadPhotoProviders(photos).timeout(
        _photoProviderLoadTimeout,
        onTimeout: () => List<pw.ImageProvider?>.filled(photos.length, null),
      );

      final pdf = pw.Document(theme: PdfBaseService.getTheme());
      final selectionCount = selections.values.fold<int>(
        0,
        (sum, value) => sum + (value as Iterable).length,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          footer: (context) => _buildSignatureFooter(
            deliveredBy: deliveredBy,
            receivedBy: receivedBy,
            regularFont: regularFont,
            boldFont: boldFont,
          ),
          build: (context) {
            return [
              PdfHeaderBuilder.build(
                metadata,
                regularFont,
                boldFont,
                logoImage,
              ),
              pw.SizedBox(height: 15),
              PdfInfoSectionBuilder.build(
                title: 'Kabul Bilgileri',
                data: {
                  'Rapor Tarihi': DateFormat(
                    'dd.MM.yyyy HH:mm',
                  ).format(DateTime.now()),
                  'Tespit Bölgesi': '${selections.length} parça',
                  'Toplam Tespit': '$selectionCount adet',
                  'Toplam Fotoğraf': '${photos.length} adet',
                },
                regularFont: regularFont,
                boldFont: boldFont,
              ),
              pw.SizedBox(height: 15),
              PdfVehicleInfoBuilder.build(
                plate: plate,
                brand: brand,
                model: model,
                regularFont: regularFont,
                boldFont: boldFont,
              ),
              if (selections.isNotEmpty) ...[
                pw.SizedBox(height: 15),
                _buildDamageSummarySection(selections, regularFont, boldFont),
              ],
              if (photos.isNotEmpty) ...[
                pw.SizedBox(height: 15),
                _buildPhotoSection(
                  photos,
                  photoProviders,
                  regularFont,
                  boldFont,
                ),
              ],
              if (generalNotes != null && generalNotes.trim().isNotEmpty) ...[
                pw.SizedBox(height: 15),
                _buildNotesSection(generalNotes, regularFont, boldFont),
              ],
              pw.SizedBox(height: 20),
              _buildFinalAcknowledgementSection(
                plate: plate,
                defects: defects,
                deliveredBy: deliveredBy,
                regularFont: regularFont,
                boldFont: boldFont,
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save().timeout(_pdfBuildTimeout);

      final filename = 'ekspertiz_${plate.replaceAll(' ', '_')}.pdf';

      // Öncelik: tüm platformlarda native print/layout akışını kullan.
      // Web'de popup blocker durumunda fallback olarak yeni sekmede aç.
      try {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: filename,
        ).timeout(_layoutTimeout);
      } on TimeoutException {
        if (kIsWeb) {
          openPdfInNewWindow(pdfBytes, filename);
        } else {
          await Printing.sharePdf(bytes: pdfBytes, filename: filename);
        }
      } catch (_) {
        if (kIsWeb) {
          openPdfInNewWindow(pdfBytes, filename);
        } else {
          await Printing.sharePdf(bytes: pdfBytes, filename: filename);
        }
      }
    } catch (e) {
      debugPrint('❌ Araç Kabul PDF hatası: $e');
      rethrow;
    }
  }

  static Future<Uint8List?> _loadPhotoBytes(ReceptionPhoto photo) async {
    final path = photo.displayPath.trim();
    if (path.isEmpty) return null;

    try {
      // Data URL (data:image/...) geçmiş kayıtlar için doğrudan çözümlenir.
      if (path.startsWith('data:image')) {
        final uri = Uri.tryParse(path);
        final bytes = uri?.data?.contentAsBytes();
        if (bytes != null && bytes.isNotEmpty) return Uint8List.fromList(bytes);
      }

      // Blob URL kalıcı değildir (oturum bağımlı), hızlıca geç.
      if (path.startsWith('blob:')) {
        return null;
      }

      // Uzak URL/relative upload path desteği.
      final remoteUrl = _resolveRemoteUrl(path);
      if (remoteUrl != null) {
        final response = await http
            .get(Uri.parse(remoteUrl))
            .timeout(_photoReadTimeout);
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      }

      final file = XFile(path);
      final bytes = await file.readAsBytes().timeout(_photoReadTimeout);
      if (bytes.isNotEmpty) return bytes;
    } catch (_) {
      // Sessizce devam et: sorunlu görselde placeholder gösterilecek.
    }

    return null;
  }

  static String? _resolveRemoteUrl(String rawPath) {
    final path = rawPath.trim();
    if (path.isEmpty) return null;

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    if (path.startsWith('data:') || path.startsWith('blob:')) {
      return null;
    }

    final apiBase = ApiConfig.baseUrl;
    final apiUri = Uri.parse(apiBase);
    final origin = '${apiUri.scheme}://${apiUri.authority}';

    final normalized = path.startsWith('/') ? path : '/$path';
    return '$origin$normalized';
  }

  static Future<List<pw.ImageProvider?>> _loadPhotoProviders(
    List<ReceptionPhoto> photos,
  ) async {
    final providers = List<pw.ImageProvider?>.filled(photos.length, null);
    final cache = <String, pw.ImageProvider?>{};

    for (var start = 0; start < photos.length; start += _photoLoadBatchSize) {
      final end = (start + _photoLoadBatchSize) > photos.length
          ? photos.length
          : (start + _photoLoadBatchSize);

      final batch = List.generate(end - start, (offset) async {
        final index = start + offset;
        final path = photos[index].displayPath;

        if (cache.containsKey(path)) {
          providers[index] = cache[path];
          return;
        }

        final bytes = await _loadPhotoBytes(photos[index]);
        final provider = bytes != null ? pw.MemoryImage(bytes) : null;
        cache[path] = provider;
        providers[index] = provider;
      });

      await Future.wait(batch);
    }

    return providers;
  }

  static pw.Widget _buildDamageSummarySection(
    VehiclePartSelections selections,
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
    List<pw.ImageProvider?> loadedPhotos,
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
                width: _photoCardWidth,
                padding: const pw.EdgeInsets.all(_photoCardPadding),
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
                      height: _photoPreviewHeight,
                      width: _photoCardWidth - (_photoCardPadding * 2),
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
      ),
    );
  }

  static pw.Widget _buildSignatureFooter({
    String? deliveredBy,
    String? receivedBy,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    final delivered = (deliveredBy ?? '').trim();
    final received = (receivedBy ?? '').trim();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: _buildFooterSignatureBlock(
              title: 'Teslim Eden',
              fullName: delivered,
              regularFont: regularFont,
              boldFont: boldFont,
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: _buildFooterSignatureBlock(
              title: 'Teslim Alan',
              fullName: received,
              regularFont: regularFont,
              boldFont: boldFont,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooterSignatureBlock({
    required String title,
    required String fullName,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: PdfStyles.textStyle(
            regularFont: regularFont,
            boldFont: boldFont,
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          fullName.isNotEmpty ? fullName : 'Ad Soyad: ____________________',
          style: PdfStyles.textStyle(
            regularFont: regularFont,
            boldFont: boldFont,
            fontSize: 8,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(height: 0.5, color: PdfColors.grey500),
        pw.SizedBox(height: 2),
        pw.Text(
          'İmza',
          style: PdfStyles.textStyle(
            regularFont: regularFont,
            boldFont: boldFont,
            fontSize: 7,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFinalAcknowledgementSection({
    required String plate,
    String? defects,
    String? deliveredBy,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    final defectText = (defects ?? '').trim();
    final name = (deliveredBy ?? '').trim();
    final signedBy = name.isNotEmpty
        ? name
        : '........................................';
    final defectsPart = defectText.isNotEmpty
        ? 'araçta belirtilen kusurlar/hasarlar ($defectText) ile birlikte'
        : 'araçta belirtilen kusurlar/hasarlar ile birlikte';

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
            'Son Onay',
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '$signedBy, $plate plakalı aracı $defectsPart teslim ettiğimi kabul ve beyan ederim.',
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 10,
            ),
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(height: 0.7, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Teslim Eden İmza / Ad Soyad',
                      style: PdfStyles.textStyle(
                        regularFont: regularFont,
                        boldFont: boldFont,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
