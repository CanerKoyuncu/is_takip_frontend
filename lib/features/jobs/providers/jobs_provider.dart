/// İş Emirleri Provider'ı
///
/// Bu sınıf, iş emirleri ile ilgili tüm state yönetimini yapar.
/// ChangeNotifier kullanarak state değişikliklerini dinleyicilere bildirir.
///
/// Sorumlulukları:
/// - İş emirlerini backend'den yükleme
/// - İş emri oluşturma
/// - Görev durumlarını güncelleme (başlatma, tamamlama)
/// - Fotoğraf yükleme
/// - Not güncelleme
/// - State cache yönetimi

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/job_models.dart';
import '../models/job_task_draft.dart';
import '../services/jobs_api_service.dart';
import '../utils/download_helper_stub.dart'
    if (dart.library.html) '../utils/download_helper_web.dart'
    as download_helper;
import 'package:vehicle_damage_map/vehicle_damage_map.dart'
    show PartSupplySource, PartSupplyStatus;

/// İş emirleri provider sınıfı
///
/// Tüm iş emri işlemlerini yönetir ve state değişikliklerini
/// dinleyicilere bildirir (ChangeNotifier pattern).
class JobsProvider extends ChangeNotifier {
  /// Constructor
  ///
  /// JobsApiService'i dependency injection ile alır.
  /// Başlatıldığında iş emirlerini otomatik yükler.
  JobsProvider({required JobsApiService jobsApiService})
    : _jobsApiService = jobsApiService {
    // Başlatıldığında iş emirlerini yükle
    loadJobs();
  }

  // Backend API servisi - tüm API işlemleri için
  final JobsApiService _jobsApiService;
  // İş emirleri cache'i - backend'den yüklenen iş emirleri
  final List<JobOrder> _jobs = [];
  // Personel görevleri cache'i - kendisine atanmış görevler
  final List<JobOrder> _myTasks = [];
  // Müsait görevler cache'i - atanmamış görevler
  final List<JobOrder> _availableTasks = [];
  // Tüm atanmış görevler cache'i - supervisor için
  final List<JobOrder> _allAssignedTasks = [];
  // Bekleyen görevler cache'i - supervisor için
  final List<JobOrder> _pendingTasks = [];
  // İş notları cache'i (jobId -> notes)
  final Map<String, List<JobNote>> _jobNotes = {};
  // Yükleme durumu - API isteği devam ediyor mu?
  bool _isLoading = false;
  // Hata mesajı - işlem başarısız olduğunda
  String? _errorMessage;

  /// İş emirleri listesi (immutable)
  List<JobOrder> get jobs => List.unmodifiable(_jobs);

  /// Personel görevleri listesi (immutable)
  List<JobOrder> get myTasks => List.unmodifiable(_myTasks);

  /// Müsait görevler listesi (immutable)
  List<JobOrder> get availableTasks => List.unmodifiable(_availableTasks);

  /// Tüm atanmış görevler listesi (immutable) - supervisor için
  List<JobOrder> get allAssignedTasks => List.unmodifiable(_allAssignedTasks);

  /// Bekleyen görevler listesi (immutable) - supervisor için
  List<JobOrder> get pendingTasks => List.unmodifiable(_pendingTasks);

  Map<String, List<JobNote>> get jobNotes => Map.unmodifiable(
    _jobNotes.map(
      (key, value) => MapEntry(key, List<JobNote>.unmodifiable(value)),
    ),
  );

  /// Yükleme durumu
  bool get isLoading => _isLoading;

  /// Hata mesajı
  String? get errorMessage => _errorMessage;

  /// ID'ye göre iş emri bulur (cache'den)
  ///
  /// Parametreler:
  /// - id: İş emri ID'si
  ///
  /// Döner: JobOrder? - Bulunursa iş emri, bulunamazsa null
  JobOrder? jobById(String id) {
    try {
      return _jobs.firstWhere((job) => job.id == id);
    } catch (_) {
      return null;
    }
  }

  List<JobNote> jobNotesForJob(String jobId) {
    return List<JobNote>.unmodifiable(_jobNotes[jobId] ?? const []);
  }

