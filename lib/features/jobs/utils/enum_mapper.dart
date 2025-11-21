/// Enum Mapping Yardımcı Sınıfı
///
/// Bu sınıf, Flutter enum'ları ile backend string formatları arasında
/// dönüşüm yapmak için kullanılır.
///
/// Backend genellikle snake_case veya camelCase string formatı kullanır,
/// Flutter ise enum'ları kullanır. Bu sınıf bu dönüşümleri yönetir.
///
/// Dönüşümler:
/// - VehicleArea <-> backend string (snake_case)
/// - JobOperationType <-> backend string (camelCase)
/// - JobTaskStatus <-> backend string (snake_case)
/// - TaskPhotoType <-> backend string
library;

import '../models/job_models.dart'
    show
        JobOperationType,
        JobTaskStatus,
        TaskBlockingReason,
        TaskPhotoType,
        JobStatus;
import '../models/vehicle_area.dart';

/// Enum mapping yardımcı sınıfı
///
/// Static metodlar ile enum ve string dönüşümlerini sağlar.
/// Singleton pattern kullanır (instance oluşturulamaz).
class EnumMapper {
  // Private constructor - bu sınıf sadece static metodlar içerir
  EnumMapper._();

  /// VehicleArea enum'ını backend string formatına dönüştürür (snake_case)
  ///
  /// Backend'e gönderilirken enum değerlerini string'e çevirir.
  ///
  /// Parametreler:
  /// - area: VehicleArea enum değeri
  ///
  /// Döner: String - Backend formatında string (örn: "front_bumper", "left_side")
  ///
  /// Not: Bazı VehicleArea değerleri backend'de tam karşılığı olmayabilir,
  /// bu durumda en yakın eşleşme kullanılır (fallback).
  static String vehicleAreaToBackend(VehicleArea area) {
    switch (area) {
      case VehicleArea.hood:
        return 'hood';
      case VehicleArea.frontBumper:
        return 'front_bumper';
      case VehicleArea.rearBumper:
        return 'rear_bumper';
      case VehicleArea.roof:
        return 'roof';
      case VehicleArea.trunk:
        return 'trunk';
      case VehicleArea.leftFrontDoor:
        return 'front_left_door';
      case VehicleArea.rightFrontDoor:
        return 'front_right_door';
      case VehicleArea.leftRearDoor:
        return 'rear_left_door';
      case VehicleArea.rightRearDoor:
        return 'rear_right_door';
      case VehicleArea.leftFrontFender:
        // Backend has left_side, map to closest match
        return 'left_side';
      case VehicleArea.rightFrontFender:
        // Backend has right_side, map to closest match
        return 'right_side';
      case VehicleArea.leftRearQuarter:
        // Backend doesn't have this, use left_side as fallback
        return 'left_side';
      case VehicleArea.rightRearQuarter:
        // Backend doesn't have this, use right_side as fallback
        return 'right_side';
      case VehicleArea.frontWindshield:
        // Backend doesn't have this, use roof as fallback
        return 'roof';
      case VehicleArea.rearWindshield:
        // Backend doesn't have this, use roof as fallback
        return 'roof';
    }
  }

  /// Backend string'ini VehicleArea enum'ına dönüştürür
  ///
  /// Backend'den gelen string değerlerini Flutter enum'ına çevirir.
  ///
  /// Parametreler:
  /// - value: Backend string değeri (örn: "front_bumper", "left_side")
  ///
  /// Döner: VehicleArea - Enum değeri
  ///
  /// Not: Bilinmeyen değerler için varsayılan olarak VehicleArea.hood döner.
  static VehicleArea vehicleAreaFromBackend(String value) {
    switch (value) {
      case 'hood':
        return VehicleArea.hood;
      case 'front_bumper':
        return VehicleArea.frontBumper;
      case 'rear_bumper':
        return VehicleArea.rearBumper;
      case 'roof':
        return VehicleArea.roof;
      case 'trunk':
        return VehicleArea.trunk;
      case 'front_left_door':
        return VehicleArea.leftFrontDoor;
      case 'front_right_door':
        return VehicleArea.rightFrontDoor;
      case 'rear_left_door':
        return VehicleArea.leftRearDoor;
      case 'rear_right_door':
        return VehicleArea.rightRearDoor;
      case 'left_side':
        // Map to leftFrontFender as closest match
        return VehicleArea.leftFrontFender;
      case 'right_side':
        // Map to rightFrontFender as closest match
        return VehicleArea.rightFrontFender;
      default:
        // Default fallback
        return VehicleArea.hood;
    }
  }

