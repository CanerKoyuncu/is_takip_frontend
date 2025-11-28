/// İş Emri Modelleri
///
/// Bu dosya, iş emirleri ile ilgili tüm veri modellerini içerir.
/// Enum'lar, extension'lar ve sınıflar burada tanımlanır.
///
/// İçerik:
/// - JobStatus: İş emrinin genel durumu
/// - JobTaskStatus: Görevin durumu
/// - JobOperationType: Yapılacak işlem tipi
/// - TaskPhotoType: Fotoğraf tipi
/// - VehicleInfo: Araç bilgileri
/// - TaskPhoto: Görev fotoğrafı
/// - JobTask: İş emri görevi
/// - JobOrder: İş emri (ana model)

import 'package:flutter/material.dart';

import 'vehicle_area.dart';

/// İş emri durumu enum'ı
///
/// İş emrinin hangi aşamada olduğunu belirtir.
/// Durum, görevlerin durumuna göre otomatik hesaplanır.
enum JobStatus {
  /// Hazırlık aşaması - henüz işlem başlamamış
  hazirlik,

  /// Kaporta işlemleri devam ediyor
  kaporta,

  /// Boya işlemleri devam ediyor
  boya,

  /// Tüm işlemler tamamlandı
  tamamlandi,
}

/// JobStatus extension'ı
///
/// İş emri durumuna göre label ve renk bilgilerini sağlar.
extension JobStatusX on JobStatus {
  /// Durumun Türkçe etiketi
  String get label {
    switch (this) {
      case JobStatus.hazirlik:
        return 'Hazırlık';
      case JobStatus.kaporta:
        return 'Kaporta';
      case JobStatus.boya:
        return 'Boya';
      case JobStatus.tamamlandi:
        return 'Tamamlandı';
    }
  }

  /// Durumun arka plan rengi
  Color toColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case JobStatus.hazirlik:
        return scheme.secondaryContainer;
      case JobStatus.kaporta:
        return scheme.tertiaryContainer;
      case JobStatus.boya:
        return scheme.primaryContainer;
      case JobStatus.tamamlandi:
        return scheme.surfaceTint;
    }
  }

  /// Durumun metin rengi (arka plan rengi üzerinde okunabilirlik için)
  Color onColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case JobStatus.hazirlik:
        return scheme.onSecondaryContainer;
      case JobStatus.kaporta:
        return scheme.onTertiaryContainer;
      case JobStatus.boya:
        return scheme.onPrimaryContainer;
      case JobStatus.tamamlandi:
        return scheme.onSurfaceVariant;
    }
  }
}

/// Görev durumu enum'ı
///
/// Bir görevin hangi aşamada olduğunu belirtir.
enum JobTaskStatus {
  /// Beklemede - henüz başlamamış
  pending,

  /// Devam ediyor - işlem sürüyor
  inProgress,

  /// Duraklatıldı - geçici olarak durdurulmuş
  paused,

  /// Tamamlandı - işlem bitmiş
  completed,
}

/// Görev engelleme nedeni enum'ı
///
/// Görevin neden bekletildiğini belirtir.
enum TaskBlockingReason {
  /// Parça bekleniyor
  partWaiting,

  /// Eksper bekleniyor
  expertWaiting,

  /// Tedarik aşamasında
  supplyStage,
}

/// TaskBlockingReason extension'ı
extension TaskBlockingReasonX on TaskBlockingReason {
  /// Engelleme nedeninin Türkçe etiketi
  String get label {
    switch (this) {
      case TaskBlockingReason.partWaiting:
        return 'Parça Bekleniyor';
      case TaskBlockingReason.expertWaiting:
        return 'Eksper Bekleniyor';
      case TaskBlockingReason.supplyStage:
        return 'Tedarik Aşamasında';
    }
  }

  /// Engelleme nedeninin ikonu
  IconData get icon {
    switch (this) {
      case TaskBlockingReason.partWaiting:
        return Icons.inventory_2_outlined;
      case TaskBlockingReason.expertWaiting:
        return Icons.person_search_outlined;
      case TaskBlockingReason.supplyStage:
        return Icons.local_shipping_outlined;
    }
  }
}

