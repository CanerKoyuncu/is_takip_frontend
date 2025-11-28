/// İş Emirleri API Servisi
///
/// Bu sınıf, backend API ile iş emirleri ile ilgili tüm iletişimi yönetir.
/// CRUD işlemleri, görev yönetimi ve fotoğraf yükleme işlemlerini içerir.
///
/// Özellikler:
/// - İş emri listeleme ve detay
/// - İş emri oluşturma ve güncelleme
/// - Görev başlatma ve tamamlama
/// - Fotoğraf yükleme (multipart/form-data)
/// - PDF rapor oluşturma

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/api_service.dart';
import '../models/job_models.dart';
import '../models/job_task_draft.dart';
import '../models/vehicle_area.dart';
import '../utils/enum_mapper.dart';

/// İş emirleri API servis sınıfı
///
/// Backend API ile iş emirleri endpoint'leri üzerinden iletişim kurar.
class JobsApiService {
  JobsApiService(this._apiService);

  // Temel API servisi - HTTP istekleri için
  final ApiService _apiService;

  /// Tüm iş emirlerini getirir
  ///
  /// Backend'den tüm iş emirlerinin listesini çeker.
  ///
  /// Parametreler:
  /// - search: Arama terimi (plaka, marka, model, müşteri adı, telefon)
  /// - startDate: Başlangıç tarihi (opsiyonel)
  /// - endDate: Bitiş tarihi (opsiyonel)
  /// - limit: Maksimum sonuç sayısı (opsiyonel)
  /// - todayOnly: Sadece bugün oluşturulan iş emirleri (opsiyonel)
  /// - incompleteOnly: Sadece tamamlanmamış iş emirleri (opsiyonel)
  ///
  /// Döner: List<JobOrder> - İş emirleri listesi
  Future<List<JobOrder>> getJobs({
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool? todayOnly,
    bool? incompleteOnly,
  }) async {
    // Query parametrelerini oluştur
    final queryParams = <String, dynamic>{};

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (startDate != null) {
      // YYYY-MM-DD formatında gönder
      queryParams['start_date'] =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    }

    if (endDate != null) {
      // YYYY-MM-DD formatında gönder
      queryParams['end_date'] =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    }

    if (limit != null && limit > 0) {
      queryParams['limit'] = limit;
    }

    if (todayOnly != null) {
      queryParams['today_only'] = todayOnly;
    }

    if (incompleteOnly != null) {
      queryParams['incomplete_only'] = incompleteOnly;
    }

    final response = await _apiService.get(
      '/jobs',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    // Backend response formatı: { "data": [...] } veya direkt array
    final List<dynamic> data = response.data['data'] ?? response.data ?? [];
    // Her JSON objesini JobOrder modeline dönüştür
    return data.map((json) => _jobOrderFromJson(json)).toList();
  }

  /// ID'ye göre iş emri getirir
  ///
  /// Belirli bir iş emrinin detaylarını backend'den çeker.
  ///
  /// Parametreler:
  /// - id: İş emri ID'si
  ///
  /// Döner: JobOrder - İş emri detayı
  Future<JobOrder> getJobById(String id) async {
    final response = await _apiService.get('/jobs/$id');
    // Backend response formatı: { "data": {...} } veya direkt object
    return _jobOrderFromJson(response.data['data'] ?? response.data);
  }

  /// Yeni iş emri oluşturur
  ///
  /// Backend'e yeni iş emri gönderir ve oluşturulan iş emrini döndürür.
  ///
  /// Parametreler:
  /// - vehicle: Araç bilgileri
  /// - taskDrafts: Görev taslakları (backend'de görevlere dönüştürülecek)
  /// - generalNotes: Genel notlar (opsiyonel)
  ///
  /// Döner: JobOrder - Oluşturulan iş emri
  Future<JobOrder> createJob({
    required VehicleInfo vehicle,
    required List<JobTaskDraft> taskDrafts,
    String? generalNotes,
  }) async {
    final response = await _apiService.post(
      '/jobs',
      data: {
        // Araç bilgileri
        'vehicle': {
          'plate': vehicle.plate,
          'brand': vehicle.brand,
          'model': vehicle.model,
        },
        // Görev taslakları - backend formatına dönüştür
        'tasks': taskDrafts
            .map(
              (draft) => {
                'area': EnumMapper.vehicleAreaToBackend(draft.area),
                'operationType': EnumMapper.jobOperationTypeToBackend(
                  draft.operationType,
                ),
                'note': draft.note,
              },
            )
            .toList(),
        'generalNotes': generalNotes,
      },
    );
    return _jobOrderFromJson(response.data['data'] ?? response.data);
  }

  /// İş emrini günceller
  ///
  /// Belirli bir iş emrinin bilgilerini günceller.
  ///
  /// Parametreler:
  /// - id: İş emri ID'si
  /// - updates: Güncellenecek alanlar (key-value çiftleri)
  ///
  /// Döner: JobOrder - Güncellenmiş iş emri
  Future<JobOrder> updateJob(String id, Map<String, dynamic> updates) async {
    final response = await _apiService.put('/jobs/$id', data: updates);
    return _jobOrderFromJson(response.data['data'] ?? response.data);
  }

  /// İş emrine görev ekler
  ///
  /// Mevcut bir iş emrine yeni bir görev ekler.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - area: Araç parçası
  /// - operationType: İşlem tipi
  /// - note: Not (opsiyonel)
  ///
  /// Döner: JobOrder - Güncellenmiş iş emri
  Future<JobOrder> addTaskToJob({
    required String jobId,
    required VehicleArea area,
    required JobOperationType operationType,
    String? note,
  }) async {
    final response = await _apiService.post(
      '/jobs/$jobId/tasks',
      data: {
        'area': EnumMapper.vehicleAreaToBackend(area),
        'operationType': EnumMapper.jobOperationTypeToBackend(operationType),
        if (note != null) 'note': note,
      },
    );
    return _jobOrderFromJson(response.data['data'] ?? response.data);
  }

  /// Görevi başlatır
  ///
  /// Backend'e görevin başlatıldığını bildirir.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - assignedWorkerId: Atanan personel ID'si (opsiyonel)
  Future<void> startTask({
    required String jobId,
    required String taskId,
    String? assignedWorkerId,
  }) async {
    await _apiService.patch(
      '/jobs/$jobId/tasks/$taskId/start',
      data: {
        if (assignedWorkerId != null) 'assignedWorkerId': assignedWorkerId,
      },
    );
  }

  /// Görevi duraklatır
  ///
  /// Backend'e görevin duraklatıldığını bildirir.
  /// Mevcut çalışma oturumu kaydedilir.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - note: Duraklatma notu (opsiyonel)
  Future<void> pauseTask({
    required String jobId,
    required String taskId,
    String? note,
  }) async {
    await _apiService.patch(
      '/jobs/$jobId/tasks/$taskId/pause',
      data: {if (note != null && note.isNotEmpty) 'note': note},
    );
  }

  /// Görevi devam ettirir
  ///
  /// Backend'e görevin devam ettirildiğini bildirir.
  /// Yeni bir çalışma oturumu başlatılır.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - assignedWorkerId: Devam ettirecek personel ID'si (farklı personel olabilir)
  Future<void> resumeTask({
    required String jobId,
    required String taskId,
    required String assignedWorkerId,
  }) async {
    await _apiService.patch(
      '/jobs/$jobId/tasks/$taskId/resume',
      data: {'assignedWorkerId': assignedWorkerId},
    );
  }

  /// Görevi günceller
  ///
  /// Backend'e görevin engelleme nedenini günceller.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - blockingReason: Engelleme nedeni (opsiyonel, null ise temizlenir)
  Future<void> updateTask({
    required String jobId,
    required String taskId,
    TaskBlockingReason? blockingReason,
    bool updateBlockingReason = false,
    bool? isTaskAvailable,
    String? note,
  }) async {
    final data = <String, dynamic>{};
    if (updateBlockingReason) {
      data['blockingReason'] = blockingReason != null
          ? EnumMapper.taskBlockingReasonToBackend(blockingReason)
          : null;
    }
    if (isTaskAvailable != null) {
      data['isTaskAvailable'] = isTaskAvailable;
    }
    if (note != null) {
      data['note'] = note;
    }

    await _apiService.patch('/jobs/$jobId/tasks/$taskId', data: data);
  }

  /// İş emrini günceller
  ///
  /// Backend'e iş emrinin araç durumunu günceller.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - isVehicleAvailable: Arabanın üzerinde çalışılabilir mi
  Future<void> updateJobVehicleAvailability({
    required String jobId,
    required bool isVehicleAvailable,
  }) async {
    await _apiService.patch(
      '/jobs/$jobId',
      data: {'isVehicleAvailable': isVehicleAvailable},
    );
  }

  /// İş emrinin araç aşamasını günceller
  ///
  /// Backend'e iş emrinin araç aşamasını günceller.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - vehicleStage: Araç aşaması (none, insurance_approval_waiting, expert_waiting, part_waiting)
  Future<void> updateJobVehicleStage({
    required String jobId,
    required String? vehicleStage,
  }) async {
    await _apiService.patch(
      '/jobs/$jobId',
      data: {'vehicleStage': vehicleStage},
    );
  }

  /// Görevi tamamlar
  ///
  /// Backend'e görevin tamamlandığını bildirir.
  /// Not ve tamamlanma fotoğrafı eklenebilir.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - note: Tamamlanma notu (opsiyonel)
  /// - completionPhotoPath: Tamamlanma fotoğrafı yolu (opsiyonel)
  Future<void> completeTask({
    required String jobId,
    required String taskId,
    String? note,
    String? completionPhotoPath,
  }) async {
    await _apiService.patch(
      '/jobs/$jobId/tasks/$taskId/complete',
      data: {
        // Not varsa ekle
        if (note != null) 'note': note,
        // Tamamlanma fotoğrafı varsa ekle
        if (completionPhotoPath != null)
          'completionPhotoPath': completionPhotoPath,
      },
    );
  }

  Future<List<JobNote>> getJobNotes(String jobId) async {
    final response = await _apiService.get('/jobs/$jobId/notes');
    final data = response.data as List<dynamic>;
    return data
        .map((item) => JobNote.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<JobNote> upsertJobNote({
    required String jobId,
    String? taskId,
    required String content,
  }) async {
    final response = await _apiService.put(
      '/jobs/$jobId/notes',
      data: {'content': content, if (taskId != null) 'taskId': taskId},
    );
    return JobNote.fromJson(response.data as Map<String, dynamic>);
  }

  /// Download all photos for a job as ZIP
  Future<ApiDownloadResponse> downloadJobPhotosZip({
    required String jobId,
    TaskPhotoType? filterType,
  }) async {
    final response = await _apiService.get<List<int>>(
      '/jobs/$jobId/photos/download',
      queryParameters: filterType != null
          ? {'photo_type': EnumMapper.taskPhotoTypeToBackend(filterType)}
          : null,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    return _buildDownloadResponse(
      response,
      fallbackName: 'is_emri_${jobId}_fotolar.zip',
      fallbackType: 'application/zip',
    );
  }

  /// Download all photos for a task as ZIP
  Future<ApiDownloadResponse> downloadTaskPhotosZip({
    required String jobId,
    required String taskId,
    TaskPhotoType? filterType,
  }) async {
    final response = await _apiService.get<List<int>>(
      '/jobs/$jobId/tasks/$taskId/photos/download',
      queryParameters: filterType != null
          ? {'photo_type': EnumMapper.taskPhotoTypeToBackend(filterType)}
          : null,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    return _buildDownloadResponse(
      response,
      fallbackName: 'is_emri_${jobId}_task_${taskId}_fotolar.zip',
      fallbackType: 'application/zip',
    );
  }

  /// Download a single task photo with export filename
  Future<ApiDownloadResponse> downloadTaskPhoto({
    required String jobId,
    required String taskId,
    required String photoId,
    bool thumbnail = false,
  }) async {
    final path = thumbnail
        ? '/jobs/$jobId/tasks/$taskId/photos/$photoId/thumbnail'
        : '/jobs/$jobId/tasks/$taskId/photos/$photoId';

    final response = await _apiService.get<List<int>>(
      path,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    return _buildDownloadResponse(
      response,
      fallbackName: 'photo_$photoId.jpg',
      fallbackType: 'image/jpeg',
    );
  }

  /// Göreve fotoğraf yükler
  ///
  /// Multipart/form-data formatında fotoğrafı backend'e upload eder.
  /// Hem web hem de mobil platformlarda çalışır.
  ///
  /// İşlem Adımları:
  /// 1. Dosyayı bytes olarak okur
  /// 2. MIME type'ını belirler
  /// 3. MultipartFile oluşturur
  /// 4. FormData ile backend'e gönderir
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - filePath: Fotoğraf dosya yolu
  /// - type: Fotoğraf tipi
  ///
  /// Döner: TaskPhoto - Yüklenen fotoğraf bilgileri
  Future<TaskPhoto> uploadPhoto({
    required String jobId,
    required String taskId,
    required String filePath,
    required TaskPhotoType type,
    JobStatus? stage,
  }) async {
    debugPrint(
      '📸 JobsApiService.uploadPhoto: jobId=$jobId, taskId=$taskId, type=$type',
    );

    // Dosyayı bytes olarak oku (web ve mobil için çalışır)
    final XFile xFile = XFile(filePath);
    final Uint8List fileBytes = await xFile.readAsBytes();

    // MIME type'ı al veya dosyadan belirle
    String? contentType = xFile.mimeType;

    // Dosya uzantısını belirle ve dosya adının doğru uzantıya sahip olduğundan emin ol
    String fileExtension = '.jpg'; // Varsayılan
    if (contentType != null && contentType.isNotEmpty) {
      // MIME type'ı uzantıya map et
      if (contentType.contains('jpeg') || contentType.contains('jpg')) {
        fileExtension = '.jpg';
        if (contentType != 'image/jpeg') {
          contentType = 'image/jpeg'; // Normalize et
        }
      } else if (contentType.contains('png')) {
        fileExtension = '.png';
        if (contentType != 'image/png') {
          contentType = 'image/png'; // Normalize et
        }
      } else if (contentType.contains('webp')) {
        fileExtension = '.webp';
        if (contentType != 'image/webp') {
          contentType = 'image/webp'; // Normalize et
        }
      }
    }

    // Doğru uzantılı dosya adı oluştur
    // Web'de XFile.name boş veya blob URL olabilir, bu yüzden ad oluştururuz
    String fileName = xFile.name;
    if (fileName.isEmpty ||
        fileName.startsWith('blob:') ||
        !fileName.contains('.')) {
      // Timestamp ile dosya adı oluştur
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      fileName = 'photo_$timestamp$fileExtension';
    } else {
      // Dosya adının doğru uzantıya sahip olduğundan emin ol
      final currentExt = fileName.split('.').last.toLowerCase();
      final validExts = ['jpg', 'jpeg', 'png', 'webp'];
      if (!validExts.contains(currentExt)) {
        // Uzantıyı belirlenen uzantı ile değiştir
        final nameWithoutExt = fileName.split('.').first;
        fileName = '$nameWithoutExt$fileExtension';
      } else {
        // Uzantıyı normalize et (jpeg -> jpg)
        if (currentExt == 'jpeg') {
          final nameWithoutExt = fileName.split('.').first;
          fileName = '$nameWithoutExt.jpg';
          fileExtension = '.jpg';
        }
      }
    }

    debugPrint(
      '📸 File info: originalName=${xFile.name}, finalName=$fileName, contentType=$contentType, size=${fileBytes.length}',
    );

    // Bytes'tan MultipartFile oluştur (web uyumlu) ve content type ekle
    final file = MultipartFile.fromBytes(
      fileBytes,
      filename: fileName,
      contentType: contentType != null ? DioMediaType.parse(contentType) : null,
    );

    // FormData oluştur - dosya, fotoğraf tipi ve aşama
    final formDataMap = <String, dynamic>{
      'file': file,
      'photo_type': EnumMapper.taskPhotoTypeToBackend(type),
    };
    // Aşama bilgisi varsa ekle
    if (stage != null) {
      formDataMap['stage'] = EnumMapper.jobStatusToBackend(stage);
    }
    final formData = FormData.fromMap(formDataMap);

    debugPrint('📸 Sending POST /jobs/$jobId/tasks/$taskId/photos');

    // Multipart/form-data ile backend'e gönder
    final response = await _apiService.post(
      '/jobs/$jobId/tasks/$taskId/photos',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    debugPrint('📸 Upload response: ${response.statusCode}');
    debugPrint('📸 Response data: ${response.data}');

    // Backend döner: {"success": true, "data": {"photoId": "...", "path": "..."}}
    // Tam fotoğraf objesi için iş emrini yeniden yüklemek gerekir
    // Şimdilik response data'dan TaskPhoto oluştur
    final responseData = response.data['data'] ?? response.data;

    debugPrint('📸 Response data extracted: $responseData');

    // Eğer sadece photoId ve path varsa, minimal TaskPhoto oluştur
    // Tam fotoğraf objesi iş emri yenilendiğinde gelecek
    if (responseData is Map<String, dynamic>) {
      final photoId =
          responseData['photoId'] as String? ??
          responseData['id'] as String? ??
          '';
      final path = responseData['path'] as String? ?? '';

      debugPrint('📸 Created TaskPhoto: id=$photoId, path=$path');

      // Geçici TaskPhoto oluştur - tam veri iş emri yenilendiğinde gelecek
      return TaskPhoto(
        id: photoId,
        path: path,
        type: type,
        createdAt: DateTime.now(),
        stage: stage,
      );
    }

    // Fallback: tam fotoğraf objesi olarak parse etmeyi dene
    debugPrint('📸 Parsing as full photo object');
    return _taskPhotoFromJson(responseData);
  }

  /// Göreve hasar fotoğrafı ekler (deprecated - uploadPhoto kullanın)
  ///
  /// Bu metod artık kullanılmıyor. Bunun yerine uploadPhoto() metodunu kullanın.
  ///
  /// Deprecated: uploadPhoto() metoduna geçiş yapılmalı
  @Deprecated('Use uploadPhoto instead')
  Future<void> addDamagePhoto({
    required String jobId,
    required String taskId,
    required String photoPath,
  }) async {
    // uploadPhoto metodunu hasar fotoğrafı tipi ile çağır
    await uploadPhoto(
      jobId: jobId,
      taskId: taskId,
      filePath: photoPath,
      type: TaskPhotoType.damage,
    );
  }

  /// JSON'dan JobOrder'a dönüştürür (private metod)
  ///
  /// Backend'den gelen JSON response'u JobOrder modeline dönüştürür.
  JobOrder _jobOrderFromJson(Map<String, dynamic> json) {
    final vehicleJson = json['vehicle'] as Map<String, dynamic>;
    return JobOrder(
      id: json['id'] as String,
      vehicle: VehicleInfo(
        plate: vehicleJson['plate'] as String,
        brand: vehicleJson['brand'] as String? ?? '',
        model: vehicleJson['model'] as String? ?? '',
      ),

      // Görevleri JSON'dan parse et
      tasks:
          (json['tasks'] as List<dynamic>?)
              ?.map((taskJson) => _jobTaskFromJson(taskJson))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      generalNotes: json['generalNotes'] as String?,
      isVehicleAvailable: json['isVehicleAvailable'] as bool? ?? true,
      vehicleStage: json['vehicleStage'] as String?,
    );
  }

  /// JSON'dan JobTask'a dönüştürür (private metod)
  ///
  /// Backend'den gelen görev JSON'unu JobTask modeline dönüştürür.
  TaskWorkSession _workSessionFromJson(Map<String, dynamic> json) {
    return TaskWorkSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      workerId: json['workerId'] as String?,
      workerName: json['workerName'] as String?,
      durationSeconds: json['durationSeconds'] != null
          ? (json['durationSeconds'] as num).toDouble()
          : null,
    );
  }

  JobTask _jobTaskFromJson(Map<String, dynamic> json) {
    return JobTask(
      id: json['id'] as String,
      // Backend string formatından enum'a dönüştür
      area: EnumMapper.vehicleAreaFromBackend(json['area'] as String),
      operationType: EnumMapper.jobOperationTypeFromBackend(
        json['operationType'] as String,
      ),
      note: json['note'] as String?,
      status: EnumMapper.jobTaskStatusFromBackend(json['status'] as String),
      // Tarihleri parse et (null olabilir)
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      assignedWorkerId: json['assignedWorkerId'] as String?,
      assignedWorkerName: json['assignedWorkerName'] as String?,
      blockingReason: json['blockingReason'] != null
          ? EnumMapper.taskBlockingReasonFromBackend(
              json['blockingReason'] as String,
            )
          : null,
      isTaskAvailable: json['isTaskAvailable'] as bool? ?? true,
      // Fotoğrafları JSON'dan parse et
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((photoJson) => _taskPhotoFromJson(photoJson))
              .toList() ??
          [],
      // Çalışma oturumlarını JSON'dan parse et
      workSessions:
          (json['workSessions'] as List<dynamic>?)
              ?.map((sessionJson) => _workSessionFromJson(sessionJson))
              .toList() ??
          [],
    );
  }

  /// JSON'dan TaskPhoto'ya dönüştürür (private metod)
  ///
  /// Backend'den gelen fotoğraf JSON'unu TaskPhoto modeline dönüştürür.
  /// Backend formatı: {"_id": ObjectId, "id": str, "path": str, "type": str, "createdAt": datetime}
  TaskPhoto _taskPhotoFromJson(Map<String, dynamic> json) {
    // Backend "_id" (ObjectId) veya "id" (string) dönebilir
    final photoId =
        json['id'] as String? ??
        json['_id']?.toString() ??
        json['photoId'] as String? ??
        '';

    // Path zorunlu
    final path = json['path'] as String? ?? '';

    // Tip belirtilmemişse varsayılan "damage"
    final typeStr = json['type'] as String? ?? 'damage';
    final type = EnumMapper.taskPhotoTypeFromBackend(typeStr);

    // createdAt'i parse et - ISO string veya DateTime olabilir
    DateTime createdAt;
    if (json['createdAt'] != null) {
      if (json['createdAt'] is String) {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } else if (json['createdAt'] is DateTime) {
        createdAt = json['createdAt'] as DateTime;
      } else {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    // Stage bilgisini parse et (opsiyonel)
    final stageStr = json['stage'] as String?;
    final stage = EnumMapper.jobStatusFromBackend(stageStr);

    return TaskPhoto(
      id: photoId,
      path: path,
      type: type,
      createdAt: createdAt,
      stage: stage,
    );
  }

  /// İş emri için PDF raporu getirir
  ///
  /// Backend'den iş emrinin PDF raporunu bytes olarak alır.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  ///
  /// Döner: Uint8List - PDF dosyası bytes
  ///
  /// Not: Bu metod backend'den PDF alır. Frontend'de PDF oluşturmak için
  /// JobOrderPdfService kullanılabilir.
  Future<Uint8List> getJobPdf(String jobId) async {
    debugPrint('📄 Requesting PDF for job: $jobId');

    // PDF'i bytes olarak al
    final response = await _apiService.get<Uint8List>(
      '/jobs/$jobId/pdf',
      options: Options(
        responseType: ResponseType.bytes, // Bytes olarak al
        validateStatus: (status) =>
            status! < 500, // 500'den küçük status kodlarını kabul et
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      debugPrint('✓ PDF received: ${response.data!.length} bytes');
      return response.data!;
    } else {
      throw Exception('PDF alınamadı: ${response.statusCode}');
    }
  }

  ApiDownloadResponse _buildDownloadResponse(
    Response<List<int>> response, {
    required String fallbackName,
    required String fallbackType,
  }) {
    if (response.statusCode != null && response.statusCode! >= 400) {
      final status = response.statusCode!;
      throw Exception('Dosya indirilemedi (HTTP $status)');
    }

    final bytesData = response.data;
    final bytes = bytesData is Uint8List
        ? bytesData
        : Uint8List.fromList(bytesData ?? <int>[]);

    final headers = response.headers;
    final contentType =
        headers.value('content-type') ?? headers.value('Content-Type');
    final contentDisposition =
        headers.value('content-disposition') ??
        headers.value('Content-Disposition');

    final filename =
        _extractFilenameFromContentDisposition(contentDisposition) ??
        fallbackName;

    return ApiDownloadResponse(
      bytes: bytes,
      filename: filename,
      contentType: contentType ?? fallbackType,
    );
  }

  String? _extractFilenameFromContentDisposition(String? header) {
    if (header == null || header.isEmpty) {
      return null;
    }

    final filenameRegex = RegExp(
      "filename\\*?=(?:UTF-8'')?\"?([^\";]+)\"?",
      caseSensitive: false,
    );
    final match = filenameRegex.firstMatch(header);
    if (match == null) {
      return null;
    }

    var filename = match.group(1) ?? '';
    filename = filename.replaceAll('"', '').trim();
    if (filename.contains("''")) {
      final parts = filename.split("''");
      filename = parts.last;
    }
    return Uri.decodeFull(filename);
  }

  /// Görevi mevcut kullanıcıya atar
  ///
  /// Personel, müsait bir görevi kendisine atayabilir.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  ///
  /// Döner: void - Başarılı olursa exception fırlatmaz
  Future<void> assignTask({
    required String jobId,
    required String taskId,
  }) async {
    final response = await _apiService.patch(
      '/jobs/$jobId/tasks/$taskId/assign',
    );

    if (response.data['success'] != true) {
      throw Exception('Görev atama başarısız');
    }
  }

  /// Mevcut kullanıcıya atanmış görevleri getirir
  ///
  /// Personel, kendisine atanmış görevleri görebilir.
  ///
  /// Parametreler:
  /// - statusFilter: Görev durumu filtresi (pending, in_progress, completed)
  ///
  /// Döner: List<JobOrder> - Atanmış görevleri içeren iş emirleri listesi
  Future<List<JobOrder>> getMyTasks({String? statusFilter}) async {
    final queryParams = <String, dynamic>{};
    if (statusFilter != null) {
      queryParams['status_filter'] = statusFilter;
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      '/jobs/tasks/my-tasks',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final jobsData = response.data?['data'] ?? [];
    return (jobsData as List<dynamic>)
        .map((job) => _jobOrderFromJson(job as Map<String, dynamic>))
        .toList();
  }

  /// Müsait görevleri getirir (atanmamış görevler)
  ///
  /// Personel, henüz atanmamış görevleri görebilir ve alabilir.
  ///
  /// Döner: List<JobOrder> - Müsait görevleri içeren iş emirleri listesi
  Future<List<JobOrder>> getAvailableTasks() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/jobs/tasks/available',
    );

    final jobsData = response.data?['data'] ?? [];
    return (jobsData as List<dynamic>)
        .map((job) => _jobOrderFromJson(job as Map<String, dynamic>))
        .toList();
  }

  /// Tüm atanmış görevleri getirir (supervisor ve üzeri için)
  ///
  /// Hangi personele atanmış olursa olsun tüm atanmış görevleri gösterir.
  ///
  /// Döner: List<JobOrder> - Atanmış görevleri içeren iş emirleri listesi
  Future<List<JobOrder>> getAllAssignedTasks() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/jobs/tasks/all-assigned',
    );

    final jobsData = response.data?['data'] ?? [];
    return (jobsData as List<dynamic>)
        .map((job) => _jobOrderFromJson(job as Map<String, dynamic>))
        .toList();
  }

  /// Bekleyen görevleri getirir (supervisor ve üzeri için)
  ///
  /// Henüz başlanmamış (pending) görevleri gösterir.
  ///
  /// Döner: List<JobOrder> - Bekleyen görevleri içeren iş emirleri listesi
  Future<List<JobOrder>> getPendingTasks() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '/jobs/tasks/pending',
    );

    final jobsData = response.data?['data'] ?? [];
    return (jobsData as List<dynamic>)
        .map((job) => _jobOrderFromJson(job as Map<String, dynamic>))
        .toList();
  }
}

class ApiDownloadResponse {
  ApiDownloadResponse({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}
