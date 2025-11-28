// SVG Araç Parçası Yükleyici
//
// Bu sınıf, gruplandırılmış SVG dosyalarını (örn: `car-cutout-grouped.svg`) yükler
// ve her bir grubu VehiclePart instance'larına dönüştürür.
//
// Özellikler:
// - SVG dosyasını assets'den yükleme
// - SVG gruplarını parse etme
// - Her grubu tıklanabilir VehiclePart'e dönüştürme
// - Cache mekanizması (aynı dosya tekrar yüklenmez)
//
// Kullanım: Hasar haritası UI'ında araç parçalarını göstermek ve
// tıklanabilir hale getirmek için kullanılır.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_drawing/path_drawing.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:xml/xml.dart' as xml;

import '../models/vehicle_area.dart';

/// SVG araç parçası yükleyici sınıfı
///
/// Singleton pattern kullanır - tek bir instance oluşturulur.
/// SVG dosyalarını yükler ve VehiclePart listesine dönüştürür.
class SvgVehiclePartLoader {
  // Private constructor - singleton pattern
  SvgVehiclePartLoader._();
  // Singleton instance
  static final SvgVehiclePartLoader instance = SvgVehiclePartLoader._();

  /// Config list exposed for UI usage (read-only).
  static Map<String, VehicleSvgPartConfig> get partConfigs =>
      Map.unmodifiable(_defaultPartConfigs);

  // Cache - aynı dosya tekrar yüklenmez
  final Map<String, Future<List<VehiclePart>>> _cache = {};

  /// SVG dosyasını yükler ve VehiclePart listesine dönüştürür
  ///
  /// Cache mekanizması kullanır - aynı dosya tekrar yüklenmez.
  ///
  /// Parametreler:
  /// - assetName: SVG dosya yolu (varsayılan: 'assets/car-cutout-grouped.svg')
  /// - partConfigs: Parça yapılandırmaları (varsayılan: `_defaultPartConfigs`)
  ///
  /// Döner: `Future<List<VehiclePart>>` - Yüklenen parçalar listesi
  Future<List<VehiclePart>> load({
    String assetName = 'assets/car-cutout-grouped.svg',
    Map<String, VehicleSvgPartConfig> partConfigs = _defaultPartConfigs,
  }) {
    // Cache'de varsa döndür, yoksa yükle ve cache'e ekle
    return _cache.putIfAbsent(assetName, () async {
      // SVG dosyasını assets'den yükle
      final rawSvg = await rootBundle.loadString(assetName);
      // SVG'yi parse et ve VehiclePart listesine dönüştür
      return _SvgVehiclePartParser(
        rawSvg: rawSvg,
        partConfigs: partConfigs,
      ).parse();
    });
  }
}

/// SVG parça yapılandırması sınıfı
///
/// Her bir SVG grubu için ID ve görünen isim bilgilerini tutar.
class VehicleSvgPartConfig {
  const VehicleSvgPartConfig({
    required this.id, // SVG group ID'si
    required this.displayName, // Kullanıcı dostu görünen isim
    this.allowBoundsHitTest = false,
  });

  final String id;
  final String displayName;
  final bool allowBoundsHitTest;
}

