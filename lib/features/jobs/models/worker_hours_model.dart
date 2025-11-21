/// Worker Hours Rapor Modelleri
///
/// İşçi mesai saatleri raporu için kullanılan modeller.

import '../models/job_models.dart';

/// Çalışma oturumu (başlangıç ve bitiş zamanı)
class WorkSession {
  WorkSession({
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    this.workerId,
  });

  final DateTime startTime;
  final DateTime endTime;
  final double durationSeconds;
  final String? workerId; // Hangi usta bu oturumda çalıştı

  /// JSON'dan WorkSession oluşturur
  factory WorkSession.fromJson(Map<String, dynamic> json) {
    return WorkSession(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      durationSeconds: (json['durationSeconds'] as num).toDouble(),
      workerId: json['workerId'] as String?,
    );
  }
}

/// Görev detay bilgileri
class TaskDetail {
  TaskDetail({
    required this.taskId,
    required this.jobId,
    required this.area,
    required this.operationType,
    required this.startedAt,
    required this.completedAt,
    required this.durationHours,
    required this.durationMinutes,
    required this.totalDurationHours,
    required this.totalDurationMinutes,
    this.note,
    this.workSessions = const [],
  });

  final String taskId;
  final String jobId;
  final String area;
  final String operationType;
  final String? note;
  final DateTime startedAt;
  final DateTime completedAt;
  final double durationHours; // Gerçek çalışma süresi (duraklamalar hariç)
  final int durationMinutes; // Gerçek çalışma süresi (duraklamalar hariç)
  final double totalDurationHours; // Toplam süre (duraklamalar dahil)
  final int totalDurationMinutes; // Toplam süre (duraklamalar dahil)
  final List<WorkSession>
  workSessions; // Çalışma oturumları (duraklamalar varsa)

  /// Duraklamalar var mı?
  bool get hasPauses => totalDurationHours > durationHours;

  /// JSON'dan TaskDetail oluşturur
  factory TaskDetail.fromJson(Map<String, dynamic> json) {
    return TaskDetail(
      taskId: json['taskId'] as String,
      jobId: json['jobId'] as String,
      area: json['area'] as String,
      operationType: json['operationType'] as String,
      note: json['note'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: DateTime.parse(json['completedAt'] as String),
      durationHours: (json['durationHours'] as num).toDouble(),
      durationMinutes: json['durationMinutes'] as int,
      totalDurationHours:
          (json['totalDurationHours'] as num?)?.toDouble() ??
          (json['durationHours'] as num).toDouble(),
      totalDurationMinutes:
          json['totalDurationMinutes'] as int? ??
          json['durationMinutes'] as int,
      workSessions:
          (json['workSessions'] as List<dynamic>?)
              ?.map((s) => WorkSession.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Araç bazında mesai saatleri
class VehicleWorkHours {
  VehicleWorkHours({
    required this.vehicle,
    required this.totalHours,
    required this.totalMinutes,
    required this.taskCount,
    required this.tasks,
    this.firstTaskDate,
    this.lastTaskDate,
  });

  final VehicleInfo vehicle;
  final double totalHours;
  final int totalMinutes;
  final int taskCount;
  final List<TaskDetail> tasks;
  final DateTime? firstTaskDate;
  final DateTime? lastTaskDate;

  /// JSON'dan VehicleWorkHours oluşturur
  factory VehicleWorkHours.fromJson(Map<String, dynamic> json) {
    return VehicleWorkHours(
      vehicle: VehicleInfo(
        plate: json['vehicle']['plate'] as String,
        brand: json['vehicle']['brand'] as String,
        model: json['vehicle']['model'] as String,
      ),
      totalHours: (json['totalHours'] as num).toDouble(),
      totalMinutes: json['totalMinutes'] as int,
      taskCount: json['taskCount'] as int,
      tasks:
          (json['tasks'] as List<dynamic>?)
              ?.map((t) => TaskDetail.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      firstTaskDate: json['firstTaskDate'] != null
          ? DateTime.parse(json['firstTaskDate'] as String)
          : null,
      lastTaskDate: json['lastTaskDate'] != null
          ? DateTime.parse(json['lastTaskDate'] as String)
          : null,
    );
  }
}

/// İşçi mesai saatleri raporu
class WorkerHoursReport {
  WorkerHoursReport({
    required this.success,
    this.workerId,
    this.workerName,
    required this.totalHours,
    required this.totalMinutes,
    required this.vehicleHours,
    this.totalWorkers = 1,
    this.message,
  });

  final bool success;
  final String? workerId;
  final String? workerName;
  final double totalHours;
  final int totalMinutes;
  final List<VehicleWorkHours> vehicleHours;
  final int totalWorkers;
  final String? message;

  /// Tüm işçiler için rapor mu?
  bool get isAllWorkers => workerId == null;

  /// JSON'dan WorkerHoursReport oluşturur
  factory WorkerHoursReport.fromJson(Map<String, dynamic> json) {
    return WorkerHoursReport(
      success: json['success'] as bool,
      workerId: json['workerId'] as String?,
      workerName: json['workerName'] as String?,
      totalHours: (json['totalHours'] as num).toDouble(),
      totalMinutes: json['totalMinutes'] as int,
      vehicleHours: (json['vehicleHours'] as List<dynamic>)
          .map((v) => VehicleWorkHours.fromJson(v as Map<String, dynamic>))
          .toList(),
      totalWorkers: json['totalWorkers'] as int? ?? 1,
      message: json['message'] as String?,
    );
  }
}
