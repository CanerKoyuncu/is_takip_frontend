// SVG Araç Parçası Yükleyici
//
// SVG dosyasını yükler ve VehiclePartsRegistry'deki konfigürasyona göre
// her bir grubu VehiclePart instance'larına dönüştürür.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_drawing/path_drawing.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:xml/xml.dart' as xml;

import '../models/vehicle_area.dart';
import '../models/vehicle_config.dart';

/// SVG araç parçası yükleyici sınıfı
///
/// Singleton pattern — tek instance.
/// SVG dosyalarını yükler, [VehiclePartsRegistry]'den gelen konfigürasyon
/// ile filtreleyerek [VehiclePart] listesine dönüştürür.
class SvgVehiclePartLoader {
  SvgVehiclePartLoader._();
  static final SvgVehiclePartLoader instance = SvgVehiclePartLoader._();

  final Map<String, Future<List<VehiclePart>>> _cache = {};

  /// SVG dosyasını yükler ve [VehiclePart] listesine dönüştürür.
  ///
  /// Cache mekanizması kullanır — aynı dosya tekrar yüklenmez.
  Future<List<VehiclePart>> load({
    String assetName = 'assets/car-cutout-grouped.svg',
  }) {
    return _cache.putIfAbsent(assetName, () async {
      final rawSvg = await rootBundle.loadString(assetName);
      // VehiclePartsRegistry'den konfigürasyonu al — her çağrıda güncel
      final partConfigs = _buildPartConfigs();
      return _SvgVehiclePartParser(
        rawSvg: rawSvg,
        partConfigs: partConfigs,
      ).parse();
    });
  }

  /// [VehiclePartDefinition] listesinden SVG parser'ın beklediği Map'i oluşturur.
  static Map<String, VehicleSvgPartConfig> _buildPartConfigs() {
    return {
      for (final def in VehiclePartsRegistry.all)
        def.id: VehicleSvgPartConfig(
          id: def.id,
          displayName: def.name,
          allowBoundsHitTest: def.allowBoundsHitTest,
          aliasFor: def.aliasFor,
        ),
    };
  }
}

/// SVG parça yapılandırması — parser'da kullanılır.
class VehicleSvgPartConfig {
  const VehicleSvgPartConfig({
    required this.id,
    required this.displayName,
    this.allowBoundsHitTest = false,
    this.aliasFor,
  });

  final String id;
  final String displayName;
  final bool allowBoundsHitTest;

  /// Bu ID SVG'de farklı bir ID olarak geçiyorsa (örn. path682 → sag-orta-cam).
  final String? aliasFor;
}

// ---------------------------------------------------------------------------
// İç parser — dışa açılmaz
// ---------------------------------------------------------------------------

class _SvgVehiclePartParser {
  _SvgVehiclePartParser({
    required this.rawSvg,
    required this.partConfigs,
  });

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
        final rawId = config.id;
        final path = _partPaths[rawId];
        if (path == null) {
          debugPrint('[SVG Parser] Parça SVG\'de bulunamadı: $rawId');
          continue;
        }

        final bounds = path.getBounds();
        if (bounds.isEmpty || bounds.width == 0 || bounds.height == 0) {
          debugPrint('[SVG Parser] Geçersiz bounds, atlandı: $rawId');
          continue;
        }

        // aliasFor varsa anlamlı ID'yi kullan (path682 → sag-orta-cam)
        final meaningfulId = _resolveToMeaningfulId(rawId);

        parts.add(
          VehiclePart(
            id: meaningfulId,
            displayName: config.displayName,
            path: Path.from(path),
            allowBoundsHitTest: config.allowBoundsHitTest,
          ),
        );

