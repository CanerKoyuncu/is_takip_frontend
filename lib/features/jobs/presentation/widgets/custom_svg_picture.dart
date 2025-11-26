import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart' as xml;
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../utils/damage_action_styles.dart';

/// Custom SVG widget that uses path_drawing and xml packages
/// instead of flutter_svg.
class CustomSvgPicture extends StatefulWidget {
  const CustomSvgPicture({
    super.key,
    required this.assetName,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorBuilder,
    this.partColorMap,
    this.partActionsMap,
  });

  final String assetName;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Map<String, Color>? partColorMap; // Part ID -> Color mapping for fill
  final Map<String, List<String>>?
  partActionsMap; // Part ID -> Actions list for striped patterns

  @override
  State<CustomSvgPicture> createState() => _CustomSvgPictureState();
}

class _CustomSvgPictureState extends State<CustomSvgPicture> {
  late Future<ParsedSvg> _parsedSvg;

  @override
  void initState() {
    super.initState();
    _parsedSvg = CustomSvgCache.instance.load(widget.assetName);
  }

  @override
  void didUpdateWidget(covariant CustomSvgPicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetName != widget.assetName) {
      _parsedSvg = CustomSvgCache.instance.load(widget.assetName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ParsedSvg>(
      future: _parsedSvg,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'CustomSvgPicture failed to load ${widget.assetName}: '
            '${snapshot.error}',
          );
          if (widget.errorBuilder != null) {
            return widget.errorBuilder!(context, snapshot.error!);
          }
          return const Center(child: Icon(Icons.error_outline));
        }

        if (!snapshot.hasData) {
          return widget.placeholder ?? const SizedBox.expand();
        }

        final parsed = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : parsed.viewBox.width;
            final height = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : parsed.viewBox.height;

            return SizedBox(
              width: width,
              height: height,
              child: CustomPaint(
                painter: _CustomSvgPainter(
                  svg: parsed,
                  fit: widget.fit,
                  partColorMap: widget.partColorMap,
                  partActionsMap: widget.partActionsMap,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CustomSvgPainter extends CustomPainter {
  const _CustomSvgPainter({
    required this.svg,
    required this.fit,
    this.partColorMap,
    this.partActionsMap,
  });

  final ParsedSvg svg;
  final BoxFit fit;
  final Map<String, Color>? partColorMap;
  final Map<String, List<String>>? partActionsMap;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final scale = _getScale(size);
    final offset = _getOffset(size, scale);

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black;

    for (final shape in svg.shapes) {
      // Check if this part has multiple actions (striped pattern)
      final actions = shape.partId != null && partActionsMap != null
          ? partActionsMap![shape.partId]
          : null;

      if (actions != null && actions.length > 1) {
        // Draw striped pattern as fill
        debugPrint(
          '[CustomSvgPicture] Drawing striped pattern for part ${shape.partId} '
          'with ${actions.length} actions: $actions',
        );
        canvas.save();
        canvas.clipPath(shape.path);
        _drawStripedPattern(canvas, shape.path, actions, scale);
        canvas.restore();
      } else {
        // Fill color varsa fill olarak çiz
        // Eğer partColorMap'te bu part için renk varsa onu kullan
        Color? fillColor = shape.fillColor;
        if (shape.partId != null && partColorMap != null) {
          final mappedColor = partColorMap![shape.partId];
          if (mappedColor != null) {
            fillColor = mappedColor;
          }
        }

        // Don't draw fill if color is transparent (used for multi-action parts)
        if (fillColor != null && fillColor != Colors.transparent) {
          paint.color = fillColor;
          paint.style = PaintingStyle.fill;
          canvas.drawPath(shape.path, paint);
        }
      }

      // Stroke color ve width varsa stroke olarak çiz
      if (shape.strokeColor != null &&
          shape.strokeWidth != null &&
          shape.strokeWidth! > 0) {
        paint.color = shape.strokeColor!;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = shape.strokeWidth!;
        canvas.drawPath(shape.path, paint);
      }
    }

    canvas.restore();
  }

  /// Draw striped pattern for multiple actions
  /// First color is used as fill, other colors are drawn as vertical and horizontal stripes
  void _drawStripedPattern(
    Canvas canvas,
    Path path,
    List<String> actions,
    double scale,
  ) {
    if (actions.isEmpty) return;

    final bounds = path.getBounds();
    // Make stripes thicker and more visible
    final stripeWidth = (15.0 / scale).clamp(2.0, 20.0);

    debugPrint(
      '[CustomSvgPicture] _drawStripedPattern: ${actions.length} actions, '
      'bounds: ${bounds.width}x${bounds.height}, stripeWidth: $stripeWidth, scale: $scale',
    );

    // Use a single clipPath for all actions to ensure proper elevation
    // (already clipped in paint method)

    // First action: draw as fill (background color)
    if (actions.isNotEmpty) {
      final firstAction = actions[0];
      final firstStyle = damageActionStyle(firstAction);
      final firstColor = firstStyle?.color;

      if (firstColor != null) {
        // Enhanced color for better visibility
        final hsvColor = HSVColor.fromColor(firstColor);
        final enhancedColor = hsvColor
            .withSaturation((hsvColor.saturation * 1.3).clamp(0.0, 1.0))
            .withValue((hsvColor.value * 1.1).clamp(0.0, 1.0))
            .toColor();

        final fillPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = enhancedColor.withValues(alpha: 1.0)
          ..isAntiAlias = true;

        canvas.drawPath(path, fillPaint);
      }
    }

    // Other actions: draw as vertical and horizontal stripes
    // Spacing is 2x stripe width: each line is stripeWidth thick with stripeWidth gap between
    // This ensures consistent line thickness for all colors and prevents overlap
    final spacing = stripeWidth * 2;

    for (int i = 1; i < actions.length; i++) {
      final action = actions[i];
      final style = damageActionStyle(action);
      final color = style?.color;

      if (style == null || color == null) {
        continue;
      }

      // Enhanced color for better visibility
      final hsvColor = HSVColor.fromColor(color);
      final enhancedColor = hsvColor
          .withSaturation((hsvColor.saturation * 1.3).clamp(0.0, 1.0))
          .withValue((hsvColor.value * 1.1).clamp(0.0, 1.0))
          .toColor();

      // Use consistent stroke width for all colors to ensure uniform thickness
      final stripePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = enhancedColor.withValues(alpha: 1.0)
        ..strokeWidth = stripeWidth
        ..strokeCap = StrokeCap
            .square // Use square cap for more consistent appearance
        ..strokeJoin = StrokeJoin.miter
        ..isAntiAlias = true;

      // Alternate between vertical (90°) and horizontal (0°) stripes
      final isVertical =
          i % 2 == 1; // Odd index = vertical, even index = horizontal

      // Draw parallel lines - ensure we cover the entire bounds
      // Start from bounds edge and add half stripe width offset for better alignment
      if (isVertical) {
        // Vertical lines - start with offset to center first line
        final startX = bounds.left + (stripeWidth / 2);
        for (double x = startX; x <= bounds.right + spacing; x += spacing) {
          final linePath = Path();
          linePath.moveTo(x, bounds.top);
          linePath.lineTo(x, bounds.bottom);
          canvas.drawPath(linePath, stripePaint);
        }
      } else {
        // Horizontal lines - start with offset to center first line
        final startY = bounds.top + (stripeWidth / 2);
        for (double y = startY; y <= bounds.bottom + spacing; y += spacing) {
          final linePath = Path();
          linePath.moveTo(bounds.left, y);
          linePath.lineTo(bounds.right, y);
          canvas.drawPath(linePath, stripePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CustomSvgPainter oldDelegate) {
    return oldDelegate.svg != svg ||
        oldDelegate.fit != fit ||
        oldDelegate.partColorMap != partColorMap ||
        oldDelegate.partActionsMap != partActionsMap;
  }

  double _getScale(Size size) {
    final scaleX = size.width / svg.viewBox.width;
    final scaleY = size.height / svg.viewBox.height;

    switch (fit) {
      case BoxFit.fill:
        return math.max(scaleX, scaleY);
      case BoxFit.contain:
        return math.min(scaleX, scaleY);
      case BoxFit.cover:
        return math.max(scaleX, scaleY);
      case BoxFit.fitWidth:
        return scaleX;
      case BoxFit.fitHeight:
        return scaleY;
      case BoxFit.none:
        return 1.0;
      case BoxFit.scaleDown:
        final scale = math.min(scaleX, scaleY);
        return scale < 1.0 ? scale : 1.0;
    }
  }

  Offset _getOffset(Size size, double scale) {
    final scaledWidth = svg.viewBox.width * scale;
    final scaledHeight = svg.viewBox.height * scale;
    final dx = (size.width - scaledWidth) / 2;
    final dy = (size.height - scaledHeight) / 2;
    return Offset(dx, dy);
  }
}

/// Parsed SVG data containing viewBox and shapes
class ParsedSvg {
  ParsedSvg({required this.viewBox, required this.shapes});

  final Rect viewBox;
  final List<SvgShape> shapes;
}

/// Single SVG shape with path and style properties
class SvgShape {
  SvgShape({
    required this.path,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth,
    this.partId,
  });

  final Path path;
  final Color? fillColor;
  final Color? strokeColor;
  final double? strokeWidth;
  final String? partId; // Part ID for color mapping (from SVG group id)

  /// Backward compatibility property
  Color? get color => fillColor;
}

/// Cache for parsed SVG files to avoid parsing same file multiple times
class CustomSvgCache {
  CustomSvgCache._();
  static final instance = CustomSvgCache._();

  final _cache = <String, Future<ParsedSvg>>{};

  Future<ParsedSvg> load(String assetName) {
    return _cache.putIfAbsent(assetName, () => _loadAndParse(assetName));
  }

  Future<ParsedSvg> _loadAndParse(String assetName) async {
    final rawSvg = await rootBundle.loadString(assetName);
    final document = xml.XmlDocument.parse(rawSvg);

    // Parse viewBox
    final svgElement = document.rootElement;
    final viewBox = _parseViewBox(svgElement.getAttribute('viewBox'));

    // Parse shapes
    final shapes = <SvgShape>[];
    _parseChildren(svgElement, vm.Matrix4.identity(), shapes, null);

    debugPrint(
      'CustomSvgCache parsed ${shapes.length} shapes from $assetName '
      'with viewBox $viewBox',
    );

    return ParsedSvg(viewBox: viewBox, shapes: shapes);
  }

  Rect _parseViewBox(String? viewBox) {
    if (viewBox == null || viewBox.isEmpty) {
      return Rect.zero;
    }

    final parts = viewBox.split(RegExp(r'[\s,]+'));
    if (parts.length != 4) {
      return Rect.zero;
    }

    return Rect.fromLTWH(
      double.parse(parts[0]),
      double.parse(parts[1]),
      double.parse(parts[2]),
      double.parse(parts[3]),
    );
  }

  void _parseChildren(
    xml.XmlElement element,
    vm.Matrix4 transform,
    List<SvgShape> shapes,
    String? activePartId,
  ) {
    final elementId = element.getAttribute('id');
    final isGroup = element.name.local == 'g';

    // Grup elemanlarında ID'yi çocuklara aktar; aksi halde mevcut id'yi koru
    String? nextPartId = activePartId;
    if (isGroup && elementId != null && elementId.isNotEmpty) {
      nextPartId = elementId;
    }

    final localTransform = _parseTransform(element.getAttribute('transform'));
    final combinedTransform = vm.Matrix4.copy(transform)
      ..multiply(localTransform);

    // Style attribute'ından renkleri ve stroke width'i parse et
    final styleAttrs = _parseStyleAttribute(element.getAttribute('style'));

    // Element tag'ına göre path oluştur
    Path? path;

    if (element.name.local == 'path') {
      final d = element.getAttribute('d');
      if (d != null && d.isNotEmpty) {
        path = parseSvgPathData(d);
      }
    } else if (element.name.local == 'rect') {
      final x = double.tryParse(element.getAttribute('x') ?? '0') ?? 0;
      final y = double.tryParse(element.getAttribute('y') ?? '0') ?? 0;
      final width = double.tryParse(element.getAttribute('width') ?? '0');
      final height = double.tryParse(element.getAttribute('height') ?? '0');
      final rx = double.tryParse(element.getAttribute('rx') ?? '0') ?? 0;
      final ry = double.tryParse(element.getAttribute('ry') ?? '0') ?? rx;

      if (width != null && height != null && width > 0 && height > 0) {
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
      }
    } else if (element.name.local == 'circle') {
      final cx = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
      final cy = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
      final r = double.tryParse(element.getAttribute('r') ?? '0');

      if (r != null && r > 0) {
        path = Path()
          ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r))
          ..close();
      }
    } else if (element.name.local == 'ellipse') {
      final cx = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
      final cy = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
      final rx = double.tryParse(element.getAttribute('rx') ?? '0');
      final ry = double.tryParse(element.getAttribute('ry') ?? '0');

      if (rx != null && ry != null && rx > 0 && ry > 0) {
        path = Path()
          ..addOval(Rect.fromLTWH(cx - rx, cy - ry, rx * 2, ry * 2))
          ..close();
      }
    }

    // Path varsa shape olarak ekle
    if (path != null) {
      final transformedPath = path.transform(combinedTransform.storage);

      // Fill ve stroke renklerini al (style'dan veya attribute'dan)
      Color? fillColor = _parseColor(
        styleAttrs['fill'] ?? element.getAttribute('fill'),
      );
      Color? strokeColor = _parseColor(
        styleAttrs['stroke'] ?? element.getAttribute('stroke'),
      );

      // Stroke width'i al
      double? strokeWidth = double.tryParse(
        styleAttrs['stroke-width'] ??
            element.getAttribute('stroke-width') ??
            '0',
      );

      // Eğer aktif bir parça ID'si varsa onu kullan, yoksa element ID'sine düş
      final shapePartId =
          nextPartId ?? (elementId != null && elementId.isNotEmpty ? elementId : null);

      shapes.add(
        SvgShape(
          path: transformedPath,
          fillColor: fillColor,
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
          partId: shapePartId, // Parent group ID veya element ID
        ),
      );
    }

    for (final child in element.children.whereType<xml.XmlElement>()) {
      _parseChildren(child, combinedTransform, shapes, nextPartId);
    }
  }

  /// SVG style attribute'unu parse eder (örn: "fill:#ff0000;stroke:#000000;stroke-width:2")
  Map<String, String> _parseStyleAttribute(String? style) {
    final result = <String, String>{};
    if (style == null || style.isEmpty) return result;

    for (final pair in style.split(';')) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        result[parts[0].trim()] = parts[1].trim();
      }
    }
    return result;
  }

  vm.Matrix4 _parseTransform(String? transform) {
    if (transform == null || transform.isEmpty) {
      return vm.Matrix4.identity();
    }

    final matrix = vm.Matrix4.identity();
    final pattern = RegExp(r'(\w+)\s*\(([\d\s,.-]+)\)');
    for (final match in pattern.allMatches(transform)) {
      final command = match.group(1);
      final params = match
          .group(2)!
          .split(RegExp(r'[\s,]+'))
          .map(double.parse)
          .toList();

      switch (command) {
        case 'translate':
          final dx = params[0];
          final dy = params.length > 1 ? params[1] : 0.0;
          matrix.translate(dx, dy);
          break;
        case 'scale':
          final sx = params[0];
          final sy = params.length > 1 ? params[1] : sx;
          matrix.scale(sx, sy);
          break;
        case 'rotate':
          final angle = params[0] * math.pi / 180;
          if (params.length > 2) {
            final cx = params[1];
            final cy = params[2];
            matrix.translate(cx, cy);
            matrix.rotateZ(angle);
            matrix.translate(-cx, -cy);
          } else {
            matrix.rotateZ(angle);
          }
          break;
      }
    }
    return matrix;
  }

  Color? _parseColor(String? fill) {
    if (fill == null || fill == 'none') return null;
    if (fill.startsWith('#')) {
      final hexString = fill.substring(1);
      final value = int.tryParse(hexString, radix: 16);
      if (value != null) {
        // Renge alpha channel ekle (0xFF)
        // Renk formatı: 0xRRGGBB -> 0xFFRRGGBB (FF = tam opacity)
        return Color((value & 0xFFFFFF) | 0xFF000000);
      }
    }
    return Colors.black;
  }
}
