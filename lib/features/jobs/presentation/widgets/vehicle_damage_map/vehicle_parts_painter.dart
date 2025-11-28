/// Vehicle Parts Painter
///
/// Araç parçalarını çizen custom painter.
/// Seçilen parçaları renklendirir ve çizgili desenler çizer.

import 'package:flutter/material.dart';
import '../../../models/vehicle_area.dart';
import '../../../utils/damage_action_styles.dart';
import 'vehicle_canvas_layout.dart';

/// Vehicle parts painter sınıfı
///
/// Araç parçalarını çizer ve seçilen parçaları renklendirir.
class VehiclePartsPainter extends CustomPainter {
  VehiclePartsPainter({
    required this.parts,
    required this.selections,
    required this.layout,
    required this.colorScheme,
    this.selectedPartId,
    this.drawFill = true,
    this.drawOutline = true,
  });

  final List<VehiclePart> parts;
  final VehiclePartSelections selections;
  final VehicleCanvasLayout layout;
  final ColorScheme colorScheme;
  final String? selectedPartId;
  final bool drawFill; // If false, only draw strokes (fill is done in SVG)
  final bool drawOutline;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(layout.translation.dx, layout.translation.dy);
    canvas.scale(layout.scale);
    canvas.translate(-layout.bounds.left, -layout.bounds.top);

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = colorScheme.outline
      ..strokeWidth = 2 / layout.scale;
    final selectedFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = colorScheme.primary.withValues(alpha: 0.2);

    // Draw parts in SVG order (first to last) to maintain proper elevation
    // Parts list is already in SVG order, so we draw them sequentially
    // This ensures that parts drawn later in SVG (higher elevation) are drawn on top
    for (final part in parts) {
      final isSelected = selectedPartId == part.id;
      final rawActions = selections[part.id];
      final normalizedActions = _normalizedActions(rawActions);

      // Base fill color (only if drawFill is true)
      if (drawFill) {
        fillPaint.color = _baseColorForActions(normalizedActions);
        canvas.drawPath(part.path, fillPaint);
      }

      // Draw stroke (outline) if enabled
      if (drawOutline) {
        canvas.drawPath(part.path, strokePaint);
      }

      // Striped patterns are now drawn as SVG fill, so we don't draw them here
      // (removed to prevent double drawing)

      // Draw selection highlight last to ensure it's on top
      if (isSelected) {
        canvas.drawPath(part.path, selectedFillPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VehiclePartsPainter oldDelegate) {
    return oldDelegate.parts != parts ||
        oldDelegate.selections != selections ||
        oldDelegate.layout.scale != layout.scale ||
        oldDelegate.layout.translation != layout.translation ||
        oldDelegate.selectedPartId != selectedPartId ||
        oldDelegate.drawFill != drawFill ||
        oldDelegate.drawOutline != drawOutline;
  }

  List<String> _normalizedActions(List<String>? actions) {
    if (actions == null || actions.isEmpty) {
      return const <String>[];
    }

    final normalized = List<String>.from(actions);
    normalized.sort(
      (a, b) =>
          damageActionPriorityIndex(a).compareTo(damageActionPriorityIndex(b)),
    );
    return normalized;
  }

  Color _baseColorForActions(List<String> actions) {
    if (actions.isEmpty) {
      return Colors.white.withValues(alpha: 0.6);
    }
    final color = damageActionColor(actions.first);
    return color ?? Colors.white;
  }
}
