import 'package:flutter/material.dart';

import '../models/vehicle_area.dart';

/// Hasar işlem öncelik sırası. Kaporta/Boya işlemlerinden daha öncelikli gösterilir.
const List<String> damageActionPriority = <String>[
  'tespit:kirik',
  'tespit:gocuk',
  'tespit:vuruk',
  'tespit:surtuk',
  'tespit:cizik',
  'tespit:leke',
  VehicleDamageActions.degisim,
  VehicleDamageActions.boya,
  VehicleDamageActions.kaporta,
  VehicleDamageActions.temizle,
];

/// Stil bilgisi
class DamageActionStyle {
  const DamageActionStyle({
    required this.color,
    required this.label,
    this.stripeAngle,
  });

  final Color color;
  final double? stripeAngle;
  final String label;
}

const Map<String, DamageActionStyle> _damageActionStyles =
    <String, DamageActionStyle>{
      VehicleDamageActions.boya: DamageActionStyle(
        color: Color(0xFF90CAF9),
        stripeAngle: 45,
        label: 'Boya',
      ),
      VehicleDamageActions.kaporta: DamageActionStyle(
        color: Color(0xFFFFF59D),
        stripeAngle: -45,
        label: 'Kaporta',
      ),
      VehicleDamageActions.degisim: DamageActionStyle(
        color: Color(0xFFFFCDD2),
        stripeAngle: 0,
        label: 'Değişim',
      ),
      VehicleDamageActions.temizle: DamageActionStyle(
        color: Color(0xFFBDBDBD),
        stripeAngle: 90,
        label: 'Temizle',
      ),
      // Intake Findings (Tespitler)
      'tespit:vuruk': DamageActionStyle(
        color: Color(0xFFFF9800), // Orange
        label: 'Vuruk',
      ),
      'tespit:gocuk': DamageActionStyle(
        color: Color(0xFFFF7043), // Deep Orange
        label: 'Göçük',
      ),
      'tespit:cizik': DamageActionStyle(
        color: Color(0xFFFFD54F), // Amber/Yellow
        label: 'Çizik',
      ),
      'tespit:surtuk': DamageActionStyle(
        color: Color(0xFFA1887F), // Brownish
        label: 'Sürtme',
      ),
      'tespit:leke': DamageActionStyle(
        color: Color(0xFFBA68C8), // Purple
        label: 'Leke',
      ),
      'tespit:kirik': DamageActionStyle(
        color: Color(0xFFE57373), // Light Red
        label: 'Kırık',
      ),
    };

/// Yeni action formatlarını (örn. "kaporta:onarim", "boya:yeniBoya")
/// uygun anahtarlara map eder.
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
        if (parts.last == 'change') return VehicleDamageActions.degisim;
        return VehicleDamageActions.kaporta;
      case 'tespit':
        return action; // Tespitlerde tipi koru (vuruk, cizik vb.)
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

/// Returns the canonical key used in style maps.
String canonicalDamageActionKey(String action) {
  return _canonicalActionKey(action);
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
  // Tespitler için özel label yönetimi (extension'dan gelebilir ama burada da mapleyebiliriz)
  final key = _canonicalActionKey(action);
  if (_damageActionStyles.containsKey(key)) {
    return _damageActionStyles[key]!.label;
  }
  return action;
}

/// Verilen action için öncelik index'i (küçük = daha öncelikli).
int damageActionPriorityIndex(String action) {
  final key = _canonicalActionKey(action);
  final index = damageActionPriority.indexOf(key);
  return index >= 0 ? index : damageActionPriority.length;
}
