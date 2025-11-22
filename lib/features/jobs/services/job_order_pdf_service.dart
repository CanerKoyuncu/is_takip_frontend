/// İş Emri PDF Servisi
///
/// Bu sınıf, iş emirleri için PDF raporları oluşturur.
/// Frontend'de PDF oluşturma işlemini yönetir.
///
/// Özellikler:
/// - İş emri bilgilerini PDF formatına dönüştürme
/// - Hasar haritası görseli ekleme
/// - Fotoğrafları PDF'e ekleme
/// - Türkçe karakter desteği (Noto Sans font)
/// - Logo ekleme
/// - Web ve mobil platform desteği
///
/// Not: Backend'den PDF almak için JobsApiService.getJobPdf() kullanılabilir.
/// Bu servis frontend'de PDF oluşturur.

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// Web desteği - conditional import
// Web'de pdf_web_helper.dart, diğer platformlarda pdf_web_helper_stub.dart kullanılır
import 'pdf_web_helper_stub.dart' if (dart.library.html) 'pdf_web_helper.dart';

import 'package:flutter/material.dart';

import '../models/job_models.dart';
import '../models/vehicle_area.dart';
import '../utils/vehicle_part_mapper.dart';
import '../utils/svg_vehicle_part_loader.dart';
import '../utils/damage_map_image_generator.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/api_service_factory.dart';
import '../services/photo_service.dart';
import 'jobs_api_service.dart';
import 'pdf/pdf_styles.dart';
import 'pdf/pdf_builders/pdf_header_builder.dart';
import 'pdf/pdf_builders/pdf_job_info_builder.dart';
import 'pdf/pdf_builders/pdf_vehicle_info_builder.dart';
import 'pdf/pdf_builders/pdf_tasks_builder.dart';
import 'pdf/pdf_builders/pdf_notes_builder.dart';
import 'pdf/pdf_builders/pdf_footer_builder.dart';

/// İş emri PDF servis sınıfı
///
/// Singleton pattern kullanır - tek bir instance oluşturulur.
/// PDF oluşturma işlemlerini yönetir.
class JobOrderPdfService {
  // Private constructor - singleton pattern
  JobOrderPdfService._();
  // Singleton instance
  static final JobOrderPdfService instance = JobOrderPdfService._();

  // Logo image provider - PDF'e eklenecek logo
  pw.ImageProvider? _logoImage;
  final ApiService _apiService = ApiServiceFactory.getApiService();

