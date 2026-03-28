import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart' as xml;

import '../core/damage_action_styles.dart' as core_styles;
import '../models/vehicle_config.dart';

/// Custom SVG widget that uses path_drawing and xml packages
/// instead of flutter_svg to support specific interactivity and rendering requirements.
class CustomSvgPicture extends StatefulWidget {
  const CustomSvgPicture({
    super.key,
    required this.assetName,
    this.fit = BoxFit.contain,
    this.placeholder,
    this.errorBuilder,
    this.partColorMap,
    this.partActionsMap,
    this.interactableIds,
    this.onPartTapped,
  });

  final String assetName;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final Map<String, Color>? partColorMap;
  final Map<String, List<String>>? partActionsMap;
  final List<String>? interactableIds;
  final void Function(String partId)? onPartTapped;

  @override
  State<CustomSvgPicture> createState() => _CustomSvgPictureState();
}

class _CustomSvgPictureState extends State<CustomSvgPicture> {
  Future<ParsedSvg>? _parsedSvg;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  void _loadSvg() {
    _parsedSvg = CustomSvgCache.instance.load(widget.assetName);
  }

  @override
  void didUpdateWidget(covariant CustomSvgPicture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetName != widget.assetName) {
      _loadSvg();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ParsedSvg>(
      future: _parsedSvg,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'CustomSvgPicture failed to load ${widget.assetName}: ${snapshot.error}',
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
        return AspectRatio(
          aspectRatio: parsed.viewBox.width / parsed.viewBox.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widgetSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _handleTap(details, parsed, widgetSize),
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
          ),
        );
      },
    );
  }

  void _handleTap(TapUpDetails details, ParsedSvg svg, Size size) {
    if (widget.onPartTapped == null) return;

    final scale = _CustomSvgPainter.getScale(size, svg.viewBox, widget.fit);
    final offset = _CustomSvgPainter.getOffset(size, scale, svg.viewBox);

    final localPosition = details.localPosition;

    // Transform tap to SVG coordinates, accounting for viewBox origin
    final svgX = (localPosition.dx - offset.dx) / scale + svg.viewBox.left;
    final svgY = (localPosition.dy - offset.dy) / scale + svg.viewBox.top;
    final tapPoint = Offset(svgX, svgY);

    // Check matches in reversed order (topmost first)
    for (final shape in svg.shapes.reversed) {
      // Resolve IDs (try partId first, then groupId)
      final effectiveId =
          _resolveEffectiveId(shape.partId) ??
          _resolveEffectiveId(shape.groupId);

      if (effectiveId != null) {
        bool isHit = false;

        // 1. Standard contains check (works for filled paths and closed shapes)
        if (shape.path.contains(tapPoint)) {
          isHit = true;
        }

        // 2. If not hit, check for special closed shapes (like rects from SVG)
        if (!isHit) {
          if (_isKnownClosedShape(effectiveId) || _isPathClosed(shape.path)) {
            if (shape.path.getBounds().contains(tapPoint)) {
              if (shape.path.contains(tapPoint)) {
                isHit = true;
              }
            }
          }
        }

        // 3. If still not hit, check for strokes/lines with tolerance
        if (!isHit) {
          const tolerance = 20.0;
          if (_isPointNearPath(tapPoint, shape.path, tolerance)) {
            isHit = true;
          }
        }

        if (isHit) {
          widget.onPartTapped!(effectiveId);
          return;
        }
      }
    }
  }

  String? _resolveEffectiveId(String? technicalId) {
    if (technicalId == null || technicalId.isEmpty) return null;

    // 1. Get canonical ID from registry (handles aliases like path682 -> sag-orta-cam)
    final canonicalId = VehiclePartsRegistry.resolveId(technicalId);

    // 2. Check if canonical ID is interactable
    if (canonicalId != null &&
        (widget.interactableIds?.contains(canonicalId) ?? true)) {
      return canonicalId;
    }

    // 3. Fallback to technical ID if it's directly interactable
    if (widget.interactableIds?.contains(technicalId) ?? true) {
      return technicalId;
    }

    return null;
  }

  // Removed _getInteractiveId as logic is inside _handleTap

  // --- Hit Test Utilities (Ported from frontend) ---

  bool _isKnownClosedShape(String partId) {
    const closedShapeIds = {
      'sunroof',
      'yakit-depo-kapagi',
      'sol-on-kapi-kolu',
      'sol-arka-kapi-kolu',
      'sag-arka-kapi-kolu',
      'sag-on-kapi-kolu',
    };
    return closedShapeIds.contains(partId);
  }

  bool _isPathClosed(Path path) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      if (metric.length == 0) continue;
      final start = metric.getTangentForOffset(0)?.position;
      final end = metric.getTangentForOffset(metric.length)?.position;
      if (start != null && end != null && (start - end).distance < 1.0) {
        return true;
      }
    }

    // Heuristic: Area to perimeter ratio
    final bounds = path.getBounds();
    final area = bounds.width * bounds.height;
    if (area > 0) {
      double totalLength = 0;
      for (final metric in metrics) {
        totalLength += metric.length;
      }
      if (totalLength > 0 && area / totalLength > 5.0) return true;
    }
    return false;
  }

  bool _isPointNearPath(Offset point, Path path, double tolerance) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final length = metric.length;
      if (length == 0) continue;

      double minDistance = double.infinity;
      final sampleCount = math.min(math.max(10, (length / 10).ceil()), 100);

      for (int i = 0; i <= sampleCount; i++) {
        final t = (i * length / sampleCount).clamp(0.0, length);
        final pos = metric.getTangentForOffset(t)?.position;
        if (pos != null) {
          final dist = (point - pos).distance;
          if (dist < minDistance) minDistance = dist;
          if (minDistance <= tolerance) return true;
        }
      }
    }
    return false;
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
    if (size.isEmpty) return;

    final scale = getScale(size, svg.viewBox, fit);
    final offset = getOffset(size, scale, svg.viewBox);

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    canvas.translate(-svg.viewBox.left, -svg.viewBox.top);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black;

    for (final shape in svg.shapes) {
      // Determine which ID governs the style
      final styleId = _getStyleId(shape);

      final actions = styleId != null && partActionsMap != null
          ? partActionsMap![styleId]
          : null;

      if (actions != null && actions.length > 1) {
        // Draw striped pattern
        canvas.save();
        canvas.clipPath(shape.path);
        _drawStripedPattern(canvas, shape.path, actions, scale);
        canvas.restore();
      } else {
        Color? fillColor = shape.fillColor;

        if (styleId != null && partColorMap != null) {
          final mappedColor = partColorMap![styleId];
          if (mappedColor != null) {
            fillColor = mappedColor;
          }
        }

        if (fillColor != null && fillColor != Colors.transparent) {
          paint.color = fillColor;
          paint.style = PaintingStyle.fill;
          canvas.drawPath(shape.path, paint);
        }
      }

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

  String? _getStyleId(SvgShape shape) {
    return _findBestStyleId(shape.partId) ?? _findBestStyleId(shape.groupId);
  }

  String? _findBestStyleId(String? technicalId) {
    if (technicalId == null || technicalId.isEmpty) return null;

    final resolvedId = VehiclePartsRegistry.resolveId(technicalId);
    if (resolvedId != null &&
        (partColorMap?.containsKey(resolvedId) == true ||
            partActionsMap?.containsKey(resolvedId) == true)) {
      return resolvedId;
    }

    if (partColorMap?.containsKey(technicalId) == true ||
        partActionsMap?.containsKey(technicalId) == true) {
      return technicalId;
    }

    return null;
  }

  void _drawStripedPattern(
    Canvas canvas,
    Path path,
    List<String> actions,
    double scale,
  ) {
    if (actions.isEmpty) return;

    final bounds = path.getBounds();
    final stripeWidth = (15.0 / scale).clamp(2.0, 20.0);

    // First action as background fill
    if (actions.isNotEmpty) {
      final firstAction = actions[0];
      final firstStyle = damageActionStyle(firstAction);
      final firstColor = firstStyle?.color;

      if (firstColor != null) {
        final fillPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = firstColor.withValues(alpha: 1.0)
          ..isAntiAlias = true;
        canvas.drawPath(path, fillPaint);
      }
    }

    final spacing = stripeWidth * 2;

    for (int i = 1; i < actions.length; i++) {
      final action = actions[i];
      final style = damageActionStyle(action);
      final color = style?.color;
      if (style == null || color == null) continue;

      final stripePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = color.withValues(alpha: 1.0)
        ..strokeWidth = stripeWidth
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter
        ..isAntiAlias = true;

      final isVertical = i % 2 == 1;

      if (isVertical) {
        final startX = bounds.left + (stripeWidth / 2);
        for (double x = startX; x <= bounds.right + spacing; x += spacing) {
          final linePath = Path();
          linePath.moveTo(x, bounds.top);
          linePath.lineTo(x, bounds.bottom);
          canvas.drawPath(linePath, stripePaint);
        }
      } else {
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

  static double getScale(Size size, Rect viewBox, BoxFit fit) {
    final scaleX = size.width / viewBox.width;
    final scaleY = size.height / viewBox.height;

    switch (fit) {
      case BoxFit.fill:
        return math.max(scaleX, scaleY); // Actually usually independent
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

  static Offset getOffset(Size size, double scale, Rect viewBox) {
    final scaledWidth = viewBox.width * scale;
    final scaledHeight = viewBox.height * scale;
    final dx = (size.width - scaledWidth) / 2;
    final dy = (size.height - scaledHeight) / 2;
    return Offset(dx, dy);
  }

  static core_styles.DamageActionStyle? damageActionStyle(String action) {
    return core_styles.damageActionStyle(action);
  }

  @override
  bool shouldRepaint(covariant _CustomSvgPainter oldDelegate) {
    return oldDelegate.svg != svg ||
        oldDelegate.fit != fit ||
        !mapEquals(oldDelegate.partColorMap, partColorMap) ||
        !mapEquals(oldDelegate.partActionsMap, partActionsMap);
  }
}

class ParsedSvg {
  ParsedSvg({required this.viewBox, required this.shapes});
  final Rect viewBox;
  final List<SvgShape> shapes;
}

class SvgShape {
  SvgShape({
    required this.path,
    this.fillColor,
    this.strokeColor,
    this.strokeWidth,
    this.partId,
    this.groupId,
  });

  final Path path;
  final Color? fillColor;
  final Color? strokeColor;
  final double? strokeWidth;

  /// The specific ID of this SVG element (e.g. path id)
  final String? partId;

  /// The ID of the parent group (e.g. g id) representing the logical part
  final String? groupId;
}

class DamageActionStyle {
  DamageActionStyle({required this.color});
  final Color color;
}

/// Cache for parsed SVG files
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
    final svgElement = document.rootElement;
    final viewBox = _parseViewBox(svgElement.getAttribute('viewBox'));

    final shapes = <SvgShape>[];
    _parseChildren(svgElement, Matrix4.identity(), shapes, null);

    return ParsedSvg(viewBox: viewBox, shapes: shapes);
  }

  Rect _parseViewBox(String? viewBox) {
    if (viewBox == null || viewBox.isEmpty) return Rect.zero;
    final parts = viewBox
        .split(RegExp(r'[\s,]+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length < 4) return Rect.zero;
    return Rect.fromLTWH(
      double.parse(parts[0]),
      double.parse(parts[1]),
      double.parse(parts[2]),
      double.parse(parts[3]),
    );
  }

  void _parseChildren(
    xml.XmlElement element,
    Matrix4 transform,
    List<SvgShape> shapes,
    String? activePartId, {
    Color? inheritedFillColor,
    Color? inheritedStrokeColor,
  }) {
    final elementId = element.getAttribute('id');
    final isGroup = element.name.local == 'g';

    String? nextPartId = activePartId;
    if (isGroup && elementId != null && elementId.isNotEmpty) {
      nextPartId = elementId;
    }

    final localTransform = _parseTransform(element.getAttribute('transform'));
    final combinedTransform = Matrix4.copy(transform)..multiply(localTransform);
    final styleAttrs = _parseStyleAttribute(element.getAttribute('style'));

    // Determine effective colors for this element (and potential inheritance)
    Color? currentFillColor = _parseColor(
      styleAttrs['fill'] ?? element.getAttribute('fill'),
    );
    Color? currentStrokeColor = _parseColor(
      styleAttrs['stroke'] ?? element.getAttribute('stroke'),
    );

    // If current element doesn't specify color, use inherited
    final effectiveFillColor = currentFillColor ?? inheritedFillColor;
    final effectiveStrokeColor = currentStrokeColor ?? inheritedStrokeColor;

    Path? path;
    if (element.name.local == 'path') {
      final d = element.getAttribute('d');
      if (d != null && d.isNotEmpty) path = parseSvgPathData(d);
    } else if (element.name.local == 'rect') {
      path = _parseRect(element);
    } else if (element.name.local == 'circle') {
      path = _parseCircle(element);
    } else if (element.name.local == 'ellipse') {
      path = _parseEllipse(element);
    }

    if (path != null) {
      final transformedPath = path.transform(combinedTransform.storage);

      double? strokeWidth = double.tryParse(
        styleAttrs['stroke-width'] ??
            element.getAttribute('stroke-width') ??
            '0',
      );

      String? shapePartId = elementId;
      // Note: We deliberately do NOT default shapePartId to nextPartId (groupId) here
      // anymore, because we want to distinguish them.
      // If the path has no ID, shapePartId is null.
      // We pass nextPartId as 'groupId'.

      shapes.add(
        SvgShape(
          path: transformedPath,
          fillColor: effectiveFillColor,
          strokeColor: effectiveStrokeColor,
          strokeWidth: strokeWidth,
          partId: shapePartId,
          groupId: nextPartId,
        ),
      );
    }

    for (final child in element.children.whereType<xml.XmlElement>()) {
      _parseChildren(
        child,
        combinedTransform,
        shapes,
        nextPartId,
        inheritedFillColor: effectiveFillColor,
        inheritedStrokeColor: effectiveStrokeColor,
      );
    }
  }

  Path? _parseRect(xml.XmlElement element) {
    final x = double.tryParse(element.getAttribute('x') ?? '0') ?? 0;
    final y = double.tryParse(element.getAttribute('y') ?? '0') ?? 0;
    final width = double.tryParse(element.getAttribute('width') ?? '0');
    final height = double.tryParse(element.getAttribute('height') ?? '0');
    final rx = double.tryParse(element.getAttribute('rx') ?? '0') ?? 0;
    final ry = double.tryParse(element.getAttribute('ry') ?? '0') ?? rx;

    if (width != null && height != null && width > 0 && height > 0) {
      final rect = Rect.fromLTWH(x, y, width, height);
      if (rx > 0 || ry > 0) {
        return Path()
          ..addRRect(RRect.fromRectXY(rect, rx, ry))
          ..close();
      } else {
        return Path()
          ..addRect(rect)
          ..close();
      }
    }
    return null;
  }

  Path? _parseCircle(xml.XmlElement element) {
    final cx = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
    final cy = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
    final r = double.tryParse(element.getAttribute('r') ?? '0');
    if (r != null && r > 0) {
      return Path()
        ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r))
        ..close();
    }
    return null;
  }

  Path? _parseEllipse(xml.XmlElement element) {
    final cx = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
    final cy = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
    final rx = double.tryParse(element.getAttribute('rx') ?? '0');
    final ry = double.tryParse(element.getAttribute('ry') ?? '0');
    if (rx != null && ry != null && rx > 0 && ry > 0) {
      return Path()
        ..addOval(Rect.fromLTWH(cx - rx, cy - ry, rx * 2, ry * 2))
        ..close();
    }
    return null;
  }

  Map<String, String> _parseStyleAttribute(String? style) {
    if (style == null || style.isEmpty) return {};
    final result = <String, String>{};
    for (final pair in style.split(';')) {
      final parts = pair.split(':');
      if (parts.length == 2) result[parts[0].trim()] = parts[1].trim();
    }
    return result;
  }

  Matrix4 _parseTransform(String? transform) {
    if (transform == null || transform.isEmpty) return Matrix4.identity();
    final matrix = Matrix4.identity();
    final pattern = RegExp(r'(\w+)\s*\(([\d\s,.-]+)\)');

    for (final match in pattern.allMatches(transform)) {
      final command = match.group(1);
      final params = match
          .group(2)!
          .split(RegExp(r'[\s,]+'))
          .where((s) => s.isNotEmpty)
          .map(double.parse)
          .toList();

      switch (command) {
        case 'translate':
          final dx = params[0];
          final dy = params.length > 1 ? params[1] : 0.0;
          matrix.multiply(Matrix4.identity()..setTranslationRaw(dx, dy, 0.0));
          break;
        case 'scale':
          final sx = params[0];
          final sy = params.length > 1 ? params[1] : sx;
          matrix.multiply(Matrix4.diagonal3Values(sx, sy, 1.0));
          break;
        case 'rotate':
          final angle = params[0] * math.pi / 180;
          if (params.length > 2) {
            final cx = params[1];
            final cy = params[2];
            matrix.multiply(Matrix4.identity()..setTranslationRaw(cx, cy, 0.0));
            matrix.rotateZ(angle);
            matrix.multiply(
              Matrix4.identity()..setTranslationRaw(-cx, -cy, 0.0),
            );
          } else {
            matrix.rotateZ(angle);
          }
          break;
        case 'matrix':
          if (params.length >= 6) {
            final a = params[0];
            final b = params[1];
            final c = params[2];
            final d = params[3];
            final e = params[4];
            final f = params[5];

            matrix.multiply(
              Matrix4(
                a,
                b,
                0.0,
                0.0,
                c,
                d,
                0.0,
                0.0,
                0.0,
                0.0,
                1.0,
                0.0,
                e,
                f,
                0.0,
                1.0,
              ),
            );
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
        if (hexString.length == 3) {
          // #RGB -> #RRGGBB not supported directly by simple parse used here usually,
          // but standard SVG parsers handle it. Inkscape usually outputs 6 digits.
          // If needed we can expand.
        }
        return Color((value & 0xFFFFFF) | 0xFF000000);
      }
    }
    return Colors
        .black; // Default fallback if parse fails but not null? Or maybe null.
  }
}