  JobNote? generalNoteForJob(String jobId) {
    final notes = _jobNotes[jobId];
    if (notes == null) return null;
    for (final note in notes) {
      if (note.taskId == null) return note;
    }
    return null;
  }

  JobNote? taskNoteForJob(String jobId, String taskId) {
    final notes = _jobNotes[jobId];
    if (notes == null) return null;
    for (final note in notes) {
      if (note.taskId == taskId) return note;
    }
    return null;
  }

  bool jobNotesLoaded(String jobId) => _jobNotes.containsKey(jobId);

  /// Belirli bir iş emrini API'den yükler
  ///
  /// Önce cache'i kontrol eder, yoksa API'den yükler.
  /// Yüklenen iş emri cache'e eklenir.
  ///
  /// Parametreler:
  /// - id: İş emri ID'si
  ///
  /// Döner: JobOrder? - Yüklenen iş emri veya null (hata durumunda)
  Future<JobOrder?> loadJobById(String id) async {
    // Önce cache'i kontrol et
    final cached = jobById(id);
    if (cached != null) return cached; // Cache'de varsa döndür

    // Cache'de yoksa API'den yükle
    _setLoading(true);
    _setError(null);

    try {
      // API'den iş emrini yükle
      final job = await _jobsApiService.getJobById(id);
      // Cache'e ekle veya güncelle
      final index = _jobs.indexWhere((j) => j.id == id);
      if (index == -1) {
        _jobs.add(job); // Yeni ise ekle
      } else {
        _jobs[index] = job; // Varsa güncelle
      }
      if (_jobNotes.containsKey(id)) {
        _applyNotesToJob(id, _jobNotes[id]!);
      }
      notifyListeners();
      return job;
    } catch (e) {
      _setError('İş emri yüklenirken hata oluştu: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// İş emirlerini yükler (ilk yükleme)
  ///
  /// Varsayılan olarak bugün oluşturulan ve tamamlanmamış iş emirlerini yükler.
  Future<void> loadJobs() async {
    await refreshJobs(todayOnly: true, incompleteOnly: true);
  }

  /// İş emirlerini API'den yeniler
  ///
  /// Tüm iş emirlerini backend'den çeker ve cache'i günceller.
  /// Bu metod çağrıldığında mevcut cache temizlenir ve
  /// yeni veriler yüklenir.
  ///
  /// Parametreler:
  /// - search: Arama terimi (opsiyonel)
  /// - startDate: Başlangıç tarihi (opsiyonel)
  /// - endDate: Bitiş tarihi (opsiyonel)
  /// - limit: Maksimum sonuç sayısı (opsiyonel)
  /// - todayOnly: Sadece bugün oluşturulan iş emirleri (opsiyonel)
  /// - incompleteOnly: Sadece tamamlanmamış iş emirleri (opsiyonel)
  /// - allCompletedOnly: Sadece tüm görevleri tamamlanmış iş emirleri (opsiyonel)
  Future<void> refreshJobs({
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    bool? todayOnly,
    bool? incompleteOnly,
    bool? allCompletedOnly,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // API'den filtrelenmiş iş emirlerini yükle
      final jobs = await _jobsApiService.getJobs(
        search: search,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        todayOnly: todayOnly,
        incompleteOnly: incompleteOnly,
        allCompletedOnly: allCompletedOnly,
      );
      // Cache'i temizle ve yeni verilerle doldur
      _jobs.clear();
      _jobs.addAll(jobs);
      // State değişikliğini bildir
      notifyListeners();
    } catch (e) {
      _setError('İş listesi yüklenirken hata oluştu: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Yeni iş emri oluşturur
  ///
  /// Backend'e yeni iş emri gönderir ve başarılı olursa
  /// cache'in başına ekler (en yeni iş emri en üstte).
  ///
  /// Parametreler:
  /// - vehicle: Araç bilgileri
  /// - taskDrafts: Görev taslakları (henüz oluşturulmamış görevler)
  /// - generalNotes: Genel notlar (opsiyonel)
  ///
  /// Döner: JobOrder? - Oluşturulan iş emri veya null (hata durumunda)
  Future<JobOrder?> createJob({
    required VehicleInfo vehicle,
    required List<JobTaskDraft> taskDrafts,
    String? generalNotes,
    List<String> requiredParts = const [],
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Backend'e iş emri oluşturma isteği gönder
      final job = await _jobsApiService.createJob(
        vehicle: vehicle,
        taskDrafts: taskDrafts,
        generalNotes: generalNotes,
        requiredParts: requiredParts,
      );

      // Başarılı olursa cache'in başına ekle (en yeni en üstte)
      _jobs.insert(0, job);
      notifyListeners();
      return job;
    } catch (e) {
      _setError('İş oluşturulurken hata oluştu: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Download all photos for a job as ZIP archive.
  Future<String?> downloadJobPhotosZip({
    required String jobId,
    TaskPhotoType? filterType,
  }) async {
    final download = await _jobsApiService.downloadJobPhotosZip(
      jobId: jobId,
      filterType: filterType,
    );
    return download_helper.saveBytes(
      download.bytes,
      download.filename,
      mimeType: download.contentType,
    );
  }

  /// Download all photos for a specific task as ZIP archive.
  Future<String?> downloadTaskPhotosZip({
    required String jobId,
    required String taskId,
    TaskPhotoType? filterType,
  }) async {
    final download = await _jobsApiService.downloadTaskPhotosZip(
      jobId: jobId,
      taskId: taskId,
      filterType: filterType,
    );
    return download_helper.saveBytes(
      download.bytes,
      download.filename,
      mimeType: download.contentType,
    );
  }

  /// Download a single photo (full size or thumbnail).
  Future<String?> downloadTaskPhoto({
    required String jobId,
    required String taskId,
    required String photoId,
    bool thumbnail = false,
  }) async {
    final download = await _jobsApiService.downloadTaskPhoto(
      jobId: jobId,
      taskId: taskId,
      photoId: photoId,
      thumbnail: thumbnail,
    );
    return download_helper.saveBytes(
      download.bytes,
      download.filename,
      mimeType: download.contentType,
    );
  }

  /// Görevi başlatır
  ///
  /// Optimistic update pattern kullanır:
  /// 1. Önce UI'ı günceller (anında görünüm)
  /// 2. Backend'e istek gönderir
  /// 3. Başarısız olursa geri alır (rollback)
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
    // İş emrini cache'de bul
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) {
      _setError('İş bulunamadı');
      return;
    }

    final job = _jobs[index];

    // Optimistic update - önce UI'ı güncelle
    final updatedTasks = job.tasks.map((task) {
      if (task.id != taskId) return task; // Bu görev değilse değiştirme
      if (task.status == JobTaskStatus.inProgress)
        return task; // Zaten başlamışsa değiştirme
      // Görevi başlatılmış olarak işaretle
      return task.copyWith(
        status: JobTaskStatus.inProgress,
        startedAt: DateTime.now(),
        assignedWorkerId: assignedWorkerId,
      );
    }).toList();

    // Cache'i güncelle
    _jobs[index] = job.copyWith(tasks: updatedTasks);
    notifyListeners();

    try {
      // Backend'e görevi başlatma isteği gönder
      await _jobsApiService.startTask(
        jobId: jobId,
        taskId: taskId,
        assignedWorkerId: assignedWorkerId,
      );
      // Backend'den güncel veriyi al (server timestamp için)
      await _refreshJob(jobId);
    } catch (e) {
      // Hata olursa geri al (rollback)
      _jobs[index] = job;
      notifyListeners();
      _setError('Görev başlatılırken hata oluştu: ${e.toString()}');
    }
  }

  /// Görevi duraklatır
  ///
  /// Optimistic update pattern kullanır.
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
    // İş emrini cache'de bul
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) {
      _setError('İş bulunamadı');
      return;
    }

    final job = _jobs[index];

    // Optimistic update - önce UI'ı güncelle
    final updatedTasks = job.tasks.map((task) {
      if (task.id != taskId) return task; // Bu görev değilse değiştirme
      if (task.status != JobTaskStatus.inProgress)
        return task; // Sadece devam eden görevler duraklatılabilir

      // Görevi duraklatılmış olarak işaretle
      return task.copyWith(
        status: JobTaskStatus.paused,
        note: note != null && note.isNotEmpty
            ? (task.note != null && task.note!.isNotEmpty
                  ? '${task.note}\n[Duraklatma] $note'
                  : '[Duraklatma] $note')
            : task.note,
      );
    }).toList();

    // Cache'i güncelle
    _jobs[index] = job.copyWith(tasks: updatedTasks);
    notifyListeners();

    try {
      // Backend'e görevi duraklatma isteği gönder
      await _jobsApiService.pauseTask(jobId: jobId, taskId: taskId, note: note);
      // Backend'den güncel veriyi al (workSessions için)
      await _refreshJob(jobId);
    } catch (e) {
      // Hata olursa geri al (rollback)
      _jobs[index] = job;
      notifyListeners();
      _setError('Görev duraklatılırken hata oluştu: ${e.toString()}');
    }
  }

  /// Görevi devam ettirir
  ///
  /// Optimistic update pattern kullanır.
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
    // İş emrini cache'de bul
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) {
      _setError('İş bulunamadı');
      return;
    }

    final job = _jobs[index];

    // Optimistic update - önce UI'ı güncelle
    final updatedTasks = job.tasks.map((task) {
      if (task.id != taskId) return task; // Bu görev değilse değiştirme
      if (task.status != JobTaskStatus.paused)
        return task; // Sadece duraklatılmış görevler devam ettirilebilir

      // Görevi devam ediyor olarak işaretle
      return task.copyWith(
        status: JobTaskStatus.inProgress,
        startedAt: DateTime.now(), // Yeni oturum başlangıcı
        assignedWorkerId: assignedWorkerId,
      );
    }).toList();

    // Cache'i güncelle
    _jobs[index] = job.copyWith(tasks: updatedTasks);
    notifyListeners();

    try {
      // Backend'e görevi devam ettirme isteği gönder
      await _jobsApiService.resumeTask(
        jobId: jobId,
        taskId: taskId,
        assignedWorkerId: assignedWorkerId,
      );
      // Backend'den güncel veriyi al
      await _refreshJob(jobId);
    } catch (e) {
      // Hata olursa geri al (rollback)
      _jobs[index] = job;
      notifyListeners();
      _setError('Görev devam ettirilirken hata oluştu: ${e.toString()}');
    }
  }

  /// Görevi günceller
  ///
  /// Engelleme nedenini günceller.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - blockingReason: Engelleme nedeni (opsiyonel, null ise temizlenir)
  Future<void> updateTask({
    required String jobId,
    required String taskId,
    TaskBlockingReason? blockingReason,
    bool? isTaskAvailable,
  }) async {
    // İş emrini cache'de bul
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) {
      _setError('İş bulunamadı');
      return;
    }

    final job = _jobs[index];

    // Optimistic update - önce UI'ı güncelle
    final updatedTasks = job.tasks.map((task) {
      if (task.id != taskId) return task; // Bu görev değilse değiştirme

      return task.copyWith(
        blockingReason: blockingReason,
        isTaskAvailable: isTaskAvailable,
      );
    }).toList();

    // Cache'i güncelle
    _jobs[index] = job.copyWith(tasks: updatedTasks);
    notifyListeners();

    try {
      // Backend'e görevi güncelleme isteği gönder
      await _jobsApiService.updateTask(
        jobId: jobId,
        taskId: taskId,
        blockingReason: blockingReason,
        updateBlockingReason: true,
        isTaskAvailable: isTaskAvailable,
      );
      // Backend'den güncel veriyi al
      await _refreshJob(jobId);
    } catch (e) {
      // Hata olursa geri al (rollback)
      _jobs[index] = job;
      notifyListeners();
      _setError('Görev güncellenirken hata oluştu: ${e.toString()}');
    }
  }

  /// Yedek parça bilgilerini günceller
  Future<void> updateSparePart({
    required String jobId,
    required String taskId,
    required String partName,
    String? newName,
    PartSupplySource? supplySource,
    int? quantity,
    PartSupplyStatus? status,
    String? partCode,
    String? notes,
  }) async {
    // İş emrini cache'de bul
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) {
      _setError('İş bulunamadı');
      return;
    }

    final job = _jobs[index];
    final taskIndex = job.tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) {
      _setError('Görev bulunamadı');
      return;
    }

    // Optimistic update - önce UI'ı güncelle
    final updatedTasks = List<JobTask>.from(job.tasks);
    final task = updatedTasks[taskIndex];

    final updatedParts = task.spareParts.map((part) {
      if (part.name != partName) return part;

      return part.copyWith(
        name: newName,
        supplySource: supplySource,
        quantity: quantity,
        status: status,
        partCode: partCode,
        notes: notes,
      );
    }).toList();

    updatedTasks[taskIndex] = task.copyWith(spareParts: updatedParts);
    _jobs[index] = job.copyWith(tasks: updatedTasks);
    notifyListeners();

    try {
      // Backend'e güncel yedek parça listesini gönder
      await _jobsApiService.updateTask(
        jobId: jobId,
        taskId: taskId,
        spareParts: updatedParts,
      );
      // Backend'den güncel veriyi al
      await _refreshJob(jobId);
    } catch (e) {
      // Hata olursa geri al (rollback)
      _jobs[index] = job;
      notifyListeners();
      _setError('Yedek parça güncellenirken hata oluştu: ${e.toString()}');
    }
  }