  /// Logo görselini assets'den yükler (private metod)
  ///
  /// Logo'yu assets klasöründen yüklemeye çalışır.
  /// Web platformunda assets başarısız olursa HTTP üzerinden yüklemeyi dener.
  ///
  /// Yükleme Sırası:
  /// 1. assets/logo.png
  /// 2. assets/images/logo.png
  /// 3. Web'de: HTTP üzerinden /assets/logo.png
  Future<void> _loadLogo() async {
    // Zaten yüklenmişse tekrar yükleme
    if (_logoImage != null) return;

    try {
      // Assets'den logo yüklemeyi dene (birden fazla olası yol)
      final possiblePaths = ['assets/logo.png', 'assets/images/logo.png'];

      for (final path in possiblePaths) {
        try {
          final logoData = await rootBundle.load(path);
          final logoBytes = logoData.buffer.asUint8List();

          // Logo bytes'larının geçerli olduğunu doğrula
          if (logoBytes.isEmpty) {
            debugPrint('Logo dosyası boş: $path');
            continue; // Sonraki yolu dene
          }

          _logoImage = pw.MemoryImage(logoBytes);
          debugPrint(
            '✓ Logo başarıyla yüklendi: $path (${logoBytes.length} bytes)',
          );
          return; // Başarılı, çık
        } catch (e) {
          debugPrint('Logo yükleme denemesi başarısız ($path): $e');
          // Sonraki yolu dene
          continue;
        }
      }

      // Web platformunda, assets başarısız olursa HTTP üzerinden yükle
      if (kIsWeb) {
        try {
          // Web sunucusundan yüklemeyi dene
          final baseUrl = Uri.base.origin;
          final logoUrl = '$baseUrl/assets/logo.png';
          debugPrint(
            'Web: Logo HTTP üzerinden yüklenmeye çalışılıyor: $logoUrl',
          );

          final response = await http
              .get(Uri.parse(logoUrl))
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            _logoImage = pw.MemoryImage(response.bodyBytes);
            debugPrint(
              '✓ Logo HTTP üzerinden yüklendi (${response.bodyBytes.length} bytes)',
            );
            return;
          }
        } catch (e) {
          debugPrint('Logo HTTP yükleme hatası: $e');
        }
      }

      debugPrint(
        '✗ Logo dosyası bulunamadı (denenen yollar: ${possiblePaths.join(", ")})',
      );
    } catch (e) {
      debugPrint('✗ Logo yükleme hatası: $e');
    }
  }

  /// Türkçe karakter desteği ile TextStyle oluşturur (private metod)
  ///
  /// Noto Sans font'unu kullanarak Türkçe karakterlerin doğru görüntülenmesini sağlar.
  /// Font'lar açıkça belirtilir (örnekteki gibi) kullanıldıklarından emin olmak için.
  ///
  /// Parametreler:
  /// - regularFont: Normal font (Noto Sans)
  /// - boldFont: Kalın font (Noto Sans)
  /// - fontSize: Font boyutu (varsayılan: 12)
  /// - fontWeight: Font kalınlığı (varsayılan: normal)
  /// - color: Metin rengi (varsayılan: siyah)
  ///
  /// Döner: pw.TextStyle - PDF text style

  /// TaskPhoto objesini kullanarak API'den fotoğraf yükler (private metod)
  ///
  /// Fotoğrafı backend API'den yükler ve PDF için ImageProvider döndürür.
  /// API key ile kimlik doğrulama yapılır.
  ///
  /// Parametreler:
  /// - photo: TaskPhoto objesi
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - thumbnail: Thumbnail mi yoksa tam boyut mu (varsayılan: true - PDF için küçük boyut)
  ///
  /// Döner: pw.ImageProvider? - Yüklenen fotoğraf veya null (hata durumunda)
  Future<pw.ImageProvider?> _loadPhotoFromApi(
    TaskPhoto photo,
    String jobId,
    String taskId, {
    bool thumbnail = true,
  }) async {
    try {
      // PhotoService kullanarak fotoğraf URL'ini al
      final photoUrl = PhotoService.getPhotoUrlFromConfig(
        photo,
        jobId: jobId,
        taskId: taskId,
        thumbnail: thumbnail,
      );

      if (photoUrl == null) {
        debugPrint('⚠️ Fotoğraf URL\'si oluşturulamadı: photoId=${photo.id}');
        return null;
      }

      debugPrint('📷 Fotoğraf yükleniyor: $photoUrl');

      final response = await _apiService.getBytes(
        photoUrl,
        options: Options(
          headers: {'Accept': 'image/*'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint(
          '✓ Fotoğraf başarıyla yüklendi (${response.data!.length} bytes)',
        );
        return pw.MemoryImage(response.data!);
      } else {
        debugPrint(
          '✗ Fotoğraf yükleme başarısız: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('✗ Fotoğraf yükleme hatası: $e');
    }
    return null;
  }

  /// İş emri için PDF belgesi oluşturur
  ///
  /// İş emri bilgilerini, hasar haritasını, fotoğrafları ve notları içeren
  /// kapsamlı bir PDF raporu oluşturur.
  ///
  /// İşlem Adımları:
  /// 1. Font'ları yükler (Türkçe karakter desteği için)
  /// 2. Logo'yu yükler
  /// 3. Fotoğrafları API'den yükler
  /// 4. Hasar haritası görselini oluşturur (veya önceden oluşturulmuş görseli kullanır)
  /// 5. PDF sayfalarını oluşturur
  ///
  /// Parametreler:
  /// - job: İş emri objesi
  /// - damageMapImageBytes: Önceden oluşturulmuş hasar haritası görseli (opsiyonel)
  ///
  /// Döner: Uint8List - PDF dosyası bytes
  ///
  /// Not: Font'lar bu metod içinde doğrudan yüklenir (örnekteki gibi)
  /// Türkçe karakterlerin doğru çalışması için.
  Future<Uint8List> generatePdf(
    JobOrder job, {
    Uint8List? damageMapImageBytes,
  }) async {
    try {
      // Load fonts directly here (like in the example)
      // This ensures fonts are loaded fresh for each PDF generation
      pw.Font? regularFont;
      pw.Font? boldFont;

      debugPrint('Fontlar yükleniyor...');

      // Helper function to validate TTF font
      bool _isValidTtfFont(ByteData data) {
        if (data.lengthInBytes < 4) return false;
        // TTF files start with specific magic numbers
        // 0x00010000 (TrueType) or 'OTTO' (OpenType with CFF)
        final bytes = data.buffer.asUint8List(0, 4);
        final magic =
            (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
        return magic == 0x00010000 ||
            (bytes[0] == 0x4F &&
                bytes[1] == 0x54 &&
                bytes[2] == 0x54 &&
                bytes[3] == 0x4F);
      }

      // Try to load from assets - only single NotoSans.ttf file
      try {
        final fontData = await rootBundle.load('assets/fonts/NotoSans.ttf');

        // Validate that it's a real TTF file
        if (!_isValidTtfFont(fontData)) {
          throw Exception(
            'NotoSans.ttf geçerli bir TTF dosyası değil. '
            'Lütfen assets/fonts/ klasöründeki dosyayı silip, '
            'https://fonts.google.com/noto/specimen/Noto+Sans adresinden '
            'geçerli TTF dosyasını indirin.',
          );
        }

        // Use the same font file for both regular and bold
        regularFont = pw.Font.ttf(fontData);
        boldFont = pw.Font.ttf(fontData);
        debugPrint(
          '✓ NotoSans.ttf yüklendi, hem Regular hem Bold olarak kullanılacak',
        );
      } catch (e) {
        debugPrint('Asset\'lerden font yükleme hatası: $e');

        // On web, try loading from the web server - only single NotoSans.ttf file
        if (kIsWeb) {
          try {
            final baseUrl = Uri.base.origin;
            debugPrint(
              'Web: NotoSans.ttf dosyasını sunucudan yüklemeye çalışılıyor...',
            );

            final response = await http
                .get(Uri.parse('$baseUrl/assets/fonts/NotoSans.ttf'))
                .timeout(const Duration(seconds: 10));

            if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
              final fontData = response.bodyBytes.buffer.asByteData();

              // Validate that it's a real TTF file (not HTML)
              if (!_isValidTtfFont(fontData)) {
                debugPrint(
                  '✗ Sunucudan yüklenen dosya geçerli bir TTF değil (HTML olabilir)',
                );
              } else {
                // Use the same font file for both regular and bold
                regularFont = pw.Font.ttf(fontData);
                boldFont = pw.Font.ttf(fontData);
                debugPrint(
                  '✓ NotoSans.ttf sunucudan yüklendi, hem Regular hem Bold olarak kullanılacak',
                );
              }
            }
          } catch (eWeb) {
            debugPrint('Web sunucudan font yükleme hatası: $eWeb');
          }
        }

        // Note: CDN fallback removed because:
        // 1. Most CDNs serve WOFF2 files which don't work with PDF library
        // 2. TTF files need to be manually downloaded from Google Fonts
        // Users should download fonts from https://fonts.google.com/noto/specimen/Noto+Sans
      }

      // CRITICAL: Fonts must be loaded for Turkish characters
      if (regularFont == null || boldFont == null) {
        throw Exception(
          'Fontlar yüklenemedi! Regular: ${regularFont != null}, Bold: ${boldFont != null}\n'
          'ÇÖZÜM: Lütfen assets/fonts/ klasörüne NotoSans.ttf dosyasını ekleyin:\n'
          '1. https://fonts.google.com/noto/specimen/Noto+Sans adresine gidin\n'
          '2. "Download family" butonuna tıklayın\n'
          '3. İndirilen ZIP dosyasını açın\n'
          '4. NotoSans.ttf dosyasını assets/fonts/ klasörüne kopyalayın\n'
          '5. flutter pub get ve flutter clean çalıştırın',
        );
      }

      debugPrint('✓ Fontlar başarıyla yüklendi, PDF oluşturuluyor...');

      // Load logo (non-blocking, logo is optional)
      await _loadLogo();

      if (_logoImage == null) {
        debugPrint('⚠ UYARI: Logo yüklenemedi, PDF logo olmadan oluşturulacak');
      } else {
        debugPrint('✓ Logo yüklendi, PDF\'e eklenecek');
      }

      // Create PDF document with theme (font support)
      // Use ThemeData.withFont to set default fonts for the entire document
      // This ensures Turkish characters are properly displayed
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          italic: regularFont,
          boldItalic: boldFont,
        ),
      );

      // Load photos for all tasks before building PDF
      debugPrint('📸 Görev fotoğrafları yükleniyor...');
      final Map<String, List<pw.ImageProvider>> taskPhotos = {};
      final Map<String, List<TaskPhoto>> taskPhotoMetadata = {};
      int totalPhotos = 0;
      int loadedPhotos = 0;

      for (final task in job.tasks) {
        if (task.photos.isNotEmpty) {
          debugPrint(
            '📋 Görev ${task.id} (${task.area.label}): ${task.photos.length} fotoğraf var',
          );
          totalPhotos += task.photos.length;
          final photos = <pw.ImageProvider>[];
          final photoMetadata = <TaskPhoto>[];
          for (final photo in task.photos) {
            // Use API to load photo with authentication
            final imageProvider = await _loadPhotoFromApi(
              photo,
              job.id,
              task.id,
              thumbnail: true, // Use thumbnail for PDF to reduce size
            );
            if (imageProvider != null) {
              photos.add(imageProvider);
              photoMetadata.add(photo);
              loadedPhotos++;
            }
          }
          if (photos.isNotEmpty) {
            taskPhotos[task.id] = photos;
            taskPhotoMetadata[task.id] = photoMetadata;
            debugPrint(
              '✓ Görev ${task.id}: ${photos.length}/${task.photos.length} fotoğraf yüklendi',
            );
          } else {
            debugPrint('✗ Görev ${task.id}: Hiç fotoğraf yüklenemedi');
          }
        }
      }

      debugPrint(
        '📊 Toplam: $loadedPhotos/$totalPhotos fotoğraf başarıyla yüklendi',
      );
      debugPrint('📊 ${taskPhotos.length} görevde fotoğraf var');

      // Load vehicle parts and selections for damage map
      debugPrint('🗺️ Hasar haritası verileri yükleniyor...');
      List<VehiclePart>? vehicleParts;
      Map<String, List<String>>? damageSelections;
      pw.ImageProvider? damageMapImage;

      try {
        vehicleParts = await SvgVehiclePartLoader.instance.load();
        damageSelections = VehiclePartMapper.tasksToSelections(job.tasks);
        debugPrint('✓ Hasar haritası verileri yüklendi');

        // Use pre-generated damage map image if provided
        if (damageMapImageBytes != null) {
          damageMapImage = pw.MemoryImage(damageMapImageBytes);
          debugPrint(
            '✓ Hasar haritası görüntüsü kullanılıyor (${damageMapImageBytes.length} bytes)',
          );
        } else {
          debugPrint(
            '⚠ Hasar haritası görüntüsü sağlanmadı, liste gösterilecek',
          );
        }
      } catch (e) {
        debugPrint('⚠ Hasar haritası verileri yüklenemedi: $e');
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            try {
              // Fonts are guaranteed to be non-null at this point (checked above)
              final rf = regularFont!;
              final bf = boldFont!;

              return [
                PdfHeaderBuilder.build(job, rf, bf, _logoImage),
                pw.SizedBox(height: 20),
                PdfJobInfoBuilder.build(job, rf, bf),
                pw.SizedBox(height: 20),
                PdfVehicleInfoBuilder.build(job, rf, bf),
                pw.SizedBox(height: 20),
                pw.SizedBox(height: 20),
                _buildDamageMapSection(
                  job,
                  rf,
                  bf,
                  vehicleParts,
                  damageSelections,
                  damageMapImage,
                ),
                pw.SizedBox(height: 20),
                _buildColorLegend(rf, bf),
                pw.SizedBox(height: 20),
                PdfTasksBuilder.build(
                  job,
                  rf,
                  bf,
                  taskPhotos,
                  taskPhotoMetadata,
                ),
                if (job.generalNotes != null &&
                    job.generalNotes!.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  PdfNotesBuilder.build(job, rf, bf),
                ],
                pw.SizedBox(height: 20),
                PdfFooterBuilder.build(job, rf, bf),
              ];
            } catch (e) {
              return [
                pw.Text(
                  'PDF oluşturulurken hata oluştu: $e',
                  style: pw.TextStyle(
                    font: regularFont ?? pw.Font.courier(),
                    color: PdfColors.red,
                  ),
                ),
              ];
            }
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      throw Exception('PDF oluşturma hatası: $e');
    }
  }

  /// Generates PDF locally and opens it for preview/sharing
  /// Uses frontend PDF generation with damage map image
  Future<void> previewAndShare(
    JobOrder job, {
    BuildContext? context,
    JobsApiService? jobsApiService,
  }) async {
    try {
      debugPrint('📄 PDF oluşturuluyor (frontend)...');

      // Load vehicle parts and selections for damage map
      Uint8List? damageMapImageBytes;

      try {
        final vehicleParts = await SvgVehiclePartLoader.instance.load();
        final damageSelections = VehiclePartMapper.tasksToSelections(job.tasks);
        debugPrint('✓ Hasar haritası verileri yüklendi');

        // Generate damage map image
        if (vehicleParts.isNotEmpty && damageSelections.isNotEmpty) {
          damageMapImageBytes = await DamageMapImageGenerator.instance
              .generateDamageMapImage(
                parts: vehicleParts,
                selections: damageSelections,
                size: const Size(600, 400),
              );
          if (damageMapImageBytes != null) {
            debugPrint(
              '✓ Hasar haritası görüntüsü oluşturuldu (${damageMapImageBytes.length} bytes)',
            );
          } else {
            debugPrint('⚠ Hasar haritası görüntüsü oluşturulamadı');
          }
        }
      } catch (e) {
        debugPrint('⚠ Hasar haritası verileri yüklenemedi: $e');
      }

      // Generate PDF with damage map image
      final pdfBytes = await generatePdf(
        job,
        damageMapImageBytes: damageMapImageBytes,
      );

      if (pdfBytes.isEmpty) {
        throw Exception('PDF oluşturulamadı');
      }

      debugPrint('✓ PDF oluşturuldu: ${pdfBytes.length} bytes');

      // Generate filename
      final filename =
          'is_emri_${job.vehicle.plate.replaceAll(' ', '_').replaceAll(RegExp(r'[^\w\-_.]'), '_')}_${DateFormat('yyyyMMdd').format(job.createdAt)}.pdf';

      // Open PDF based on platform
      if (kIsWeb) {
        // For web, open PDF as blob URL in new tab
        openPdfInNewWindow(pdfBytes, filename);
      } else {
        // For mobile/desktop, use Printing.layoutPdf
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
        );
      }
    } catch (e) {
      debugPrint('❌ PDF önizleme hatası: $e');
      rethrow;
    }
  }

  /// Builds damage map section with vehicle illustration
  pw.Widget _buildDamageMapSection(
    JobOrder job,
    pw.Font regularFont,
    pw.Font boldFont,
    List<VehiclePart>? vehicleParts,
    Map<String, List<String>>? damageSelections,
    pw.ImageProvider? damageMapImage,
  ) {
    try {
      // If we have the damage map image, use it
      if (damageMapImage != null) {
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
                'Araç Hasar Haritası',
                style: PdfStyles.textStyle(
                  regularFont: regularFont,
                  boldFont: boldFont,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Container(
                  constraints: const pw.BoxConstraints(
                    maxWidth: 500,
                    maxHeight: 350,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Image(damageMapImage, fit: pw.BoxFit.contain),
                ),
              ),
            ],
          ),
        );
      }

      if (vehicleParts == null || damageSelections == null) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'Hasar haritası verileri yüklenemedi',
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        );
      }

      final parts = vehicleParts;
      final selections = damageSelections;

      // Fallback: Create a simple visual representation
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
              'Araç Hasar Haritası',
              style: PdfStyles.textStyle(
                regularFont: regularFont,
                boldFont: boldFont,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'Seçilen Parçalar:',
              style: PdfStyles.textStyle(
                regularFont: regularFont,
                boldFont: boldFont,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (selections.isEmpty)
              pw.Text(
                'Hasar işaretlenmemiş',
                style: PdfStyles.textStyle(
                  regularFont: regularFont,
                  boldFont: boldFont,
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              )
            else
              pw.Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selections.entries.map((entry) {
                  final partId = entry.key;
                  final actions = entry.value;
                  final area = VehiclePartMapper.partIdToVehicleArea(partId);

                  // Find part for display name
                  VehiclePart? part;
                  try {
                    part = parts.firstWhere((p) => p.id == partId);
                  } catch (_) {
                    part = null;
                  }

                  // Get color for actions
                  PdfColor color = PdfColors.grey300;
                  if (actions.contains(VehicleDamageActions.boya)) {
                    color = PdfColors.blue300;
                  } else if (actions.contains(VehicleDamageActions.kaporta)) {
                    color = PdfColors.orange300;
                  } else if (actions.contains(VehicleDamageActions.degisim)) {
                    color = PdfColors.red300;
                  }

                  final displayName =
                      area?.label ?? (part != null ? part.displayName : partId);

                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Text(
                      displayName,
                      style: PdfStyles.textStyle(
                        regularFont: regularFont,
                        boldFont: boldFont,
                        fontSize: 9,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Hasar haritası oluşturulurken hata: $e');
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'Hasar haritası yüklenemedi: $e',
          style: PdfStyles.textStyle(
            regularFont: regularFont,
            boldFont: boldFont,
            fontSize: 10,
            color: PdfColors.red,
          ),
        ),
      );
    }
  }

  /// Builds color legend explaining what each color means
  pw.Widget _buildColorLegend(pw.Font regularFont, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.grey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Renk Açıklamaları',
            style: PdfStyles.textStyle(
              regularFont: regularFont,
              boldFont: boldFont,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(4),
            },
            children: [
              _buildLegendRow(
                'Mavi',
                PdfColors.blue300,
                'Boya işlemi gereken parçalar',
                regularFont,
                boldFont,
              ),
              _buildLegendRow(
                'Turuncu',
                PdfColors.orange300,
                'Kaporta işlemi gereken parçalar',
                regularFont,
                boldFont,
              ),
              _buildLegendRow(
                'Kırmızı',
                PdfColors.red300,
                'Değişim gereken parçalar',
                regularFont,
                boldFont,
              ),
              _buildLegendRow(
                'Gri',
                PdfColors.grey300,
                'Temizleme gereken parçalar',
                regularFont,
                boldFont,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildLegendRow(
    String colorName,
    PdfColor color,
    String description,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Row(
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  color: color,
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                colorName,
                style: PdfStyles.textStyle(
                  regularFont: regularFont,
                  boldFont: boldFont,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            description,
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
}
