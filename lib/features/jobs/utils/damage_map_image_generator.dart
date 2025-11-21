/// Hasar Haritası Görsel Oluşturucu
///
/// Bu sınıf, hasar haritasını SVG'den direkt olarak PNG görseline dönüştürür.
/// BuildContext gerektirmez - Canvas ve PictureRecorder kullanır.
///
/// Kullanım Alanları:
/// - PDF raporlarına hasar haritası ekleme
/// - Hasar haritasını görsel olarak paylaşma
/// - Raporlama ve dokümantasyon
///
/// Özellikler:
/// - SVG'den direkt görsel oluşturma
/// - Seçilen parçaları renklendirme
/// - Ölçeklendirme ve dönüştürme
/// - PNG formatında çıktı

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../models/vehicle_area.dart';
import '../presentation/widgets/custom_svg_picture.dart';
import 'damage_action_styles.dart';

/// Hasar haritası görsel oluşturucu sınıfı
///
/// Singleton pattern kullanır - tek bir instance oluşturulur.
/// SVG'den PNG görseli oluşturur.
class DamageMapImageGenerator {
  // Private constructor - singleton pattern
  DamageMapImageGenerator._();
  // Singleton instance
  static final DamageMapImageGenerator instance = DamageMapImageGenerator._();

  /// Hasar haritasını PNG görsel bytes'ına dönüştürür
  ///
  /// SVG'den direkt olarak PNG görseli oluşturur.
  /// BuildContext gerektirmez - Canvas ve PictureRecorder kullanır.
  ///
  /// İşlem Adımları:
  /// 1. SVG dosyasını yükler
  /// 2. Canvas üzerinde SVG'yi çizer
  /// 3. Seçilen parçaları renklendirir (hasar overlay'leri)
  /// 4. Canvas'ı PNG bytes'ına dönüştürür
  ///
  /// Parametreler:
  /// - parts: Araç parçaları listesi
  /// - selections: Seçilen parça ve işlemler (partId -> [action1, action2])
  /// - svgAssetName: SVG dosya yolu (varsayılan: 'assets/car-cutout-grouped.svg')
  /// - size: Çıktı görsel boyutu (varsayılan: 600x400)
  ///
  /// Döner: Future<Uint8List?> - PNG görsel bytes'ı veya null (hata durumunda)
  Future<Uint8List?> generateDamageMapImage({
    required List<VehiclePart> parts,
    required Map<String, List<String>> selections,
    String svgAssetName = 'assets/car-cutout-grouped.svg',
    Size size = const Size(600, 400),
  }) async {
    try {
      // SVG dosyasını yükle
      final parsedSvg = await CustomSvgCache.instance.load(svgAssetName);

      // Layout hesapla - UI'daki _VehicleCanvasLayout ile aynı mantık
      // SVG viewBox'ı bounds olarak kullan (UI'da GroupedSvgPicture viewBox kullanır)
      final svgViewBox = parsedSvg.viewBox;
      const defaultArtboard = Rect.fromLTWH(0, 0, 1668, 1160);

      // SVG viewBox'ı primary bounds olarak kullan, geçersizse varsayılan artboard kullan
      Rect bounds = svgViewBox.width > 0 && svgViewBox.height > 0
          ? svgViewBox
          : defaultArtboard;

      // Ölçek ve öteleme hesapla (_VehicleCanvasLayout.from ile aynı)
      final widthScale = size.width / bounds.width;
      final heightScale = size.height / bounds.height;
      final scale = math.min(widthScale, heightScale); // Aspect ratio koru

      final translatedWidth = bounds.width * scale;
      final translatedHeight = bounds.height * scale;

      // Ortalama için öteleme hesapla
      final translation = Offset(
        (size.width - translatedWidth) / 2,
        (size.height - translatedHeight) / 2,
      );

      // Çizim için PictureRecorder oluştur
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Beyaz arka plan çiz
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      // UI ile aynı şekilde çiz: SVG ve hasar overlay'leri aynı transform kullanır
      canvas.save();
      canvas.translate(translation.dx, translation.dy);
      canvas.scale(scale);
      canvas.translate(-bounds.left, -bounds.top);

      // Build part color map for SVG fill coloring
      // Only set fill color for single action parts
      // For multiple actions, set transparent to prevent SVG default fill
      final partColorMap = <String, Color>{};
      for (final part in parts) {
        final normalizedActions = _normalizedActions(selections[part.id]);
        if (normalizedActions.length == 1) {
          // Single action: use the action color
          final color = _baseColorForActions(normalizedActions);
          partColorMap[part.id] = color;
        } else if (normalizedActions.length > 1) {
          // Multiple actions: set transparent to prevent SVG default fill
          // Striped pattern will be drawn on top
          partColorMap[part.id] = Colors.transparent;
        }
      }

      // SVG arka planını çiz (hasar overlay'leri ile aynı transform)
      // Fill renklendirmesi artık SVG içinde yapılıyor
      _drawSvgTransformed(canvas, parsedSvg, bounds, partColorMap);

      // Hasar haritası overlay'lerini üstüne çiz (sadece stroke ve striped pattern)
      _drawDamageMap(
        canvas,
        parts,
        selections,
        scale,
        drawFill: false,
        drawOutline: false,
      );

      canvas.restore();

      // Görsele dönüştür
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      // PNG bytes'ına dönüştür
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose(); // Memory temizle

      if (byteData == null) {
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Damage map image generation error: $e');
      return null;
    }
  }

  /// SVG arka planını çizer (private metod)
  ///
  /// Hasar overlay'leri ile aynı transform'u kullanır.
  /// SVG viewBox transform'unu uygular (_CustomSvgPainter ile aynı).
  ///
  /// Parametreler:
  /// - canvas: Çizim canvas'ı
  /// - svg: Parse edilmiş SVG
  /// - bounds: Sınırlayıcı dikdörtgen
  /// - partColorMap: Part ID -> Color mapping for fill coloring
  void _drawSvgTransformed(
    Canvas canvas,
    ParsedSvg svg,
    Rect bounds,
    Map<String, Color>? partColorMap,
  ) {
    // SVG viewBox transform'unu uygula (_GroupedSvgPainter ile aynı)
    // Canvas zaten bounds koordinat sistemine transform edilmiş
    // Şimdi viewBox offset'ini uygula
    canvas.save();
    canvas.translate(-svg.viewBox.left, -svg.viewBox.top);

    // SVG şekillerini çiz
    final paint = Paint();
    for (final shape in svg.shapes) {
      // Fill color varsa fill olarak çiz
      // Eğer partColorMap'te bu part için renk varsa onu kullan
      Color? fillColor = shape.fillColor;
      if (shape.partId != null && partColorMap != null) {
        final mappedColor = partColorMap[shape.partId];
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

  /// Draws damage map overlays exactly like _VehiclePartsPainter does in UI
  void _drawDamageMap(
    Canvas canvas,
    List<VehiclePart> parts,
    Map<String, List<String>> selections,
    double scale, {
    bool drawFill = true,
    bool drawOutline = true,
  }) {
    // Same logic as _VehiclePartsPainter.paint()
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.grey
          .withValues(alpha: 0.5) // Same as colorScheme.outline
      ..strokeWidth = 2 / scale;

    // Draw parts in SVG order (first to last) to maintain proper elevation
    // Parts list is already in SVG order, so we draw them sequentially
    // This ensures that parts drawn later in SVG (higher elevation) are drawn on top
    for (final part in parts) {
      final normalizedActions = _normalizedActions(selections[part.id]);

      // Base fill color (only if drawFill is true)
      if (drawFill) {
        fillPaint.color = _baseColorForActions(normalizedActions);
        canvas.drawPath(part.path, fillPaint);
      }

      // Draw stroke (outline) if enabled
      if (drawOutline) {
        canvas.drawPath(part.path, strokePaint);
      }

      // If multiple actions, draw striped pattern with all colors
      // (always draw striped pattern for multiple actions, even if drawFill is false)
      // Draw after fill and stroke to ensure proper elevation
      if (normalizedActions.length > 1) {
        _drawStripedPattern(canvas, part.path, normalizedActions, scale);
      }
    }
  }

  /// Gets color for part based on actions (same as _VehiclePartsPainter._colorForPart)
  Color _baseColorForActions(List<String> actions) {
    if (actions.isEmpty) {
      return Colors.white.withValues(alpha: 0.6); // Same as UI
    }

    return damageActionColor(actions.first) ?? Colors.white; // Same as UI
  }

  List<String> _normalizedActions(List<String>? actions) {
    if (actions == null || actions.isEmpty) {
      return const <String>[];
    }

    final normalized = <String>[];
    for (final action in damageActionPriority) {
      if (actions.contains(action)) {
        normalized.add(action);
      }
    }
    return normalized;
  }

  /// Draws pattern for multiple actions
  /// First color is used as fill, other colors are drawn as path outlines (strokes)
  void _drawStripedPattern(
    Canvas canvas,
    Path path,
    List<String> actions,
    double scale,
  ) {
    if (actions.isEmpty) return;

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

    // Other actions: draw as path outlines (strokes) on top
    // Stroke width scales with zoom level
    final strokeWidth = (3.0 / scale).clamp(2.0, 8.0);

    for (int i = 1; i < actions.length; i++) {
      final action = actions[i];
      final style = damageActionStyle(action);
      final color = style?.color;
      if (style == null || color == null) continue;

      // Enhanced color for better visibility
      final hsvColor = HSVColor.fromColor(color);
      final enhancedColor = hsvColor
          .withSaturation((hsvColor.saturation * 1.3).clamp(0.0, 1.0))
          .withValue((hsvColor.value * 1.1).clamp(0.0, 1.0))
          .toColor();

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = enhancedColor.withValues(alpha: 1.0)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

      // Draw the path outline in this color
      canvas.drawPath(path, strokePaint);
        }
  }
}