        debugPrint(
          '[SVG Parser] Yüklendi: $rawId → $meaningfulId '
          '(${config.displayName}), bounds: $bounds',
        );
      }

      debugPrint(
        '[SVG Parser] Toplam ${parts.length} parça '
        '(${partConfigs.length} konfigürasyondan).',
      );
      return parts;
    } catch (e, st) {
      debugPrint('[SVG Parser] Hata: $e\n$st');
      rethrow;
    }
  }

  String _resolveToMeaningfulId(String id) {
    // aliasFor değerini registry'den al
    final def = VehiclePartsRegistry.byId(id);
    return def?.aliasFor ?? id;
  }

  void _visitElement(
    xml.XmlElement element,
    vm.Matrix4 transform,
    String? activePartId,
  ) {
    final elementId = element.getAttribute('id');
    final nextPartId =
        (elementId != null && elementId.isNotEmpty) ? elementId : activePartId;

    final combinedTransform = vm.Matrix4.copy(transform)
      ..multiply(_parseTransform(element.getAttribute('transform')));

    final targetPartId =
        (elementId != null && elementId.isNotEmpty) ? elementId : nextPartId;

    switch (element.name.local) {
      case 'path':
      case 'rect':
      case 'circle':
        final resolvedPartId =
            (targetPartId != null && partConfigs.containsKey(targetPartId))
                ? targetPartId
                : (activePartId != null &&
                      partConfigs.containsKey(activePartId))
                    ? activePartId
                    : null;

        if (resolvedPartId != null) {
          final style = _extractStyle(element);
          final path = _createPath(element, style);
          if (path != null) {
            final transformedPath = path.transform(combinedTransform.storage);
            _partPaths.update(
              resolvedPartId,
              (existing) => existing..addPath(transformedPath, Offset.zero),
              ifAbsent: () => Path()..addPath(transformedPath, Offset.zero),
            );
          }
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
    switch (element.name.local) {
      case 'path':
        final data = element.getAttribute('d');
        if (data == null || data.trim().isEmpty) return null;
        final path = parseSvgPathData(data);
        final fillRule = _parseFillRule(style['fill-rule']);
        if (fillRule != null) path.fillType = fillRule;
        return path;

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
          return Path()
            ..addRRect(RRect.fromRectXY(rect, rx, ry))
            ..close();
        }
        return Path()
          ..addRect(rect)
          ..close();

      case 'circle':
        final radius = _parseDouble(element.getAttribute('r'));
        if (radius == null) return null;
        final cx = _parseDouble(element.getAttribute('cx')) ?? 0;
        final cy = _parseDouble(element.getAttribute('cy')) ?? 0;
        return Path()
          ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius))
          ..close();

      default:
        return null;
    }
  }

  Map<String, String> _extractStyle(xml.XmlElement element) {
    final style = <String, String>{};
    final styleAttr = element.getAttribute('style');
    if (styleAttr != null && styleAttr.isNotEmpty) {
      for (final part in styleAttr.split(';')) {
        final entry = part.split(':');
        if (entry.length == 2) style[entry[0].trim()] = entry[1].trim();
      }
    }
    final fillRule = element.getAttribute('fill-rule');
    if (fillRule != null) style['fill-rule'] = fillRule;
    return style;
  }

  PathFillType? _parseFillRule(String? value) {
    if (value == 'evenodd') return PathFillType.evenOdd;
    return null;
  }

  double? _parseDouble(String? value) =>
      value == null ? null : double.tryParse(value.trim());

  List<double> _parseNumberList(String input) =>
      RegExp(r'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?')
          .allMatches(input)
          .map((m) => double.parse(m.group(0)!))
          .toList();

  vm.Matrix4 _parseTransform(String? transform) {
    if (transform == null || transform.trim().isEmpty) {
      return vm.Matrix4.identity();
    }
    final matrix = vm.Matrix4.identity();
    final re = RegExp(r'(\w+)\s*\(([^)]*)\)');
    for (final match in re.allMatches(transform)) {
      final command = match.group(1);
      final args = _parseNumberList(match.group(2) ?? '');
      switch (command) {
        case 'translate':
          matrix.multiply(
            vm.Matrix4.identity()
              ..translate(
                args.isNotEmpty ? args[0] : 0.0,
                args.length > 1 ? args[1] : 0.0,
              ),
          );
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
            matrix.multiply(
              vm.Matrix4.zero()
                ..setValues(
                  args[0], args[2], 0, args[4],
                  args[1], args[3], 0, args[5],
                  0, 0, 1, 0,
                  0, 0, 0, 1,
                ),
            );
          }
          break;
        case 'skewX':
          if (args.isNotEmpty) {
            final a = args[0] * math.pi / 180;
            matrix.multiply(
              vm.Matrix4.identity()..setEntry(0, 1, math.tan(a)),
            );
          }
          break;
        case 'skewY':
          if (args.isNotEmpty) {
            final a = args[0] * math.pi / 180;
            matrix.multiply(
              vm.Matrix4.identity()..setEntry(1, 0, math.tan(a)),
            );
          }
          break;
        default:
          break;
      }
    }
    return matrix;
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