  /// İş emrinin araç durumunu günceller
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - isVehicleAvailable: Arabanın üzerinde çalışılabilir mi
  Future<void> updateJobVehicleAvailability({
    required String jobId,
    required bool isVehicleAvailable,
  }) async {
    // İş emrini cache'de bul
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) {
      _setError('İş bulunamadı');
      return;
    }

    final job = _jobs[index];

    // Optimistic update - önce UI'ı güncelle
    _jobs[index] = job.copyWith(isVehicleAvailable: isVehicleAvailable);
    notifyListeners();

    try {
      // Backend'e iş emrini güncelleme isteği gönder
      await _jobsApiService.updateJobVehicleAvailability(
        jobId: jobId,
        isVehicleAvailable: isVehicleAvailable,
      );
      // Backend'den güncel veriyi al
      await _refreshJob(jobId);
    } catch (e) {
      // Hata olursa geri al (rollback)
      _jobs[index] = job;
      notifyListeners();
      _setError('Araç durumu güncellenirken hata oluştu: ${e.toString()}');
    }
  }

  /// İş emrinin araç aşamasını günceller
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - vehicleStage: Araç aşaması (none, insurance_approval_waiting, expert_waiting, part_waiting)
  Future<void> updateJobVehicleStage({
    required String jobId,
    required String? vehicleStage,
  }) async {
    // İş emrini cache'de bul
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) {
      _setError('İş bulunamadı');
      return;
    }

    final job = _jobs[index];

    // Optimistic update - önce UI'ı güncelle
    _jobs[index] = job.copyWith(vehicleStage: vehicleStage);
    notifyListeners();

    try {
      // Backend'e iş emrini güncelleme isteği gönder
      await _jobsApiService.updateJobVehicleStage(
        jobId: jobId,
        vehicleStage: vehicleStage,
      );
      // Backend'den güncel veriyi al
      await _refreshJob(jobId);
    } catch (e) {
      // Hata olursa geri al (rollback)
      _jobs[index] = job;
      notifyListeners();
      _setError('Araç aşaması güncellenirken hata oluştu: ${e.toString()}');
    }
  }

  /// Görevi tamamlar
  ///
  /// Optimistic update pattern kullanır.
  /// Tamamlanma fotoğrafı ve not eklenebilir.
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
    // İş emrini cache'de bul
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) {
      _setError('İş bulunamadı');
      return;
    }

    final job = _jobs[index];

    // Optimistic update - önce UI'ı güncelle
    final updatedTasks = job.tasks.map((task) {
      if (task.id != taskId) return task; // Bu görev değilse değiştirme
      if (task.status == JobTaskStatus.completed)
        return task; // Zaten tamamlanmışsa değiştirme

      final photos = List<TaskPhoto>.from(task.photos);
      // Fotoğraf API yanıtından eklenecek (şimdilik ekleme)

      // Görevi tamamlanmış olarak işaretle
      return task.copyWith(
        status: JobTaskStatus.completed,
        completedAt: DateTime.now(),
        note: note ?? task.note,
        photos: photos,
      );
    }).toList();

    // Cache'i güncelle
    _jobs[index] = job.copyWith(tasks: updatedTasks);
    notifyListeners();

    try {
      // Backend'e görevi tamamlama isteği gönder
      await _jobsApiService.completeTask(
        jobId: jobId,
        taskId: taskId,
        note: note,
        completionPhotoPath: completionPhotoPath,
      );
      // Backend'den güncel veriyi al
      await _refreshJob(jobId);
    } catch (e) {
      // Hata olursa geri al (rollback)
      _jobs[index] = job;
      notifyListeners();
      _setError('Görev tamamlanırken hata oluştu: ${e.toString()}');
    }
  }

  /// Göreve fotoğraf yükler
  ///
  /// Fotoğrafı backend'e upload eder ve göreve ekler.
  /// Upload sonrası iş emrini backend'den yeniler (tam metadata için).
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - photoPath: Fotoğraf dosya yolu
  /// - type: Fotoğraf tipi (varsayılan: hasar fotoğrafı)
  Future<void> addDamagePhoto({
    required String jobId,
    required String taskId,
    required String photoPath,
    TaskPhotoType type = TaskPhotoType.damage,
    JobStatus? stage,
  }) async {
    // İş emrini cache'de bul
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) {
      throw Exception('İş bulunamadı');
    }

    try {
      _setLoading(true);
      _setError(null);

      debugPrint(
        '📸 Uploading photo: jobId=$jobId, taskId=$taskId, type=$type, path=$photoPath',
      );

      // Fotoğrafı backend'e upload et
      final photo = await _jobsApiService.uploadPhoto(
        jobId: jobId,
        taskId: taskId,
        filePath: photoPath,
        type: type,
        stage: stage,
      );

      debugPrint('📸 Photo uploaded: id=${photo.id}, path=${photo.path}');

      // İş emrini backend'den yenile (tam metadata için)
      // Bu sayede doğru fotoğraf ID'si ve tüm backend alanları alınır
      try {
        debugPrint('📸 Refreshing job from API...');
        final updatedJob = await _jobsApiService.getJobById(jobId);

        // Debug: Güncellenmiş iş emrindeki fotoğrafları kontrol et
        final task = updatedJob.tasks.firstWhere(
          (t) => t.id == taskId,
          orElse: () => throw Exception('Task not found in updated job'),
        );
        debugPrint('📸 Updated task has ${task.photos.length} photos');
        for (final p in task.photos) {
          debugPrint(
            '📸 Photo in task: id=${p.id}, path=${p.path}, type=${p.type}',
          );
        }

        // Cache'i güncelle
        _jobs[index] = updatedJob;
        debugPrint('📸 Job refreshed successfully');
      } catch (e) {
        debugPrint('⚠️ Job refresh failed: $e, using optimistic update');
        // Refresh başarısız olursa optimistic update kullan
        final job = _jobs[index];
        final updatedTasks = job.tasks.map((task) {
          if (task.id != taskId) return task;
          // Fotoğrafı listeye ekle
          final photos = List<TaskPhoto>.from(task.photos)..add(photo);
          debugPrint(
            '📸 Optimistic update: task now has ${photos.length} photos',
          );
          return task.copyWith(photos: photos);
        }).toList();
        _jobs[index] = job.copyWith(tasks: updatedTasks);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Photo upload error: $e');
      _setError('Fotoğraf yüklenirken hata oluştu: ${e.toString()}');
      rethrow; // UI'ın hata yönetimi yapabilmesi için tekrar fırlat
    } finally {
      _setLoading(false);
    }
  }

  /// Görev notunu günceller (sadece local, API endpoint yok)
  ///
  /// Not: Bu metod sadece local cache'i günceller.
  /// Backend'e kaydedilmez. Gelecekte API endpoint eklendiğinde
  /// backend'e de kaydedilebilir.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  /// - note: Yeni not
  Future<void> updateTaskNote({
    required String jobId,
    required String taskId,
    required String note,
  }) async {
    await upsertJobNote(jobId: jobId, taskId: taskId, content: note);
  }

  /// Genel notları günceller
  ///
  /// İş emrinin genel notlarını backend'e kaydeder.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - notes: Yeni genel notlar
  Future<void> updateGeneralNotes({
    required String jobId,
    required String notes,
  }) async {
    await upsertJobNote(jobId: jobId, content: notes);
  }

  /// İş emrine görev ekler
  ///
  /// Backend'e görev ekler ve cache'i günceller.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - task: Eklenecek görev
  Future<void> addTaskToJob({
    required String jobId,
    required JobTask task,
    String? partName,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      // Backend'e görev ekle
      final updatedJob = await _jobsApiService.addTaskToJob(
        jobId: jobId,
        area: task.area,
        operationType: task.operationType,
        note: task.note,
        partName: partName,
      );

      // Cache'i güncelle
      final index = _jobs.indexWhere((job) => job.id == jobId);
      if (index != -1) {
        _jobs[index] = updatedJob;
      } else {
        _jobs.add(updatedJob);
      }
      notifyListeners();
    } catch (e) {
      _setError('Görev eklenirken hata oluştu: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Durum sayılarını hesaplar
  ///
  /// Her durumdaki iş emri sayısını döndürür.
  /// Dashboard'da istatistik göstermek için kullanılır.
  ///
  /// Döner: Map<JobStatus, int> - Durum -> sayı mapping'i
  Map<JobStatus, int> get statusCounts {
    // Tüm durumlar için 0 ile başlat
    final Map<JobStatus, int> counts = {
      for (final status in JobStatus.values) status: 0,
    };

    // Her iş emrinin durumunu say
    for (final job in _jobs) {
      counts[job.status] = (counts[job.status] ?? 0) + 1;
    }

    return counts;
  }

  /// Tek bir iş emrini API'den yeniler (private metod)
  ///
  /// Diğer metodlar tarafından kullanılır.
  /// Hata durumunda sessizce başarısız olur (hata zaten gösterilmiş).
  Future<void> _refreshJob(String jobId) async {
    try {
      final job = await _jobsApiService.getJobById(jobId);
      final index = _jobs.indexWhere((job) => job.id == jobId);
      if (index != -1) {
        _jobs[index] = job;
        if (_jobNotes.containsKey(jobId)) {
          _applyNotesToJob(jobId, _jobNotes[jobId]!);
        }
        notifyListeners();
      }
    } catch (e) {
      // Sessizce başarısız ol (hata zaten gösterilmiş)
    }
  }

  void _applyNotesToJob(String jobId, List<JobNote> notes) {
    final index = _jobs.indexWhere((job) => job.id == jobId);
    if (index == -1) return;
    final job = _jobs[index];
    String? generalNotes = job.generalNotes;
    final updatedTasks = job.tasks.map((task) {
      final note = _findNote(notes, (element) => element.taskId == task.id);
      if (note != null) {
        return task.copyWith(note: note.content);
      }
      return task;
    }).toList();

    final generalNote = _findNote(notes, (note) => note.taskId == null);
    if (generalNote != null) {
      generalNotes = generalNote.content;
    }

    _jobs[index] = job.copyWith(
      tasks: updatedTasks,
      generalNotes: generalNotes,
    );
  }

  JobNote? _findNote(
    List<JobNote> notes,
    bool Function(JobNote note) predicate,
  ) {
    for (final note in notes) {
      if (predicate(note)) return note;
    }
    return null;
  }

  /// Yükleme durumunu ayarlar (private metod)
  ///
  /// State değişikliğini dinleyicilere bildirir.
  void _setLoading(bool value) {
    if (_isLoading == value) return; // Değişiklik yoksa bildirme
    _isLoading = value;
    notifyListeners();
  }

  /// Hata mesajını ayarlar (private metod)
  ///
  /// State değişikliğini dinleyicilere bildirir.
  void _setError(String? message) {
    if (_errorMessage == message) return; // Değişiklik yoksa bildirme
    _errorMessage = message;
    notifyListeners();
  }

  /// Personelin kendi görevlerini yükler
  ///
  /// Backend'den mevcut kullanıcıya atanmış görevleri çeker.
  ///
  /// Parametreler:
  /// - statusFilter: Görev durumu filtresi (pending, in_progress, completed)
  Future<void> loadMyTasks({String? statusFilter}) async {
    _setLoading(true);
    _setError(null);

    try {
      final jobs = await _jobsApiService.getMyTasks(statusFilter: statusFilter);
      _myTasks.clear();
      _myTasks.addAll(jobs);
      notifyListeners();
    } catch (e) {
      _setError('Görevler yüklenirken hata oluştu: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Müsait görevleri yükler
  ///
  /// Backend'den henüz atanmamış görevleri çeker.
  /// Araç üzerinde çalışılamaz durumda olan iş emirleri filtrelenir.
  Future<void> loadAvailableTasks() async {
    _setLoading(true);
    _setError(null);

    try {
      final jobs = await _jobsApiService.getAvailableTasks();
      _availableTasks.clear();
      // Ek güvenlik kontrolü: Araç üzerinde çalışılamaz iş emirlerini filtrele
      _availableTasks.addAll(jobs.where((job) => job.isVehicleAvailable));
      notifyListeners();
    } catch (e) {
      _setError('Müsait görevler yüklenirken hata oluştu: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Görevi mevcut kullanıcıya atar
  ///
  /// Personel, müsait bir görevi kendisine atayabilir.
  ///
  /// Parametreler:
  /// - jobId: İş emri ID'si
  /// - taskId: Görev ID'si
  Future<void> assignTask({
    required String jobId,
    required String taskId,
  }) async {
    try {
      await _jobsApiService.assignTask(jobId: jobId, taskId: taskId);

      // Müsait görevler listesini yenile
      await loadAvailableTasks();

      // Kendi görevlerimi de yenile
      await loadMyTasks();

      // Ana iş emirleri listesini de yenile (görev atandığı için)
      await _refreshJob(jobId);
    } catch (e) {
      _setError('Görev atama başarısız: ${e.toString()}');
      rethrow;
    }
  }

  /// Tüm atanmış görevleri yükler (supervisor için)
  ///
  /// Hangi personele atanmış olursa olsun tüm atanmış görevleri çeker.
  Future<void> loadAllAssignedTasks() async {
    _setLoading(true);
    _setError(null);

    try {
      final jobs = await _jobsApiService.getAllAssignedTasks();
      _allAssignedTasks.clear();
      _allAssignedTasks.addAll(jobs);
      notifyListeners();
    } catch (e) {
      _setError('Atanmış görevler yüklenirken hata oluştu: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Bekleyen görevleri yükler (supervisor için)
  ///
  /// Henüz başlanmamış (pending) görevleri çeker.
  Future<void> loadPendingTasks() async {
    _setLoading(true);
    _setError(null);

    try {
      final jobs = await _jobsApiService.getPendingTasks();
      _pendingTasks.clear();
      _pendingTasks.addAll(jobs);
      notifyListeners();
    } catch (e) {
      _setError('Bekleyen görevler yüklenirken hata oluştu: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> ensureJobNotesLoaded(String jobId) async {
    if (_jobNotes.containsKey(jobId)) return;
    await loadJobNotes(jobId: jobId);
  }

  Future<void> loadJobNotes({required String jobId, bool force = false}) async {
    if (!force && _jobNotes.containsKey(jobId)) return;
    try {
      final notes = await _jobsApiService.getJobNotes(jobId);
      _jobNotes[jobId] = notes;
      _applyNotesToJob(jobId, notes);
      notifyListeners();
    } catch (e) {
      _setError('Notlar yüklenirken hata oluştu: ${e.toString()}');
    }
  }

  Future<JobNote> upsertJobNote({
    required String jobId,
    String? taskId,
    required String content,
  }) async {
    final normalizedContent = content.trim();
    try {
      final note = await _jobsApiService.upsertJobNote(
        jobId: jobId,
        taskId: taskId,
        content: normalizedContent,
      );
      final current = List<JobNote>.from(_jobNotes[jobId] ?? const []);
      final index = current.indexWhere((item) => item.taskId == note.taskId);
      if (index >= 0) {
        current[index] = note;
      } else {
        current.add(note);
      }
      _jobNotes[jobId] = current;
      _applyNotesToJob(jobId, current);
      notifyListeners();
      return note;
    } catch (e) {
      _setError('Not kaydedilirken hata oluştu: ${e.toString()}');
      rethrow;
    }
  }

  /// Get available workers for kiosk mode auto-assignment
  Future<List<Map<String, dynamic>>> getAvailableWorkers() async {
    try {
      final response = await _jobsApiService.getAvailableWorkers();
      return response;
    } catch (e) {
      _setError('Usta listesi alınırken hata oluştu: ${e.toString()}');
      rethrow;
    }
  }
}