/// JobTaskStatus extension'ı
///
/// Görev durumuna göre label ve renk bilgilerini sağlar.
extension JobTaskStatusX on JobTaskStatus {
  /// Durumun Türkçe etiketi
  String get label {
    switch (this) {
      case JobTaskStatus.pending:
        return 'Beklemede';
      case JobTaskStatus.inProgress:
        return 'Devam Ediyor';
      case JobTaskStatus.paused:
        return 'Duraklatıldı';
      case JobTaskStatus.completed:
        return 'Tamamlandı';
    }
  }

  /// Durumun arka plan rengi
  Color toColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case JobTaskStatus.pending:
        return scheme.surfaceContainerHighest;
      case JobTaskStatus.inProgress:
        return scheme.primaryContainer;
      case JobTaskStatus.paused:
        return scheme.tertiaryContainer;
      case JobTaskStatus.completed:
        return scheme.secondaryContainer;
    }
  }

  /// Durumun metin rengi
  Color onColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case JobTaskStatus.pending:
        return scheme.onSurfaceVariant;
      case JobTaskStatus.inProgress:
        return scheme.onPrimaryContainer;
      case JobTaskStatus.paused:
        return scheme.onTertiaryContainer;
      case JobTaskStatus.completed:
        return scheme.onSecondaryContainer;
    }
  }
}

/// Görev kategorisi enum'ı
///
/// Görevlerin hangi ana kategori altında olduğunu belirtir.
enum TaskCategory {
  /// Kaporta kategorisi
  kaporta,

  /// Boya kategorisi
  boya,
}

/// TaskCategory extension'ı
///
/// Kategoriye göre label ve renk bilgilerini sağlar.
extension TaskCategoryX on TaskCategory {
  /// Kategorinin Türkçe etiketi
  String get label {
    switch (this) {
      case TaskCategory.kaporta:
        return 'Kaporta';
      case TaskCategory.boya:
        return 'BOYA';
    }
  }

  /// Kategorinin ikonu
  IconData get icon {
    switch (this) {
      case TaskCategory.kaporta:
        return Icons.handyman_outlined;
      case TaskCategory.boya:
        return Icons.format_paint_outlined;
    }
  }
}

/// İşlem tipi enum'ı
///
/// Görevde yapılacak işlem tipini belirtir.
/// Her işlem tipi bir kategoriye aittir.
enum JobOperationType {
  // Kaporta kategorisi işlemleri
  change,

  /// Sök - Tak
  sokTak,

  /// Onarım
  onarim,

  /// Döşeme
  doseme,

  /// Parça Kurtarma
  parcaKurtarma,

  /// Boyasız Onarım
  boyasizOnarim,

  // BOYA kategorisi işlemleri
  /// Yeni Boya
  yeniBoya,

  /// Onarım Boya
  onarimBoya,

  /// Lokal Boya
  lokalBoya,

  /// Pasta
  pasta,
}

/// JobOperationType extension'ı
///
/// İşlem tipine göre label, ikon ve kategori bilgilerini sağlar.
extension JobOperationTypeX on JobOperationType {
  /// İşlem tipinin Türkçe etiketi
  String get label {
    switch (this) {
      // Kaporta kategorisi
      case JobOperationType.change:
        return 'Değişim';
      case JobOperationType.sokTak:
        return 'Sök - Tak';
      case JobOperationType.onarim:
        return 'Onarım';
      case JobOperationType.doseme:
        return 'Döşeme';
      case JobOperationType.parcaKurtarma:
        return 'Parça Kurtarma';
      case JobOperationType.boyasizOnarim:
        return 'Boyasız Onarım';
      // BOYA kategorisi
      case JobOperationType.yeniBoya:
        return 'Yeni Boya';
      case JobOperationType.onarimBoya:
        return 'Onarım Boya';
      case JobOperationType.lokalBoya:
        return 'Lokal Boya';
      case JobOperationType.pasta:
        return 'Pasta';
    }
  }

