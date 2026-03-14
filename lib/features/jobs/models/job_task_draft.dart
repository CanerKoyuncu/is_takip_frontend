/// Görev Taslağı Sınıfı
///
/// Bu sınıf, yeni bir iş emri oluşturulurken görev bilgilerini
/// geçici olarak tutmak için kullanılır. Backend'e gönderilmeden
/// önce bu formatta tutulur.
///
/// JobTask'tan farkı:
/// - ID yok (henüz oluşturulmadı)
/// - Fotoğraflar path olarak tutulur (henüz upload edilmedi)
/// - Status yok (henüz oluşturulmadı)

import 'vehicle_area.dart';
import 'job_models.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart' show SparePartItem;

/// Görev taslağı sınıfı
///
/// Yeni iş emri oluşturulurken görev bilgilerini tutar.
class JobTaskDraft {
  JobTaskDraft({
    required this.area, // Araç parçası
    required this.operationType, // İşlem tipi
    this.note, // Notlar
    List<String> photoPaths = const [],
    List<SparePartItem> spareParts = const [],
  }) : photoPaths = List.unmodifiable(photoPaths),
       spareParts = List.unmodifiable(spareParts);

  final VehicleArea area;
  final JobOperationType operationType;
  final String? note;
  // Fotoğraf yolları - henüz backend'e upload edilmemiş fotoğraflar
  final List<String> photoPaths;
  // Bu parça için seçilen yedek parçalar
  final List<SparePartItem> spareParts;

  /// Taslak bilgilerini kopyalar ve günceller
  ///
  /// Immutable pattern - yeni bir instance oluşturur.
  JobTaskDraft copyWith({
    VehicleArea? area,
    JobOperationType? operationType,
    String? note,
    List<String>? photoPaths,
    List<SparePartItem>? spareParts,
  }) {
    return JobTaskDraft(
      area: area ?? this.area,
      operationType: operationType ?? this.operationType,
      note: note ?? this.note,
      photoPaths: photoPaths ?? this.photoPaths,
      spareParts: spareParts ?? this.spareParts,
    );
  }
}
