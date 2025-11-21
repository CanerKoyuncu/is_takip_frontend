/// Vehicle Canvas Layout
///
/// Araç hasar haritası için canvas layout hesaplama sınıfı.
/// SVG koordinatlarını ekran koordinatlarına dönüştürür.

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../models/vehicle_area.dart';

/// Vehicle canvas layout sınıfı
///
/// SVG koordinatlarını ekran koordinatlarına dönüştürür.
class VehicleCanvasLayout {
  VehicleCanvasLayout._(this.bounds, this.scale, this.translation);

  factory VehicleCanvasLayout.from(
    Size size,
    List<VehiclePart> parts, {
    Rect? boundsHint,
  }) {
    assert(parts.isNotEmpty, 'At least one vehicle part is required.');

    if (parts.isEmpty) {
      throw ArgumentError('Parts list cannot be empty');
    }

    Rect bounds = boundsHint ?? parts.first.bounds;

    // Validate initial bounds
    if (bounds.isEmpty || bounds.width <= 0 || bounds.height <= 0) {
      debugPrint(
        '[VehicleCanvasLayout] Warning: Invalid initial bounds: $bounds, '
        'using first part: ${parts.first.id}',
      );
      // Try to find a valid bounds from parts
      bounds = parts
          .firstWhere(
            (p) =>
                !p.bounds.isEmpty && p.bounds.width > 0 && p.bounds.height > 0,
            orElse: () => parts.first,
          )
          .bounds;
    }

    if (boundsHint == null) {
      for (final part in parts.skip(1)) {
        if (!part.bounds.isEmpty &&
            part.bounds.width > 0 &&
            part.bounds.height > 0) {
          bounds = bounds.expandToInclude(part.bounds);
        }
      }
    }

    final widthScale = size.width / bounds.width;
    final heightScale = size.height / bounds.height;
    final scale = math.min(widthScale, heightScale);

    final translatedWidth = bounds.width * scale;
    final translatedHeight = bounds.height * scale;

    final translation = Offset(
      (size.width - translatedWidth) / 2,
      (size.height - translatedHeight) / 2,
    );

    debugPrint(
      '[VehicleCanvasLayout] Initialized: size=$size, bounds=$bounds, '
      'scale=$scale, translation=$translation',
    );

    return VehicleCanvasLayout._(bounds, scale, translation);
  }

  final Rect bounds;
  final double scale;
  final Offset translation;

  Offset toArtboard(Offset point) {
    final offset = point - translation;
    final result = Offset(
      offset.dx / scale + bounds.left,
      offset.dy / scale + bounds.top,
    );
    debugPrint(
      '[VehicleCanvasLayout] toArtboard: screen=$point -> artboard=$result',
    );
    return result;
  }
}
