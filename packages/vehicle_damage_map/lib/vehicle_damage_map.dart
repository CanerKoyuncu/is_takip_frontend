export 'src/widgets/vehicle_damage_map.dart';
export 'src/widgets/custom_svg_picture.dart' hide DamageActionStyle;
export 'src/widgets/vehicle_part_autocomplete.dart';

export 'src/core/damage_action_styles.dart';
export 'src/core/svg_vehicle_part_loader.dart';
export 'src/core/damage_map_image_generator.dart';

export 'src/models/vehicle_area.dart';
export 'src/models/vehicle_config.dart'
    show
        VehiclePartConfig,
        VehiclePartsConfig,
        VehiclePartsRegistry,
        VehicleMapConfiguration,
        PartSparePartsMap;

// Parça veri yapısı — doğrudan erişim gerekiyorsa
export 'src/config/vehicle_parts_data.dart'
    show
        VehiclePartDefinition,
        SparePartItem,
        PartSupplySource,
        kVehiclePartsData;