  /// İşlem tipinin ikonu
  IconData get icon {
    switch (this) {
      case JobOperationType.change:
        return Icons.swap_horiz_outlined;
      // Kaporta kategorisi
      case JobOperationType.sokTak:
        return Icons.swap_horiz_outlined;
      case JobOperationType.onarim:
        return Icons.build_outlined;
      case JobOperationType.doseme:
        return Icons.chair_outlined;
      case JobOperationType.parcaKurtarma:
        return Icons.inventory_2_outlined;
      case JobOperationType.boyasizOnarim:
        return Icons.auto_fix_high_outlined;
      // BOYA kategorisi
      case JobOperationType.yeniBoya:
        return Icons.format_paint_outlined;
      case JobOperationType.onarimBoya:
        return Icons.brush_outlined;
      case JobOperationType.lokalBoya:
        return Icons.auto_awesome_outlined;
      case JobOperationType.pasta:
        return Icons.cleaning_services_outlined;
    }
  }

  /// İşlem tipinin ait olduğu kategori
  TaskCategory get category {
    switch (this) {
      case JobOperationType.change:
      case JobOperationType.sokTak:
      case JobOperationType.onarim:
      case JobOperationType.doseme:
      case JobOperationType.parcaKurtarma:
      case JobOperationType.boyasizOnarim:
        return TaskCategory.kaporta;
      case JobOperationType.yeniBoya:
      case JobOperationType.onarimBoya:
      case JobOperationType.lokalBoya:
      case JobOperationType.pasta:
        return TaskCategory.boya;
    }
  }
}

/// Görev fotoğrafı tipi enum'ı
///
/// Fotoğrafın ne amaçla çekildiğini belirtir.
enum TaskPhotoType {
  damage,

  /// Onarım fotoğrafı - işlem öncesi hasar durumu
  onRepair,

  /// Boya fotoğrafı - işlem sonrası durum
  onPaint,

  /// Temizleme fotoğrafı - işlem sonrası durum
  onClean,

  /// Tamamlanma fotoğrafı - işlem sonrası durum
  completion,
}

/// TaskPhotoType extension'ı
///
/// Fotoğraf tipine göre Türkçe etiket sağlar.
extension TaskPhotoTypeX on TaskPhotoType {
  /// Fotoğraf tipinin Türkçe etiketi
  String get label {
    switch (this) {
      case TaskPhotoType.damage:
        return 'Hasar Fotoğrafı';
      case TaskPhotoType.onRepair:
        return 'Onarım Fotoğrafı';
      case TaskPhotoType.onPaint:
        return 'Boya Fotoğrafı';
      case TaskPhotoType.onClean:
        return 'Temizleme Fotoğrafı';
      case TaskPhotoType.completion:
        return 'Tamamlandı Fotoğrafı';
    }
  }
}

/// Araç bilgileri sınıfı
///
/// İş emrindeki aracın bilgilerini tutar.
class VehicleInfo {
  const VehicleInfo({
    required this.plate, // Plaka numarası
    required this.brand, // Marka
    required this.model, // Model
  });

  final String plate;
  final String brand;
  final String model;
}

/// Görev fotoğrafı sınıfı
///
/// Bir göreve ait fotoğraf bilgilerini tutar.
class TaskPhoto {
  const TaskPhoto({
    required this.id, // Fotoğraf ID'si
    required this.path, // Fotoğraf yolu (backend'deki path)
    required this.type, // Fotoğraf tipi
    required this.createdAt, // Oluşturulma zamanı
    this.stage, // Fotoğrafın hangi aşamada yüklendiği
  });

  final String id;
  final String path;
  final TaskPhotoType type;
  final DateTime createdAt;
  final JobStatus? stage; // Fotoğrafın hangi aşamada yüklendiği (opsiyonel)

  /// Fotoğraf bilgilerini kopyalar ve günceller
  ///
  /// Immutable pattern - yeni bir instance oluşturur.
  TaskPhoto copyWith({
    String? path,
    TaskPhotoType? type,
    DateTime? createdAt,
    JobStatus? stage,
  }) {
    return TaskPhoto(
      id: id,
      path: path ?? this.path,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      stage: stage ?? this.stage,
    );
  }
}