const Map<String, VehicleSvgPartConfig> _defaultPartConfigs = {
  // Core body
  'kaput': VehicleSvgPartConfig(id: 'kaput', displayName: 'Kaput'),
  'bagaj-kapisi': VehicleSvgPartConfig(
    id: 'bagaj-kapisi',
    displayName: 'Bagaj Kapağı',
  ),
  'on-tampon': VehicleSvgPartConfig(id: 'on-tampon', displayName: 'Ön Tampon'),
  'arka-tampon': VehicleSvgPartConfig(
    id: 'arka-tampon',
    displayName: 'Arka Tampon',
  ),
  'on-tampon-demir': VehicleSvgPartConfig(
    id: 'on-tampon-demir',
    displayName: 'Ön Tampon Demiri',
    allowBoundsHitTest: true,
  ),
  'on-tampon-civata': VehicleSvgPartConfig(
    id: 'on-tampon-civata',
    displayName: 'Ön Tampon Civataları',
  ),
  'arka-tampon-sol-stop': VehicleSvgPartConfig(
    id: 'arka-tampon-sol-stop',
    displayName: 'Arka Sol Stop',
  ),
  'arka-tampon-sag-stop': VehicleSvgPartConfig(
    id: 'arka-tampon-sag-stop',
    displayName: 'Arka Sağ Stop',
  ),

  // Left side panels & accessories (non-glass)
  'sol-on-camurluk': VehicleSvgPartConfig(
    id: 'sol-on-camurluk',
    displayName: 'Sol Ön Çamurluk',
  ),
  'sol-arka-camurluk': VehicleSvgPartConfig(
    id: 'sol-arka-camurluk',
    displayName: 'Sol Arka Çamurluk',
  ),
  'sol-on-dodik': VehicleSvgPartConfig(
    id: 'sol-on-dodik',
    displayName: 'Sol Ön Çamurluk',
  ),
  'sol-arka-dodik': VehicleSvgPartConfig(
    id: 'sol-arka-dodik',
    displayName: 'Sol Arka Çamurluk',
  ),
  'sol-on-kapi': VehicleSvgPartConfig(
    id: 'sol-on-kapi',
    displayName: 'Sol Ön Kapı',
  ),
  'sol-on-kapı': VehicleSvgPartConfig(
    id: 'sol-on-kapı',
    displayName: 'Sol Ön Kapı',
  ),
  'sol-arka-kapi': VehicleSvgPartConfig(
    id: 'sol-arka-kapi',
    displayName: 'Sol Arka Kapı',
  ),
  'sol-arka-kapı': VehicleSvgPartConfig(
    id: 'sol-arka-kapı',
    displayName: 'Sol Arka Kapı',
  ),
  'sol-on-etek': VehicleSvgPartConfig(
    id: 'sol-on-etek',
    displayName: 'Sol Marşpiyel',
  ),
  'sol-on-sis': VehicleSvgPartConfig(
    id: 'sol-on-sis',
    displayName: 'Sol Ön Sis Farı',
  ),
  'on-sol-lastik': VehicleSvgPartConfig(
    id: 'on-sol-lastik',
    displayName: 'Ön Sol Lastik',
    allowBoundsHitTest: true,
  ),
  'sol-arka-lastik': VehicleSvgPartConfig(
    id: 'sol-arka-lastik',
    displayName: 'Arka Sol Lastik',
    allowBoundsHitTest: true,
  ),

  // Right side panels & accessories (non-glass)
  'sag-on-camurluk': VehicleSvgPartConfig(
    id: 'sag-on-camurluk',
    displayName: 'Sağ Ön Çamurluk',
  ),
  'sag-arka-camurluk': VehicleSvgPartConfig(
    id: 'sag-arka-camurluk',
    displayName: 'Sağ Arka Çamurluk',
  ),
  'sag-on-dodik': VehicleSvgPartConfig(
    id: 'sag-on-dodik',
    displayName: 'Sağ Ön Çamurluk',
  ),
  'sag-arka-dodik': VehicleSvgPartConfig(
    id: 'sag-arka-dodik',
    displayName: 'Sağ Arka Çamurluk',
  ),
  'sag-on-etek': VehicleSvgPartConfig(
    id: 'sag-on-etek',
    displayName: 'Sağ Ön Marşpiyel',
  ),
  'sag-arka-etek': VehicleSvgPartConfig(
    id: 'sag-arka-etek',
    displayName: 'Sağ Arka Marşpiyel',
  ),
  'sag-on-kapi': VehicleSvgPartConfig(
    id: 'sag-on-kapi',
    displayName: 'Sağ Ön Kapı',
  ),
  'sag-on-kapı': VehicleSvgPartConfig(
    id: 'sag-on-kapı',
    displayName: 'Sağ Ön Kapı',
  ),
  'sag-arka-kapi': VehicleSvgPartConfig(
    id: 'sag-arka-kapi',
    displayName: 'Sağ Arka Kapı',
  ),
  'sag-arka-kapı': VehicleSvgPartConfig(
    id: 'sag-arka-kapı',
    displayName: 'Sağ Arka Kapı',
  ),
  'sag-on-sis': VehicleSvgPartConfig(
    id: 'sag-on-sis',
    displayName: 'Sağ Ön Sis Farı',
  ),
  'on-sag-lastik': VehicleSvgPartConfig(
    id: 'on-sag-lastik',
    displayName: 'Ön Sağ Lastik',
    allowBoundsHitTest: true,
  ),
  'arka-sag-lastik': VehicleSvgPartConfig(
    id: 'arka-sag-lastik',
    displayName: 'Arka Sağ Lastik',
    allowBoundsHitTest: true,
  ),

  // Roof & glass — placed last so they win hit-tests against body panels
  'tavan': VehicleSvgPartConfig(id: 'tavan', displayName: 'Tavan'),
  // Sunroof'u tavan'dan sonra tanımlayarak (map'in sonuna taşıyıp)
  // hit-test sırasında sunroof'un öncelikli seçilmesini sağlıyoruz.
  'sunroof': VehicleSvgPartConfig(id: 'sunroof', displayName: 'Sunroof'),
  'on-cam': VehicleSvgPartConfig(id: 'on-cam', displayName: 'Ön Cam'),
  'arka-cam': VehicleSvgPartConfig(id: 'arka-cam', displayName: 'Arka Cam'),
  'sol-on-cam': VehicleSvgPartConfig(
    id: 'sol-on-cam',
    displayName: 'Sol Ön Cam',
  ),
  'sol-arka-cam': VehicleSvgPartConfig(
    id: 'sol-arka-cam',
    displayName: 'Sol Arka Cam',
  ),
  'sol-arka-kelebek': VehicleSvgPartConfig(
    id: 'sol-arka-kelebek',
    displayName: 'Sol Arka Kelebek Cam',
  ),
  'sag-on-cam': VehicleSvgPartConfig(
    id: 'sag-on-cam',
    displayName: 'Sağ Ön Cam',
  ),
  'path682': VehicleSvgPartConfig(id: 'path682', displayName: 'Sağ Orta Cam'),
  'sag-arka-cam': VehicleSvgPartConfig(
    id: 'sag-arka-cam',
    displayName: 'Sağ Arka Cam',
  ),

  // Fuel cap
  'yakit-depo-kapagi': VehicleSvgPartConfig(
    id: 'yakit-depo-kapagi',
    displayName: 'Yakıt Deposu Kapağı',
  ),

  // Door handles
  'sol-on-kapi-kolu': VehicleSvgPartConfig(
    id: 'sol-on-kapi-kolu',
    displayName: 'Sol Ön Kapı Kolu',
  ),
  'sol-arka-kapi-kolu': VehicleSvgPartConfig(
    id: 'sol-arka-kapi-kolu',
    displayName: 'Sol Arka Kapı Kolu',
  ),
  'sag-arka-kapi-kolu': VehicleSvgPartConfig(
    id: 'sag-arka-kapi-kolu',
    displayName: 'Sağ Arka Kapı Kolu',
  ),
};

