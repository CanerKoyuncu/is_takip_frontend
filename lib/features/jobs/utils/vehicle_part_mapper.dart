/// Araç Parçası Mapping Yardımcı Sınıfı
///
/// Bu sınıf, araç parçası ID'leri, VehicleArea enum'ları ve
/// hasar işlem tipleri arasında dönüşüm yapar.
///
/// Kullanım Alanları:
/// - SVG parça ID'lerini VehicleArea enum'ına dönüştürme
/// - Hasar işlem tiplerini JobOperationType'a dönüştürme
/// - VehicleArea'dan SVG parça ID'sine dönüştürme
///
/// Not: SVG dosyasındaki parça ID'leri ile VehicleArea enum'ları
/// arasında eşleştirme yapılır.

import '../models/job_models.dart';
import '../models/job_task_draft.dart';
import '../models/vehicle_area.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart' show SparePartItem;

/// Araç parçası mapping yardımcı sınıfı
///
/// Static metodlar ile parça ID'leri, enum'lar ve işlem tipleri
/// arasında dönüşüm sağlar.
/// Singleton pattern kullanır (instance oluşturulamaz).
class VehiclePartMapper {
  VehiclePartMapper._();

  static const Map<String, VehicleArea> _partIdToVehicleArea = {
    'kaput': VehicleArea.hood,
    'tavan': VehicleArea.roof,
    'bagaj-kapisi': VehicleArea.trunk,
    'on-tampon': VehicleArea.frontBumper,
    'on-tampon-demir': VehicleArea.frontBumper,
    'on-tampon-civata': VehicleArea.frontBumper,
    'sol-on-sis': VehicleArea.frontBumper,
    'sag-on-sis': VehicleArea.frontBumper,
    'arka-tampon': VehicleArea.rearBumper,
    'on-cam': VehicleArea.frontWindshield,
    'arka-cam': VehicleArea.rearWindshield,
    'sol-on-dodik': VehicleArea.leftFrontFender,
    'sol-arka-dodik': VehicleArea.leftRearQuarter,
    'sag-on-dodik': VehicleArea.rightFrontFender,
    'sag-arka-dodik': VehicleArea.rightRearQuarter,
    'sol-on-kapi': VehicleArea.leftFrontDoor,
    'sol-on-kapı': VehicleArea.leftFrontDoor,
    'sol-arka-kapi': VehicleArea.leftRearDoor,
    'sol-arka-kapı': VehicleArea.leftRearDoor,
    'sag-on-kapi': VehicleArea.rightFrontDoor,
    'sag-on-kapı': VehicleArea.rightFrontDoor,
    'sag-arka-kapi': VehicleArea.rightRearDoor,
    'sag-arka-kapı': VehicleArea.rightRearDoor,
    // Yan camlar - kapılara map edilir
    'sol-on-cam': VehicleArea.leftFrontDoor,
    'sol-arka-cam': VehicleArea.leftRearDoor,
    'sag-on-cam': VehicleArea.rightFrontDoor,
    'sag-arka-cam': VehicleArea.rightRearDoor,
    'sol-arka-kelebek': VehicleArea.leftRearDoor,
    'path682': VehicleArea
        .rightFrontDoor, // Sağ orta cam (eski ID - backward compatibility)
    'sag-orta-cam': VehicleArea.rightFrontDoor, // Yeni anlamlı ID
    // Sunroof - tavana map edilir
    'sunroof': VehicleArea.roof,
    // Çamurluklar
    'sol-on-camurluk': VehicleArea.leftFrontFender,
    'sol-arka-camurluk': VehicleArea.leftRearQuarter,
    'sag-on-camurluk': VehicleArea.rightFrontFender,
    'sag-arka-camurluk': VehicleArea.rightRearQuarter,
    // Etekler
    'sol-on-etek': VehicleArea.leftFrontFender,
    'sag-on-etek': VehicleArea.rightFrontFender,
    'sag-arka-etek': VehicleArea.rightRearQuarter,
    // Yakıt deposu kapağı
    'yakit-depo-kapagi': VehicleArea.rightRearQuarter,
    // Kapı kolları - kapılara map edilir
    'sol-on-kapi-kolu': VehicleArea.leftFrontDoor,
    'sol-arka-kapi-kolu': VehicleArea.leftRearDoor,
    'sag-arka-kapi-kolu': VehicleArea.rightRearDoor,
  };

