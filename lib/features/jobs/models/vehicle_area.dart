/// Araç Bölgesi Modelleri
///
/// Bu dosya, araç üzerindeki bölgeleri (parçaları) tanımlar.
/// Enum ve extension'lar ile araç parçalarının Türkçe isimlerini
/// ve görsel temsillerini sağlar.
///
/// İçerik:
/// - VehicleArea: Araç bölgeleri enum'ı
/// - VehicleDamageActions: Hasar işlem tipleri
/// - VehiclePart: Tıklanabilir araç parçası
/// - VehiclePartSelections: Seçilen parça ve işlemler

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

/// Araç bölgesi enum'ı
///
/// Araç üzerindeki farklı bölgeleri (parçaları) temsil eder.
/// Her bölge, hasar haritasında tıklanabilir bir alan olarak gösterilir.
enum VehicleArea {
  /// Ön tampon
  frontBumper,

  /// Kaput
  hood,

  /// Tavan
  roof,

  /// Bagaj
  trunk,

  /// Arka tampon
  rearBumper,

  /// Sol ön çamurluk
  leftFrontFender,

  /// Sol ön kapı
  leftFrontDoor,

  /// Sol arka kapı
  leftRearDoor,

  /// Sol arka çamurluk
  leftRearQuarter,

  /// Sağ ön çamurluk
  rightFrontFender,

  /// Sağ ön kapı
  rightFrontDoor,

  /// Sağ arka kapı
  rightRearDoor,

  /// Sağ arka çamurluk
  rightRearQuarter,

  /// Ön cam
  frontWindshield,

  /// Arka cam
  rearWindshield,
}

/// VehicleArea extension'ı
///
/// Araç bölgesine göre Türkçe etiket sağlar.
extension VehicleAreaX on VehicleArea {
  /// Bölgenin Türkçe etiketi
  String get label {
    switch (this) {
      case VehicleArea.frontBumper:
        return 'Ön Tampon';
      case VehicleArea.hood:
        return 'Kaput';
      case VehicleArea.roof:
        return 'Tavan';
      case VehicleArea.trunk:
        return 'Bagaj';
      case VehicleArea.rearBumper:
        return 'Arka Tampon';
      case VehicleArea.leftFrontFender:
        return 'Sol Ön Çamurluk';
      case VehicleArea.leftFrontDoor:
        return 'Sol Ön Kapı';
      case VehicleArea.leftRearDoor:
        return 'Sol Arka Kapı';
      case VehicleArea.leftRearQuarter:
        return 'Sol Arka Çamurluk';
      case VehicleArea.rightFrontFender:
        return 'Sağ Ön Çamurluk';
      case VehicleArea.rightFrontDoor:
        return 'Sağ Ön Kapı';
      case VehicleArea.rightRearDoor:
        return 'Sağ Arka Kapı';
      case VehicleArea.rightRearQuarter:
        return 'Sağ Arka Çamurluk';
      case VehicleArea.frontWindshield:
        return 'Ön Cam';
      case VehicleArea.rearWindshield:
        return 'Arka Cam';
    }
  }
}

/// Hasar işlem tipleri
///
/// Kullanıcı dostu etiketler için string sabitleri.
/// Bu değerler, kullanıcının hasar haritasında seçebileceği
/// işlem tiplerini temsil eder.
class VehicleDamageActions {
  /// Boya işlemi
  static const boya = 'Boya';

  /// Kaporta işlemi
  static const kaporta = 'Kaporta';

  /// Parça değişimi
  static const degisim = 'Değişim';

  /// Temizleme (görev oluşturmaz)
  static const temizle = 'Temizle';

  /// Tüm işlem tipleri listesi
  static const values = [boya, kaporta, degisim, temizle];
}

/// Tıklanabilir araç parçası sınıfı
///
/// Hasar haritasında gösterilen ve tıklanabilir olan
/// araç parçalarını temsil eder.
///
/// Her parça:
/// - SVG path'inden oluşturulur
/// - Tıklanabilir bir alan olarak gösterilir
/// - Seçildiğinde işlem tipleri seçilebilir
class VehiclePart {
  VehiclePart({
    required this.id, // Parça ID'si (SVG group ID'si)
    required this.displayName, // Görünen isim
    required this.path, // SVG path (çizim için)
    this.allowBoundsHitTest = false,
  }) : bounds = path.getBounds(); // Bounding box (hit test için)

  /// SVG path data'dan parça oluşturur
  ///
  /// Factory constructor - SVG path string'inden parça oluşturur.
  factory VehiclePart.fromSvgPathData({
    required String id,
    required String displayName,
    required String svgPathData, // SVG path string'i
    Offset translation = Offset.zero, // Öteleme (varsayılan: yok)
  }) {
    // SVG path'i parse et
    var parsedPath = parseSvgPathData(svgPathData);
    // Öteleme varsa uygula
    if (translation != Offset.zero) {
      parsedPath = parsedPath.shift(translation);
    }

    return VehiclePart(id: id, displayName: displayName, path: parsedPath);
  }

  /// Benzersiz tanımlayıcı (map key olarak kullanılabilir)
  final String id;

  /// Kullanıcı dostu görünen isim
  final String displayName;

  /// Canvas üzerinde çizilecek parse edilmiş path
  final Path path;

  /// Some parts are drawn with stroke-only paths (fill:none). When true we
  /// treat the bounding box as clickable to provide a better hit area.
  final bool allowBoundsHitTest;

  /// Hit test optimizasyonu için sınırlayıcı dikdörtgen
  final Rect bounds;
}

/// Seçilen parça ve işlemler tipi
///
/// Parça ID'sini, seçilen işlem tiplerinin listesine map eder.
/// Bir parça için birden fazla işlem seçilebilir.
///
/// Örnek:
/// {
///   'kaput': ['Boya', 'Kaporta'],
///   'on-tampon': ['Değişim']
/// }
typedef VehiclePartSelections = Map<String, List<String>>;