class _SvgVehiclePartParser {
  _SvgVehiclePartParser({required this.rawSvg, required this.partConfigs});

  final String rawSvg;
  final Map<String, VehicleSvgPartConfig> partConfigs;

  final Map<String, Path> _partPaths = {};

  List<VehiclePart> parse() {
    try {
      final document = xml.XmlDocument.parse(rawSvg);
      final svgElement =
          document.findElements('svg').firstOrNull ??
          document.descendants.whereType<xml.XmlElement>().firstWhere(
            (element) => element.name.local == 'svg',
          );

      _visitElement(svgElement, vm.Matrix4.identity(), null);

      final parts = <VehiclePart>[];

      for (final config in partConfigs.values) {
        final path = _partPaths[config.id];
        if (path == null) {
          debugPrint('[SVG Parser] Warning: No path found for ${config.id}');
          continue;
        }

        final metrics = path.computeMetrics().iterator;
        if (!metrics.moveNext()) {
          debugPrint('[SVG Parser] Warning: Empty path for ${config.id}');
          continue;
        }

        // Verify path has valid bounds
        final bounds = path.getBounds();
        if (bounds.isEmpty || bounds.width == 0 || bounds.height == 0) {
          debugPrint(
            '[SVG Parser] Warning: Invalid bounds for ${config.id}: $bounds',
          );
          continue;
        }

        parts.add(
          VehiclePart(
            id: config.id,
            displayName: config.displayName,
            path: Path.from(path),
            allowBoundsHitTest: config.allowBoundsHitTest,
          ),
        );

        debugPrint(
          '[SVG Parser] Loaded part: ${config.id} (${config.displayName}), bounds: $bounds',
        );
      }

      debugPrint('[SVG Parser] Successfully loaded ${parts.length} parts');
      return parts;
    } catch (e, stackTrace) {
      debugPrint('[SVG Parser] Error parsing SVG: $e');
      debugPrint('[SVG Parser] Stack trace: $stackTrace');
      rethrow;
    }
  }