  /// JobOperationType enum'ını backend string formatına dönüştürür
  ///
  /// Backend'e gönderilirken enum değerlerini string'e çevirir.
  ///
  /// Parametreler:
  /// - type: JobOperationType enum değeri
  ///
  /// Döner: String - Backend formatında string (örn: "bodyRepair", "paint")
  static String jobOperationTypeToBackend(JobOperationType type) {
    switch (type) {
      case JobOperationType.bodyRepair:
        return 'bodyRepair';
      case JobOperationType.paint:
        return 'paint';
      case JobOperationType.partReplacement:
        return 'replacement';
      case JobOperationType.polish:
        return 'polish';
      case JobOperationType.other:
        return 'other';
    }
  }

  /// Backend string'ini JobOperationType enum'ına dönüştürür
  ///
  /// Backend'den gelen string değerlerini Flutter enum'ına çevirir.
  ///
  /// Parametreler:
  /// - value: Backend string değeri (örn: "bodyRepair", "paint")
  ///
  /// Döner: JobOperationType - Enum değeri
  ///
  /// Not: Bilinmeyen değerler için varsayılan olarak JobOperationType.other döner.
  static JobOperationType jobOperationTypeFromBackend(String value) {
    switch (value) {
      case 'bodyRepair':
        return JobOperationType.bodyRepair;
      case 'paint':
        return JobOperationType.paint;
      case 'replacement':
        return JobOperationType.partReplacement;
      case 'polish':
        return JobOperationType.polish;
      case 'other':
        return JobOperationType.other;
      default:
        return JobOperationType.other;
    }
  }

  /// JobTaskStatus enum'ını backend string formatına dönüştürür
  ///
  /// Backend'e gönderilirken enum değerlerini string'e çevirir.
  ///
  /// Parametreler:
  /// - status: JobTaskStatus enum değeri
  ///
  /// Döner: String - Backend formatında string (örn: "pending", "in_progress")
  static String jobTaskStatusToBackend(JobTaskStatus status) {
    switch (status) {
      case JobTaskStatus.pending:
        return 'pending';
      case JobTaskStatus.inProgress:
        return 'in_progress';
      case JobTaskStatus.paused:
        return 'paused';
      case JobTaskStatus.completed:
        return 'completed';
    }
  }

  /// Backend string'ini JobTaskStatus enum'ına dönüştürür
  ///
  /// Backend'den gelen string değerlerini Flutter enum'ına çevirir.
  ///
  /// Parametreler:
  /// - value: Backend string değeri (örn: "pending", "in_progress")
  ///
  /// Döner: JobTaskStatus - Enum değeri
  ///
  /// Not: Bilinmeyen değerler için varsayılan olarak JobTaskStatus.pending döner.
  static JobTaskStatus jobTaskStatusFromBackend(String value) {
    switch (value) {
      case 'pending':
        return JobTaskStatus.pending;
      case 'in_progress':
        return JobTaskStatus.inProgress;
      case 'paused':
        return JobTaskStatus.paused;
      case 'completed':
        return JobTaskStatus.completed;
      default:
        return JobTaskStatus.pending;
    }
  }

