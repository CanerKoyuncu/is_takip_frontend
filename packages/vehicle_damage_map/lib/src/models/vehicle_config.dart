import '../config/vehicle_parts_data.dart';

// Re-export VehiclePartDefinition and related types from config
export '../config/vehicle_parts_data.dart'
    show
        VehiclePartDefinition,
        SparePartItem,
        PartSupplySource,
        kVehiclePartsData;

/// Kullanıcının seçtiği parçalar için yedek parça listesi.
/// partId → kullanıcı tarafından eklenen/düzenlenen yedek parçalar
typedef VehiclePartSparePartsSelections = Map<String, List<SparePartItem>>;

/// Alias for VehiclePartSparePartsSelections
typedef PartSparePartsMap = VehiclePartSparePartsSelections;

/// Araç parçası widget konfigürasyonu.
///
/// [VehiclePartDefinition]'dan türetilir — [kVehiclePartsData] tek kaynak.
class VehiclePartConfig {
  const VehiclePartConfig({
    required this.id,
    required this.name,
    this.description,
    this.allowedActions = const [],
    this.spareParts = const [],
  });

  /// Parça ID'si (SVG'deki id ile eşleşmeli)
  final String id;

  /// Parça adı (Türkçe)
  final String name;

  /// Parça açıklaması (opsiyonel)
  final String? description;

  /// Bu parça için izin verilen işlemler
  final List<String> allowedActions;

  /// Bu parça için gereken yedek parçalar
  final List<SparePartItem> spareParts;

  factory VehiclePartConfig.fromDefinition(VehiclePartDefinition def) {
    return VehiclePartConfig(
      id: def.id,
      name: def.name,
      allowedActions: def.allowedActions,
      spareParts: def.spareParts,
    );
  }
}

/// Tüm araç parçalarının kayıt defteri.
///
/// [kVehiclePartsData] const verisini parse ederek tipli nesnelere dönüştürür.
/// Hem SVG yükleyici hem widget config bu sınıfı kullanır.
class VehiclePartsRegistry {
  VehiclePartsRegistry._();

  /// Tüm parça tanımları (tek kaynak).
  static final List<VehiclePartDefinition> all = kVehiclePartsData
      .map(VehiclePartDefinition.fromMap)
      .toList(growable: false);

  /// Widget konfigürasyonu listesi.
  static List<VehiclePartConfig> get partConfigs =>
      all.map(VehiclePartConfig.fromDefinition).toList(growable: false);

  /// ID'ye göre parça tanımı al.
  static VehiclePartDefinition? byId(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Belirli bir aksiyon için izin verilen parçalar.
  static List<VehiclePartDefinition> byAction(String action) =>
      all.where((p) => p.allowedActions.contains(action)).toList();
}

/// Tüm parça ID'leri (yalnızca gerçek ID'ler, alias'lar hariç).
class VehiclePartsConfig {
  VehiclePartsConfig._();

  /// [VehiclePartsRegistry.partConfigs] ile aynı — geriye uyumluluk için.
  static List<VehiclePartConfig> get parts => VehiclePartsRegistry.partConfigs;

  /// Tüm parça ID'lerini al
  static List<String> getAllPartIds() =>
      VehiclePartsRegistry.all.map((p) => p.id).toList();

  /// Tüm parça isimlerini al (id -> name)
  static Map<String, String> getAllPartNames() => {
    for (final p in VehiclePartsRegistry.all) p.id: p.name,
  };

  /// Belirli bir ID için konfigürasyonu bul
  static VehiclePartConfig? getPartById(String id) {
    final def = VehiclePartsRegistry.byId(id);
    if (def == null) return null;
    return VehiclePartConfig.fromDefinition(def);
  }

  /// Belirli bir aksiyon için izin verilen parçaları al
  static List<VehiclePartConfig> getPartsByAction(String action) =>
      VehiclePartsRegistry.byAction(
        action,
      ).map(VehiclePartConfig.fromDefinition).toList();
}

/// Unified configuration for the map
class VehicleMapConfiguration {
  final List<VehiclePartConfig> parts;

  const VehicleMapConfiguration({required this.parts});

  /// Default configuration — tüm standart sedan parçaları
  factory VehicleMapConfiguration.standard() {
    return VehicleMapConfiguration(parts: VehiclePartsConfig.parts);
  }

  /// Özel konfigürasyon — parça ekle veya çıkar
  factory VehicleMapConfiguration.custom({
    List<VehiclePartConfig>? addedParts,
    List<String>? removedPartIds,
  }) {
    final currentParts = List<VehiclePartConfig>.from(VehiclePartsConfig.parts);

    if (removedPartIds != null) {
      currentParts.removeWhere((p) => removedPartIds.contains(p.id));
    }

    if (addedParts != null) {
      for (final newPart in addedParts) {
        final index = currentParts.indexWhere((p) => p.id == newPart.id);
        if (index >= 0) {
          currentParts[index] = newPart;
        } else {
          currentParts.add(newPart);
        }
      }
    }

    return VehicleMapConfiguration(parts: currentParts);
  }

  List<String> get interactablePartIds => parts.map((e) => e.id).toList();

  VehiclePartConfig? getPart(String id) {
    try {
      return parts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