  void _visitElement(
    xml.XmlElement element,
    vm.Matrix4 transform,
    String? activePartId,
  ) {
    final elementId = element.getAttribute('id');
    final nextPartId = partConfigs.containsKey(elementId)
        ? elementId
        : activePartId;

    final combinedTransform = vm.Matrix4.copy(transform)
      ..multiply(_parseTransform(element.getAttribute('transform')));

    final targetPartId = partConfigs.containsKey(elementId)
        ? elementId
        : nextPartId;

    switch (element.name.local) {
      case 'path':
      case 'rect':
      case 'circle':
        final style = _extractStyle(element);
        final path = _createPath(element, style);
        if (path != null && targetPartId != null) {
          final transformedPath = path.transform(combinedTransform.storage);
          _partPaths.update(
            targetPartId,
            (existing) => existing..addPath(transformedPath, Offset.zero),
            ifAbsent: () => Path()..addPath(transformedPath, Offset.zero),
          );
        }
        break;
      default:
        break;
    }

    for (final child in element.children.whereType<xml.XmlElement>()) {
      _visitElement(child, combinedTransform, nextPartId);
    }
  }

  Path? _createPath(xml.XmlElement element, Map<String, String> style) {
    Path? path;

    switch (element.name.local) {
      case 'path':
        final data = element.getAttribute('d');
        if (data == null || data.trim().isEmpty) return null;
        path = parseSvgPathData(data);
        final fillRule = _parseFillRule(style['fill-rule']);
        if (fillRule != null) {
          path.fillType = fillRule;
        }
        break;
      case 'rect':
        final width = _parseDouble(element.getAttribute('width'));
        final height = _parseDouble(element.getAttribute('height'));
        if (width == null || height == null) return null;
        final x = _parseDouble(element.getAttribute('x')) ?? 0;
        final y = _parseDouble(element.getAttribute('y')) ?? 0;
        final rx =
            _parseDouble(element.getAttribute('rx')) ??
            _parseDouble(element.getAttribute('ry')) ??
            0;
        final ry = _parseDouble(element.getAttribute('ry')) ?? rx;
        final rect = Rect.fromLTWH(x, y, width, height);
        if (rx > 0 || ry > 0) {
          path = Path()
            ..addRRect(RRect.fromRectXY(rect, rx, ry))
            ..close();
        } else {
          path = Path()
            ..addRect(rect)
            ..close();
        }
        break;
      case 'circle':
        final radius = _parseDouble(element.getAttribute('r'));
        if (radius == null) return null;
        final cx = _parseDouble(element.getAttribute('cx')) ?? 0;
        final cy = _parseDouble(element.getAttribute('cy')) ?? 0;
        path = Path()
          ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
          ..close();
        break;
      default:
        return null;
    }

    return path;
  }

