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
import 'pdf/pdf_base_service.dart';
import 'pdf/pdf_report_metadata.dart';
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

  final ApiService _apiService = ApiServiceFactory.getApiService();

  /// TaskPhoto objesini kullanarak API'den fotoğraf yükler (private metod)
  Future<pw.ImageProvider?> _loadPhotoFromApi(
    TaskPhoto photo,
    String jobId,
    String taskId, {
    bool thumbnail = true,
  }) async {
    try {
      final photoUrl = PhotoService.getPhotoUrlFromConfig(
        photo,
        jobId: jobId,
        taskId: taskId,
        thumbnail: thumbnail,
      );

      if (photoUrl == null) return null;

      final response = await _apiService.getBytes(
        photoUrl,
        options: Options(
          headers: {'Accept': 'image/*'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return pw.MemoryImage(response.data!);
      }
    } catch (e) {
      debugPrint('✗ Fotoğraf yükleme hatası: $e');
    }
    return null;
  }

  /// İş emri için PDF belgesi oluşturur
  Future<Uint8List> generatePdf(
    JobOrder job, {
    Uint8List? damageMapImageBytes,
  }) async {
    try {
      // Load shared resources
      await PdfBaseService.ensureFontsLoaded();
      await PdfBaseService.ensureLogoLoaded();

      final regularFont = PdfBaseService.regularFont;
      final boldFont = PdfBaseService.boldFont;
      final logoImage = PdfBaseService.logoImage;

      // Create PDF document with theme
      final pdf = pw.Document(theme: PdfBaseService.getTheme());

      // Prepare Metadata
      final metadata = PdfReportMetadata(
        title: 'İŞ EMRİ RAPORU',
        reportId: job.id.length >= 8 ? job.id.substring(0, 8) : job.id,
        createdAt: job.createdAt,
        statusLabel: job.status.label,
        statusColor: PdfStyles.getStatusColor(job.status),
        plate: job.vehicle.plate,
        brand: job.vehicle.brand,
        model: job.vehicle.model,
      );

      // Load photos for all tasks
      final Map<String, List<pw.ImageProvider>> taskPhotos = {};
      final Map<String, List<TaskPhoto>> taskPhotoMetadata = {};

      for (final task in job.tasks) {
        if (task.photos.isNotEmpty) {
          final photos = <pw.ImageProvider>[];
          final photoMetadata = <TaskPhoto>[];
          for (final photo in task.photos) {
            final imageProvider = await _loadPhotoFromApi(
              photo,
              job.id,
              task.id,
              thumbnail: true,
            );
            if (imageProvider != null) {
              photos.add(imageProvider);
              photoMetadata.add(photo);
            }
          }
          if (photos.isNotEmpty) {
            taskPhotos[task.id] = photos;
            taskPhotoMetadata[task.id] = photoMetadata;
          }
        }
      }

      // Load vehicle parts and selections for damage map
      List<VehiclePart>? vehicleParts;
      Map<String, List<String>>? damageSelections;
      pw.ImageProvider? damageMapImage;

      try {
        vehicleParts = await SvgVehiclePartLoader.instance.load();
        damageSelections = VehiclePartMapper.tasksToSelections(job.tasks);
        if (damageMapImageBytes != null) {
          damageMapImage = pw.MemoryImage(damageMapImageBytes);
        }
      } catch (e) {
        debugPrint('⚠ Hasar haritası verileri yüklenemedi: $e');
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              PdfHeaderBuilder.build(
                metadata,
                regularFont,
                boldFont,
                logoImage,
              ),
              pw.SizedBox(height: 20),
              PdfInfoSectionBuilder.build(
                title: 'İş Emri Bilgileri',
                data: {
                  'Oluşturulma Tarihi': DateFormat(
                    'dd.MM.yyyy HH:mm',
                  ).format(job.createdAt),
                  'Toplam Görev': '${job.tasks.length} görev',
                },
                regularFont: regularFont,
                boldFont: boldFont,
              ),
              pw.SizedBox(height: 20),
              PdfVehicleInfoBuilder.build(
                plate: job.vehicle.plate,
                brand: job.vehicle.brand,
                model: job.vehicle.model,
                regularFont: regularFont,
                boldFont: boldFont,
              ),
              pw.SizedBox(height: 20),
              _buildDamageMapSection(
                job,
                regularFont,
                boldFont,
                vehicleParts,
                damageSelections,
                damageMapImage,
              ),
              pw.SizedBox(height: 20),
              _buildColorLegend(regularFont, boldFont),
              pw.SizedBox(height: 20),
              PdfTasksBuilder.build(
                job,
                regularFont,
                boldFont,
                taskPhotos,
                taskPhotoMetadata,
              ),
              if (job.generalNotes != null && job.generalNotes!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                PdfNotesBuilder.build(job, regularFont, boldFont),
              ],
              pw.SizedBox(height: 20),
              PdfFooterBuilder.build(
                stats: {
                  'Beklemede': job.tasks
                      .where((t) => t.status == JobTaskStatus.pending)
                      .length,
                  'Devam Ediyor': job.tasks
                      .where((t) => t.status == JobTaskStatus.inProgress)
                      .length,
                  'Tamamlandı': job.tasks
                      .where((t) => t.status == JobTaskStatus.completed)
                      .length,
                },
                regularFont: regularFont,
                boldFont: boldFont,
              ),
            ];
          },
        ),
      );

      return pdf.save();
    } catch (e) {
      throw Exception('PDF oluşturma hatası: $e');
    }
  }

  /// PDF'i önizleme ve paylaşma
  Future<void> previewAndShare(
    JobOrder job, {
    BuildContext? context,
    JobsApiService? jobsApiService,
  }) async {
    try {
      Uint8List? damageMapImageBytes;

      try {
        final vehicleParts = await SvgVehiclePartLoader.instance.load();
        final damageSelections = VehiclePartMapper.tasksToSelections(job.tasks);
        if (vehicleParts.isNotEmpty && damageSelections.isNotEmpty) {
          damageMapImageBytes = await DamageMapImageGenerator.instance
              .generateDamageMapImage(
                parts: vehicleParts,
                selections: damageSelections,
                size: const Size(600, 400),
              );
        }
      } catch (e) {
        debugPrint('⚠ Hasar haritası görüntüsü oluşturulamadı: $e');
      }

      final pdfBytes = await generatePdf(
        job,
        damageMapImageBytes: damageMapImageBytes,
      );

      final filename =
          'is_emri_${job.vehicle.plate.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(job.createdAt)}.pdf';

      if (kIsWeb) {
        openPdfInNewWindow(pdfBytes, filename);
      } else {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: filename,
        );
      }
    } catch (e) {
      debugPrint('❌ PDF önizleme hatası: $e');
      rethrow;
    }
  }

  pw.Widget _buildDamageMapSection(
    JobOrder job,
    pw.Font regularFont,
    pw.Font boldFont,
    List<VehiclePart>? vehicleParts,
    Map<String, List<String>>? damageSelections,
    pw.ImageProvider? damageMapImage,
  ) {
    if (damageMapImage != null) {
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
              'Araç Hasar Haritası',
              style: PdfStyles.textStyle(
                regularFont: regularFont,
                boldFont: boldFont,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Container(
                constraints: const pw.BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 250,
                ),
                child: pw.Image(damageMapImage, fit: pw.BoxFit.contain),
              ),
            ),
          ],
        ),
      );
    }
    return pw.SizedBox();
  }

  pw.Widget _buildColorLegend(pw.Font regularFont, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Boya', PdfColors.blue300, regularFont, boldFont),
          _buildLegendItem(
            'Kaporta',
            PdfColors.orange300,
            regularFont,
            boldFont,
          ),
          _buildLegendItem('Değişim', PdfColors.red300, regularFont, boldFont),
        ],
      ),
    );
  }

  pw.Widget _buildLegendItem(
    String label,
    PdfColor color,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Row(
      children: [
        pw.Container(width: 10, height: 10, color: color),
        pw.SizedBox(width: 4),
        pw.Text(
          label,
          style: PdfStyles.textStyle(
            regularFont: regularFont,
            boldFont: boldFont,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