  static const Map<VehicleArea, List<String>> _vehicleAreaToPartIds = {
    VehicleArea.hood: ['kaput'],
    VehicleArea.roof: ['tavan', 'sunroof'],
    VehicleArea.trunk: ['bagaj-kapisi'],
    VehicleArea.frontBumper: [
      'on-tampon',
      'on-tampon-demir',
      'on-tampon-civata',
      'sol-on-sis',
      'sag-on-sis',
    ],
    VehicleArea.rearBumper: ['arka-tampon'],
    VehicleArea.frontWindshield: ['on-cam'],
    VehicleArea.rearWindshield: ['arka-cam'],
    VehicleArea.leftFrontFender: [
      'sol-on-dodik',
      'sol-on-etek',
      'sol-on-camurluk',
    ],
    VehicleArea.leftRearQuarter: [
      'sol-arka-dodik',
      'sol-arka-etek',
      'sol-arka-camurluk',
    ],
    VehicleArea.rightFrontFender: [
      'sag-on-dodik',
      'sag-on-etek',
      'sag-on-camurluk',
    ],
    VehicleArea.rightRearQuarter: [
      'sag-arka-dodik',
      'sag-arka-etek',
      'sag-arka-camurluk',
      'yakit-depo-kapagi',
    ],
    VehicleArea.leftFrontDoor: [
      'sol-on-kapi',
      'sol-on-kapı',
      'sol-on-cam',
      'sol-on-kapi-kolu',
    ],
    VehicleArea.leftRearDoor: [
      'sol-arka-kapi',
      'sol-arka-kapı',
      'sol-arka-cam',
      'sol-arka-kelebek',
      'sol-arka-kapi-kolu',
    ],
    VehicleArea.rightFrontDoor: [
      'sag-on-kapi',
      'sag-on-kapı',
      'sag-on-cam',
      'path682', // Eski ID - backward compatibility
      'sag-orta-cam', // Yeni anlamlı ID
      'sag-on-kapi-kolu',
    ],
    VehicleArea.rightRearDoor: [
      'sag-arka-kapi',
      'sag-arka-kapı',
      'sag-arka-cam',
      'sag-arka-kapi-kolu',
    ],
  };

  static VehicleArea? partIdToVehicleArea(String partId) {
    return _partIdToVehicleArea[partId];
  }

  static String? vehicleAreaToPartId(VehicleArea area) {
    final candidates = _vehicleAreaToPartIds[area];
    if (candidates == null || candidates.isEmpty) {
      return null;
    }

    for (final candidate in candidates) {
      if (_partIdToVehicleArea.containsKey(candidate)) {
        return candidate;
      }
    }

    return candidates.first;
  }

  static JobOperationType? damageActionToOperationType(String action) {
    // Yeni format: "category:operationType" (örn: "kaporta:onarim", "boya:yeniBoya")
    if (action.contains(':')) {
      final parts = action.split(':');
      if (parts.length == 2) {
        final operationTypeName = parts[1];

        // JobOperationType enum'ında bu isimle eşleşen değeri bul
        try {
          return JobOperationType.values.firstWhere(
            (type) => type.name == operationTypeName,
          );
        } catch (e) {
          // Eşleşme bulunamadı, eski format'a dön
        }
      }
    }

    // Eski format (backward compatibility)
    switch (action) {
      case VehicleDamageActions.boya:
        return JobOperationType.yeniBoya; // BOYA kategorisi
      case VehicleDamageActions.kaporta:
        return JobOperationType.onarim; // Kaporta kategorisi
      case VehicleDamageActions.degisim:
        return JobOperationType.change; // Kaporta kategorisi
      case VehicleDamageActions.temizle:
        return null;
      default:
        return null;
    }
  }

  static String? operationTypeToDamageAction(JobOperationType operationType) {
    // Yeni format: "category:operationType"
    return '${operationType.category.name}:${operationType.name}';
  }

  static List<JobTaskDraft> selectionsToTaskDrafts(
    VehiclePartSelections selections,
    List<VehiclePart> parts, {
    Map<String, List<SparePartItem>> sparePartsSelections = const {},
  }) {
    final drafts = <JobTaskDraft>[];

    for (final entry in selections.entries) {
      final partId = entry.key;
      final actions = entry.value;

      if (actions.isEmpty ||
          (actions.length == 1 &&
              actions.first == VehicleDamageActions.temizle)) {
        continue;
      }

      final area = partIdToVehicleArea(partId);
      if (area == null) {
        continue;
      }

      final partSpareParts = sparePartsSelections[partId] ?? const [];

      // İlk aksiyona yedek parçaları ekleyelim (genelde kaporta aksiyonu ilk olur)
      bool sparePartsAssigned = false;

      for (final action in actions) {
        if (action == VehicleDamageActions.temizle) {
          continue;
        }

        final operationType = damageActionToOperationType(action);
        if (operationType == null) {
          continue;
        }

        drafts.add(
          JobTaskDraft(
            area: area,
            operationType: operationType,
            note: null,
            spareParts: !sparePartsAssigned ? partSpareParts : const [],
          ),
        );
        sparePartsAssigned = true;
      }
    }

    return drafts;
  }

  static VehiclePartSelections tasksToSelections(List<JobTask> tasks) {
    final selections = <String, List<String>>{};

    for (final task in tasks) {
      final partId = vehicleAreaToPartId(task.area);
      if (partId == null) {
        continue;
      }

      final action = operationTypeToDamageAction(task.operationType);
      if (action == null) {
        continue;
      }

      selections.putIfAbsent(partId, () => []);
      if (!selections[partId]!.contains(action)) {
        selections[partId]!.add(action);
      }
    }

    return selections;
  }
}
