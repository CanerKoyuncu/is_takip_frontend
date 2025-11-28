import 'package:flutter/material.dart';

import '../models/vehicle_area.dart';

/// Priority order used for drawing and legends (canonical keys).
const List<String> damageActionPriority = <String>[
  VehicleDamageActions.boya,
  VehicleDamageActions.kaporta,
  VehicleDamageActions.degisim,
  VehicleDamageActions.temizle,
];

/// Immutable styling information for each damage action.
class DamageActionStyle {
  const DamageActionStyle({
    required this.color,
    required this.label,
    this.stripeAngle,
  });

  /// Base color used for fills and legend swatches.
  final Color color;

  /// Optional stripe angle (degrees) for overlay patterns when
  /// multiple actions exist on the same part.
  final double? stripeAngle;

  /// Human readable description displayed in legends.
  final String label;
}

const Map<String, DamageActionStyle> _damageActionStyles =
    <String, DamageActionStyle>{
      VehicleDamageActions.boya: DamageActionStyle(
        color: Color(0xFF90CAF9),
        stripeAngle: 45,
        label: 'Boya (Mavi)',
      ),
      VehicleDamageActions.kaporta: DamageActionStyle(
        color: Color(0xFFFFF59D),
        stripeAngle: -45,
        label: 'Kaporta (Sarı)',
      ),
      VehicleDamageActions.degisim: DamageActionStyle(
        color: Color(0xFFFFCDD2),
        stripeAngle: 0,
        label: 'Parça Değişim (Kırmızı)',
      ),
      VehicleDamageActions.temizle: DamageActionStyle(
        color: Color(0xFFBDBDBD),
        stripeAngle: 90,
        label: 'Temizle (Gri)',
      ),
    };

/// Yeni action formatlarını (örn. "kaporta:onarim", "boya:yeniBoya")
/// eski kategorik anahtarlara map eder.
String _canonicalActionKey(String action) {
  // Temizle özel case
  if (action == VehicleDamageActions.temizle) {
    return VehicleDamageActions.temizle;
  }

  // Yeni format: "category:operationType"
  final parts = action.split(':');
  if (parts.length == 2) {
    final categoryPart = parts.first;
    switch (categoryPart) {
      case 'boya':
        return VehicleDamageActions.boya;
      case 'kaporta':
        return VehicleDamageActions.kaporta;
      default:
        break;
    }
  }

  // Eski formatlarda doğrudan kullan
  if (_damageActionStyles.containsKey(action)) {
    return action;
  }

  return action;
}

/// Returns the style for the given action, or null if not supported.
DamageActionStyle? damageActionStyle(String action) {
  final key = _canonicalActionKey(action);
  return _damageActionStyles[key];
}

/// Convenience helper for retrieving the base color of an action.
Color? damageActionColor(String action) {
  final key = _canonicalActionKey(action);
  return _damageActionStyles[key]?.color;
}

/// Helper that returns the stripe angle (in degrees) for an action, if any.
double? damageActionStripeAngle(String action) {
  final key = _canonicalActionKey(action);
  return _damageActionStyles[key]?.stripeAngle;
}

/// Legend label for the given action (localized / descriptive text).
String damageActionLabel(String action) {
  final key = _canonicalActionKey(action);
  return _damageActionStyles[key]?.label ?? action;
}

/// Verilen action için öncelik index'i (küçük = daha öncelikli).
int damageActionPriorityIndex(String action) {
  final key = _canonicalActionKey(action);
  final index = damageActionPriority.indexOf(key);
  return index >= 0 ? index : damageActionPriority.length;
}
