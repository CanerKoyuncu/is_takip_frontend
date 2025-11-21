/// Fotoğraf İşlemleri Servisi
///
/// Bu sınıf, fotoğraf seçme, yükleme ve URL oluşturma işlemlerini yönetir.
///
/// Özellikler:
/// - Galeri/kamera'dan fotoğraf seçme
/// - Fotoğraf yükleme
/// - Fotoğraf URL'leri oluşturma (thumbnail ve full size)

import 'package:image_picker/image_picker.dart';

import '../../../core/config/api_config.dart';
import '../models/job_models.dart';
import 'jobs_api_service.dart';

/// Fotoğraf işlemleri servis sınıfı
///
/// Fotoğraf seçme, yükleme ve URL oluşturma işlemlerini sağlar.
class PhotoService {
  PhotoService(this._jobsApiService);

  // Jobs API servisi - fotoğraf yükleme için
  final JobsApiService _jobsApiService;
  // Image picker - galeri/kamera erişimi için
  final ImagePicker _imagePicker = ImagePicker();

  /// Galeri veya kameradan fotoğraf seçer
  ///
  /// Parametreler:
  /// - source: Fotoğraf kaynağı (galeri veya kamera, varsayılan: galeri)
  ///
  /// Döner: XFile? - Seçilen fotoğraf dosyası veya null (iptal edilirse)
  ///
  /// Not: Fotoğraf kalitesi %85'e düşürülür ve maksimum boyut 1920x1920'dir.
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _imagePicker.pickImage(
        source: source,
        imageQuality: 85, // %85 kalite (dosya boyutunu küçültür)
        maxWidth: 1920, // Maksimum genişlik
        maxHeight: 1920, // Maksimum yükseklik
      );
    } catch (e) {
      return null; // Hata durumunda null döndür
    }
  }

  /// Göreve fotoğraf yükler
  ///
  /// JobsApiService üzerinden fotoğrafı backend'e upload eder.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - filePath: Fotoğraf dosya yolu
  /// - type: Fotoğraf tipi
  /// - stage: Fotoğrafın hangi aşamada yüklendiği (opsiyonel)
  ///
  /// Döner: TaskPhoto - Yüklenen fotoğraf bilgileri
  Future<TaskPhoto> uploadPhotoToTask({
    required String jobId,
    required String taskId,
    required String filePath,
    required TaskPhotoType type,
    JobStatus? stage,
  }) async {
    return await _jobsApiService.uploadPhoto(
      jobId: jobId,
      taskId: taskId,
      filePath: filePath,
      type: type,
      stage: stage,
    );
  }

  /// Download all photos for a job as ZIP
  Future<ApiDownloadResponse> downloadJobPhotosZip({
    required String jobId,
    TaskPhotoType? filterType,
  }) {
    return _jobsApiService.downloadJobPhotosZip(
      jobId: jobId,
      filterType: filterType,
    );
  }

  /// Download all photos for a specific task as ZIP
  Future<ApiDownloadResponse> downloadTaskPhotosZip({
    required String jobId,
    required String taskId,
    TaskPhotoType? filterType,
  }) {
    return _jobsApiService.downloadTaskPhotosZip(
      jobId: jobId,
      taskId: taskId,
      filterType: filterType,
    );
  }

  /// Download a single photo (full size or thumbnail)
  Future<ApiDownloadResponse> downloadTaskPhoto({
    required String jobId,
    required String taskId,
    required String photoId,
    bool thumbnail = false,
  }) {
    return _jobsApiService.downloadTaskPhoto(
      jobId: jobId,
      taskId: taskId,
      photoId: photoId,
      thumbnail: thumbnail,
    );
  }

  /// Fotoğraf için thumbnail URL'i oluşturur (static metod)
  ///
  /// Küçük boyutlu (thumbnail) fotoğraf URL'ini döndürür.
  ///
  /// Parametreler:
  /// - baseUrl: API base URL'i
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - photoId: Fotoğraf ID'si
  ///
  /// Döner: String - Thumbnail URL'i
  static String getThumbnailUrl({
    required String baseUrl,
    required String jobId,
    required String taskId,
    required String photoId,
  }) {
    return '$baseUrl/jobs/$jobId/tasks/$taskId/photos/$photoId/thumbnail';
  }

  /// Fotoğraf için tam boyut URL'i oluşturur (static metod)
  ///
  /// Tam çözünürlüklü fotoğraf URL'ini döndürür.
  ///
  /// Parametreler:
  /// - baseUrl: API base URL'i
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - photoId: Fotoğraf ID'si
  ///
  /// Döner: String - Tam boyut URL'i
  static String getFullImageUrl({
    required String baseUrl,
    required String jobId,
    required String taskId,
    required String photoId,
  }) {
    return '$baseUrl/jobs/$jobId/tasks/$taskId/photos/$photoId';
  }

  /// TaskPhoto objesinden fotoğraf URL'i oluşturur (static metod)
  ///
  /// TaskPhoto objesindeki bilgileri kullanarak fotoğraf URL'ini oluşturur.
  ///
  /// Parametreler:
  /// - photo: TaskPhoto objesi
  /// - baseUrl: API base URL'i
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - thumbnail: Thumbnail mi yoksa tam boyut mu (varsayılan: false)
  ///
  /// Döner: String? - Fotoğraf URL'i veya null (photoId bulunamazsa)
  static String? getPhotoUrl(
    TaskPhoto photo, {
    required String baseUrl,
    required String jobId,
    required String taskId,
    bool thumbnail = false,
  }) {
    // photo.id varsa kullan, yoksa photo.path'ten çıkar
    final photoId = photo.id.isNotEmpty
        ? photo.id
        : photo.path.split('/').last.split('.').first;

    if (photoId.isEmpty) {
      return null;
    }

    // Thumbnail veya tam boyut URL'i döndür
    if (thumbnail) {
      return getThumbnailUrl(
        baseUrl: baseUrl,
        jobId: jobId,
        taskId: taskId,
        photoId: photoId,
      );
    } else {
      return getFullImageUrl(
        baseUrl: baseUrl,
        jobId: jobId,
        taskId: taskId,
        photoId: photoId,
      );
    }
  }

  /// ApiConfig baseUrl kullanarak fotoğraf URL'i oluşturur (static metod)
  ///
  /// ApiConfig'deki baseUrl'i kullanarak fotoğraf URL'ini oluşturur.
  /// Bu metod, ApiConfig.baseUrl'i otomatik kullanır.
  ///
  /// Parametreler:
  /// - photo: TaskPhoto objesi
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - thumbnail: Thumbnail mi yoksa tam boyut mu (varsayılan: false)
  ///
  /// Döner: String? - Fotoğraf URL'i veya null
  static String? getPhotoUrlFromConfig(
    TaskPhoto photo, {
    required String jobId,
    required String taskId,
    bool thumbnail = false,
  }) {
    return getPhotoUrl(
      photo,
      baseUrl: ApiConfig.baseUrl,
      jobId: jobId,
      taskId: taskId,
      thumbnail: thumbnail,
    );
  }
}