/// Görev çalışma oturumu sınıfı
///
/// Bir görevde bir işçinin çalışma oturumunu temsil eder.
class TaskWorkSession {
  const TaskWorkSession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.workerId,
    this.workerName,
    this.durationSeconds,
  });

  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String? workerId;
  final String? workerName;
  final double? durationSeconds;

  /// Süreyi saniye cinsinden hesaplar
  double get durationInSeconds {
    if (durationSeconds != null) {
      return durationSeconds!;
    }
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inSeconds.toDouble();
  }

  /// Süreyi dakika cinsinden hesaplar
  double get durationInMinutes => durationInSeconds / 60;

  /// Süreyi saat cinsinden hesaplar
  double get durationInHours => durationInMinutes / 60;
}

/// İş emri görevi sınıfı
///
/// Bir iş emrindeki tek bir görevi temsil eder.
/// Her görev bir araç parçası üzerinde yapılacak bir işlemi belirtir.
class JobTask {
  JobTask({
    required this.id, // Görev ID'si
    required this.area, // Araç parçası (hangi bölgede)
    required this.operationType, // İşlem tipi (ne yapılacak)
    this.note, // Notlar
    this.status = JobTaskStatus.pending, // Durum (varsayılan: beklemede)
    this.startedAt, // Başlangıç zamanı
    this.completedAt, // Tamamlanma zamanı
    this.assignedWorkerId, // Atanan işçi ID'si (gelecekte kullanılabilir)
    this.assignedWorkerName, // Atanan işçi adı
    this.blockingReason, // Engelleme nedeni (parça bekleniyor, eksper bekleniyor, vb.)
    this.isTaskAvailable = true, // Görev üzerinde çalışılabilir mi
    List<TaskPhoto> photos = const <TaskPhoto>[], // Fotoğraflar
    List<TaskWorkSession> workSessions =
        const <TaskWorkSession>[], // Çalışma oturumları
  }) : photos = List<TaskPhoto>.unmodifiable(photos),
       workSessions = List<TaskWorkSession>.unmodifiable(
         workSessions,
       ); // Immutable liste

  final String id;
  final VehicleArea area;
  final JobOperationType operationType;
  final String? note;
  final JobTaskStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? assignedWorkerId;
  final String? assignedWorkerName;
  final TaskBlockingReason? blockingReason;
  final bool isTaskAvailable;
  final List<TaskPhoto> photos;
  final List<TaskWorkSession> workSessions;

  /// Toplam çalışma süresini saat cinsinden hesaplar
  double get totalWorkHours {
    double total = 0;
    for (final session in workSessions) {
      total += session.durationInHours;
    }
    return total;
  }

  /// Görevde çalışan tüm işçileri ve sürelerini döndürür
  Map<String, double> get workerHours {
    final Map<String, double> hours = {};
    for (final session in workSessions) {
      final workerName = session.workerName ?? session.workerId ?? 'Bilinmeyen';
      hours[workerName] = (hours[workerName] ?? 0) + session.durationInHours;
    }
    return hours;
  }

  /// Görev bilgilerini kopyalar ve günceller
  ///
  /// Immutable pattern - yeni bir instance oluşturur.
  JobTask copyWith({
    VehicleArea? area,
    JobOperationType? operationType,
    String? note,
    JobTaskStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? assignedWorkerId,
    String? assignedWorkerName,
    TaskBlockingReason? blockingReason,
    bool? isTaskAvailable,
    List<TaskPhoto>? photos,
    List<TaskWorkSession>? workSessions,
  }) {
    return JobTask(
      id: id,
      area: area ?? this.area,
      operationType: operationType ?? this.operationType,
      note: note ?? this.note,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      assignedWorkerName: assignedWorkerName ?? this.assignedWorkerName,
      blockingReason: blockingReason ?? this.blockingReason,
      isTaskAvailable: isTaskAvailable ?? this.isTaskAvailable,
      photos: photos ?? this.photos,
      workSessions: workSessions ?? this.workSessions,
    );
  }
}