  Map<String, String> _extractStyle(xml.XmlElement element) {
    final style = <String, String>{};

    final styleAttribute = element.getAttribute('style');
    if (styleAttribute != null && styleAttribute.isNotEmpty) {
      for (final part in styleAttribute.split(';')) {
        final entry = part.split(':');
        if (entry.length == 2) {
          style[entry[0].trim()] = entry[1].trim();
        }
      }
    }

    void readAttr(String name) {
      final value = element.getAttribute(name);
      if (value != null) {
        style[name] = value;
      }
    }

    for (final attr in const ['fill-rule']) {
      readAttr(attr);
    }

    return style;
  }

  PathFillType? _parseFillRule(String? value) {
    switch (value) {
      case 'evenodd':
        return PathFillType.evenOdd;
      case 'nonzero':
      case null:
        return null;
      default:
        return null;
    }
  }

  double? _parseDouble(String? value) {
    if (value == null) {
      return null;
    }
    return double.tryParse(value.trim());
  }

  List<double> _parseNumberList(String input) {
    final matches = RegExp(r'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?')
        .allMatches(input)
        .map((match) => match.group(0)!)
        .map(double.parse)
        .toList();
    return matches;
  }

  vm.Matrix4 _parseTransform(String? transform) {
    if (transform == null || transform.trim().isEmpty) {
      return vm.Matrix4.identity();
    }

    final matrix = vm.Matrix4.identity();
    final commandRegExp = RegExp(r'(\w+)\s*\(([^)]*)\)');

    for (final match in commandRegExp.allMatches(transform)) {
      final command = match.group(1);
      final rawArgs = match.group(2) ?? '';
      final args = _parseNumberList(rawArgs);

      switch (command) {
        case 'translate':
          final dx = args.isNotEmpty ? args[0] : 0.0;
          final dy = args.length > 1 ? args[1] : 0.0;
          matrix.multiply(vm.Matrix4.identity()..translate(dx, dy));
          break;
        case 'scale':
          final sx = args.isNotEmpty ? args[0] : 1.0;
          final sy = args.length > 1 ? args[1] : sx;
          matrix.multiply(vm.Matrix4.identity()..scale(sx, sy));
          break;
        case 'rotate':
          final angle = args.isNotEmpty ? args[0] : 0.0;
          final radians = angle * math.pi / 180;
          if (args.length > 2) {
            final cx = args[1];
            final cy = args[2];
            matrix.multiply(
              vm.Matrix4.identity()
                ..translate(cx, cy)
                ..rotateZ(radians)
                ..translate(-cx, -cy),
            );
          } else {
            matrix.multiply(vm.Matrix4.identity()..rotateZ(radians));
          }
          break;
        case 'matrix':
          if (args.length == 6) {
            final m = vm.Matrix4.zero()
              ..setValues(
                args[0],
                args[2],
                0,
                args[4],
                args[1],
                args[3],
                0,
                args[5],
                0,
                0,
                1,
                0,
                0,
                0,
                0,
                1,
              );
            matrix.multiply(m);
          }
          break;
        case 'skewX':
          if (args.isNotEmpty) {
            final angle = args[0] * math.pi / 180;
            final m = vm.Matrix4.identity()..setEntry(0, 1, math.tan(angle));
            matrix.multiply(m);
          }
          break;
        case 'skewY':
          if (args.isNotEmpty) {
            final angle = args[0] * math.pi / 180;
            final m = vm.Matrix4.identity()..setEntry(1, 0, math.tan(angle));
            matrix.multiply(m);
          }
          break;
        default:
          break;
      }
    }

    return matrix;
  }
}

extension IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