  /// TaskBlockingReason enum'ını backend string formatına dönüştürür
  ///
  /// Backend'e gönderilirken enum değerlerini string'e çevirir.
  ///
  /// Parametreler:
  /// - reason: TaskBlockingReason enum değeri
  ///
  /// Döner: String - Backend formatında string (örn: "part_waiting", "expert_waiting")
  static String taskBlockingReasonToBackend(TaskBlockingReason reason) {
    switch (reason) {
      case TaskBlockingReason.partWaiting:
        return 'part_waiting';
      case TaskBlockingReason.expertWaiting:
        return 'expert_waiting';
      case TaskBlockingReason.supplyStage:
        return 'supply_stage';
    }
  }

  /// Backend string'ini TaskBlockingReason enum'ına dönüştürür
  ///
  /// Backend'den gelen string değerlerini Flutter enum'ına çevirir.
  ///
  /// Parametreler:
  /// - value: Backend string değeri (örn: "part_waiting", "expert_waiting")
  ///
  /// Döner: TaskBlockingReason - Enum değeri
  ///
  /// Not: Bilinmeyen değerler için null döner.
  static TaskBlockingReason? taskBlockingReasonFromBackend(String value) {
    switch (value) {
      case 'part_waiting':
        return TaskBlockingReason.partWaiting;
      case 'expert_waiting':
        return TaskBlockingReason.expertWaiting;
      case 'supply_stage':
        return TaskBlockingReason.supplyStage;
      default:
        return null;
    }
  }

  /// TaskPhotoType enum'ını backend string formatına dönüştürür
  ///
  /// Backend'e gönderilirken enum değerlerini string'e çevirir.
  ///
  /// Parametreler:
  /// - type: TaskPhotoType enum değeri
  ///
  /// Döner: String - Backend formatında string (örn: "damage", "completion")
  static String taskPhotoTypeToBackend(TaskPhotoType type) {
    switch (type) {
      case TaskPhotoType.damage:
        return 'damage';
      case TaskPhotoType.completion:
        return 'completion';
      case TaskPhotoType.other:
        return 'other';
    }
  }

  /// Backend string'ini TaskPhotoType enum'ına dönüştürür
  ///
  /// Backend'den gelen string değerlerini Flutter enum'ına çevirir.
  ///
  /// Parametreler:
  /// - value: Backend string değeri (örn: "damage", "completion")
  ///
  /// Döner: TaskPhotoType - Enum değeri
  ///
  /// Not: Bilinmeyen değerler için varsayılan olarak TaskPhotoType.damage döner.
  static TaskPhotoType taskPhotoTypeFromBackend(String value) {
    switch (value) {
      case 'damage':
        return TaskPhotoType.damage;
      case 'completion':
        return TaskPhotoType.completion;
      case 'other':
        return TaskPhotoType.other;
      default:
        return TaskPhotoType.damage;
    }
  }

  /// JobStatus enum'ını backend string formatına dönüştürür
  ///
  /// Backend'e gönderilirken enum değerlerini string'e çevirir.
  ///
  /// Parametreler:
  /// - status: JobStatus enum değeri
  ///
  /// Döner: String - Backend formatında string (örn: "hazirlik", "kaporta")
  static String jobStatusToBackend(JobStatus status) {
    switch (status) {
      case JobStatus.hazirlik:
        return 'hazirlik';
      case JobStatus.kaporta:
        return 'kaporta';
      case JobStatus.boya:
        return 'boya';
      case JobStatus.tamamlandi:
        return 'tamamlandi';
    }
  }

  /// Backend string'ini JobStatus enum'ına dönüştürür
  ///
  /// Backend'den gelen string değerlerini Flutter enum'ına çevirir.
  ///
  /// Parametreler:
  /// - value: Backend string değeri (örn: "hazirlik", "kaporta")
  ///
  /// Döner: JobStatus? - Enum değeri (null olabilir)
  ///
  /// Not: Bilinmeyen değerler için null döner.
  static JobStatus? jobStatusFromBackend(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'hazirlik':
        return JobStatus.hazirlik;
      case 'kaporta':
        return JobStatus.kaporta;
      case 'boya':
        return JobStatus.boya;
      case 'tamamlandi':
        return JobStatus.tamamlandi;
      default:
        return null;
    }
  }
}