/// İş emri sınıfı (ana model)
///
/// Bir iş emrini temsil eder. Araç ve görev bilgilerini içerir.
/// İş emrinin durumu, görevlerin durumuna göre otomatik hesaplanır.
class JobOrder {
  JobOrder({
    required this.id, // İş emri ID'si
    required this.vehicle, // Araç bilgileri
    required List<JobTask> tasks, // Görevler listesi
    required this.createdAt, // Oluşturulma zamanı
    this.generalNotes, // Genel notlar
    this.isVehicleAvailable = true, // Arabanın üzerinde çalışılabilir mi
    this.vehicleStage, // Araç aşaması (sigorta onayı, eksper, parça bekleniyor vb.)
  }) : _tasks = List<JobTask>.unmodifiable(tasks); // Immutable liste

  final String id;
  final VehicleInfo vehicle;

  final DateTime createdAt;
  final String? generalNotes;
  final bool isVehicleAvailable;
  final String?
  vehicleStage; // none, insurance_approval_waiting, expert_waiting, part_waiting
  // Private tasks listesi - immutable getter ile erişilir
  final List<JobTask> _tasks;

  /// Görevler listesi (immutable)
  List<JobTask> get tasks => List<JobTask>.unmodifiable(_tasks);

  /// İş emrinin durumunu hesaplar
  ///
  /// Görevlerin durumuna göre otomatik olarak iş emrinin
  /// genel durumunu belirler.
  ///
  /// Mantık:
  /// - Tüm görevler tamamlandıysa -> Tamamlandı
  /// - Boya işlemi devam ediyorsa -> Boya
  /// - Kaporta işlemi devam ediyorsa -> Kaporta
  /// - Diğer durumlarda -> Hazırlık
  JobStatus get status {
    // Görev yoksa hazırlık aşamasında
    if (_tasks.isEmpty) {
      return JobStatus.hazirlik;
    }

    // Devam eden kaporta işlemi var mı?
    final hasInProgressKaporta = _tasks.any(
      (task) =>
          task.status == JobTaskStatus.inProgress &&
          task.operationType.category == TaskCategory.kaporta,
    );

    // Devam eden boya işlemi var mı?
    final hasInProgressPaint = _tasks.any(
      (task) =>
          task.status == JobTaskStatus.inProgress &&
          task.operationType.category == TaskCategory.boya,
    );

    // Tüm görevler tamamlandıysa
    if (_tasks.every((task) => task.status == JobTaskStatus.completed)) {
      return JobStatus.tamamlandi;
    }

    // Boya işlemi öncelikli (kaporta'dan sonra gelir)
    if (hasInProgressPaint) {
      return JobStatus.boya;
    }

    // Kaporta işlemi devam ediyorsa
    if (hasInProgressKaporta) {
      return JobStatus.kaporta;
    }

    // Diğer durumlarda hazırlık
    return JobStatus.hazirlik;
  }

  /// İş emri bilgilerini kopyalar ve günceller
  ///
  /// Immutable pattern - yeni bir instance oluşturur.
  JobOrder copyWith({
    VehicleInfo? vehicle,
    List<JobTask>? tasks,
    DateTime? createdAt,
    String? generalNotes,
    bool? isVehicleAvailable,
    String? vehicleStage,
  }) {
    return JobOrder(
      id: id,
      vehicle: vehicle ?? this.vehicle,
      tasks: tasks ?? _tasks,
      createdAt: createdAt ?? this.createdAt,
      generalNotes: generalNotes ?? this.generalNotes,
      isVehicleAvailable: isVehicleAvailable ?? this.isVehicleAvailable,
      vehicleStage: vehicleStage ?? this.vehicleStage,
    );
  }
}

class JobNote {
  const JobNote({
    required this.id,
    required this.jobId,
    this.taskId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String jobId;
  final String? taskId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory JobNote.fromJson(Map<String, dynamic> json) {
    return JobNote(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      taskId: json['taskId'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  JobNote copyWith({String? content, DateTime? updatedAt}) {
    return JobNote(
      id: id,
      jobId: jobId,
      taskId: taskId,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
