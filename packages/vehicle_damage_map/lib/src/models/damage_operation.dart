import 'package:flutter/material.dart';

/// Damage operation categories.
enum DamageTaskCategory {
  /// Bodywork category
  kaporta,

  /// Paint category
  boya,

  /// Intake category (findings)
  tespit,
}

/// Extension for DamageTaskCategory.
extension DamageTaskCategoryX on DamageTaskCategory {
  /// Turkish label for the category.
  String get label {
    switch (this) {
      case DamageTaskCategory.kaporta:
        return 'Kaporta';
      case DamageTaskCategory.boya:
        return 'BOYA';
      case DamageTaskCategory.tespit:
        return 'TESPİT (HASARLAR)';
    }
  }

  /// Icon for the category.
  IconData get icon {
    switch (this) {
      case DamageTaskCategory.kaporta:
        return Icons.handyman_outlined;
      case DamageTaskCategory.boya:
        return Icons.format_paint_outlined;
      case DamageTaskCategory.tespit:
        return Icons.search_outlined;
    }
  }
}

/// Damage operation types.
/// Each operation belongs to a category.
enum DamageOperationType {
  // Bodywork category operations
  change,
  sokTak,
  onarim,
  doseme,
  parcaKurtarma,
  boyasizOnarim,

  // Paint category operations
  yeniBoya,
  onarimBoya,
  lokalBoya,
  pasta,

  // Intake category operations
  vuruk,
  gocuk,
  cizik,
  surtuk,
  leke,
  kirik,
}

/// İlk karşılama (tespit) ekranlarında gösterilecek hasar tipleri.
const List<DamageOperationType> intakeDamageOperations = <DamageOperationType>[
  DamageOperationType.kirik,
  DamageOperationType.gocuk,
  DamageOperationType.vuruk,
  DamageOperationType.surtuk,
  DamageOperationType.cizik,
  DamageOperationType.leke,
];

/// İş emri ekranlarında gösterilecek temel hasar tipleri.
const List<DamageOperationType> workOrderDamageOperations =
    <DamageOperationType>[
      DamageOperationType.change,
      DamageOperationType.sokTak,
      DamageOperationType.onarim,
      DamageOperationType.doseme,
      DamageOperationType.parcaKurtarma,
      DamageOperationType.boyasizOnarim,
      DamageOperationType.yeniBoya,
      DamageOperationType.onarimBoya,
      DamageOperationType.lokalBoya,
      DamageOperationType.pasta,
    ];

/// Extension for DamageOperationType.
extension DamageOperationTypeX on DamageOperationType {
  /// Turkish label for the operation.
  String get label {
    switch (this) {
      // Bodywork
      case DamageOperationType.change:
        return 'Değişim';
      case DamageOperationType.sokTak:
        return 'Sök - Tak';
      case DamageOperationType.onarim:
        return 'Onarım';
      case DamageOperationType.doseme:
        return 'Döşeme';
      case DamageOperationType.parcaKurtarma:
        return 'Parça Kurtarma';
      case DamageOperationType.boyasizOnarim:
        return 'Boyasız Onarım';
      // Paint
      case DamageOperationType.yeniBoya:
        return 'Yeni Boya';
      case DamageOperationType.onarimBoya:
        return 'Onarım Boya';
      case DamageOperationType.lokalBoya:
        return 'Lokal Boya';
      case DamageOperationType.pasta:
        return 'Pasta';
      // Intake (Findings)
      case DamageOperationType.vuruk:
        return 'Vuruk';
      case DamageOperationType.gocuk:
        return 'Göçük';
      case DamageOperationType.cizik:
        return 'Çizik';
      case DamageOperationType.surtuk:
        return 'Sürtme';
      case DamageOperationType.leke:
        return 'Leke';
      case DamageOperationType.kirik:
        return 'Kırık';
    }
  }

  /// Icon for the operation.
  IconData get icon {
    switch (this) {
      case DamageOperationType.change:
      case DamageOperationType.sokTak:
        return Icons.swap_horiz_outlined;
      case DamageOperationType.onarim:
        return Icons.build_outlined;
      case DamageOperationType.doseme:
        return Icons.chair_outlined;
      case DamageOperationType.parcaKurtarma:
        return Icons.inventory_2_outlined;
      case DamageOperationType.boyasizOnarim:
        return Icons.auto_fix_high_outlined;
      case DamageOperationType.yeniBoya:
        return Icons.format_paint_outlined;
      case DamageOperationType.onarimBoya:
        return Icons.brush_outlined;
      case DamageOperationType.lokalBoya:
        return Icons.auto_awesome_outlined;
      case DamageOperationType.pasta:
        return Icons.cleaning_services_outlined;
      case DamageOperationType.vuruk:
        return Icons.emergency_outlined;
      case DamageOperationType.gocuk:
        return Icons.panorama_fish_eye_outlined;
      case DamageOperationType.cizik:
        return Icons.linear_scale_outlined;
      case DamageOperationType.surtuk:
        return Icons.texture_outlined;
      case DamageOperationType.leke:
        return Icons.water_drop_outlined;
      case DamageOperationType.kirik:
        return Icons.dangerous_outlined;
    }
  }

  /// Category the operation belongs to.
  DamageTaskCategory get category {
    switch (this) {
      case DamageOperationType.change:
      case DamageOperationType.sokTak:
      case DamageOperationType.onarim:
      case DamageOperationType.doseme:
      case DamageOperationType.parcaKurtarma:
      case DamageOperationType.boyasizOnarim:
        return DamageTaskCategory.kaporta;
      case DamageOperationType.yeniBoya:
      case DamageOperationType.onarimBoya:
      case DamageOperationType.lokalBoya:
      case DamageOperationType.pasta:
        return DamageTaskCategory.boya;
      case DamageOperationType.vuruk:
      case DamageOperationType.gocuk:
      case DamageOperationType.cizik:
      case DamageOperationType.surtuk:
      case DamageOperationType.leke:
      case DamageOperationType.kirik:
        return DamageTaskCategory.tespit;
    }
  }

  /// Canonical key for the operation (e.g. "kaporta:onarim")
  String get actionKey => '${category.name}:$name';
}
