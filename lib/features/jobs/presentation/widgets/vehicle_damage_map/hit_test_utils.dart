/// Hit Test Utilities
///
/// Araç parçaları için hit test yardımcı fonksiyonları.
/// Path'lerin tıklanabilirliğini kontrol eder.

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Hit test utility fonksiyonları
class HitTestUtils {
  HitTestUtils._();

  /// Checks if a part ID is a known closed shape (rect, circle from SVG)
  /// These shapes are always closed even if they have fill:none
  static bool isKnownClosedShape(String partId) {
    // Parts that come from SVG rect or circle elements
    // These are always closed shapes
    const closedShapeIds = {
      'sunroof', // rect element
      // Add other rect/circle parts here if needed
    };
    return closedShapeIds.contains(partId);
  }

  /// Checks if a path is closed (forms a closed shape like rect, circle, etc.)
  /// This helps distinguish between closed shapes (sunroof) and open paths (tavan)
  static bool isPathClosed(Path path) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      if (metric.length == 0) continue;

      // Get start and end points
      final startTangent = metric.getTangentForOffset(0);
      final endTangent = metric.getTangentForOffset(metric.length);

      if (startTangent != null && endTangent != null) {
        final start = startTangent.position;
        final end = endTangent.position;
        // If start and end points are very close, path is closed
        final distance = (start - end).distance;
        if (distance < 1.0) {
          return true;
        }
      }
    }

    // Also check if path bounds area is significant compared to path length
    // Closed shapes typically have larger area-to-perimeter ratio
    final bounds = path.getBounds();
    final boundsArea = bounds.width * bounds.height;
    if (boundsArea > 0) {
      final metrics = path.computeMetrics();
      double totalLength = 0;
      for (final metric in metrics) {
        totalLength += metric.length;
      }
      // For closed shapes, area should be significant relative to perimeter
      // This is a heuristic - adjust threshold as needed
      if (totalLength > 0 && boundsArea / totalLength > 5.0) {
        return true;
      }
    }

    return false;
  }

  /// Checks if a point is near a path (within tolerance distance)
  /// This is used for hit testing open/stroke paths that don't have a fill area
  static bool isPointNearPath(Offset point, Path path, double tolerance) {
    // Get path metrics to iterate through path segments
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      final length = metric.length;
      if (length == 0) continue;

      // Use binary search to find the closest point on the path
      double minDistance = double.infinity;

      // Adaptive sampling based on path length
      // More samples for longer paths
      final sampleCount = math.min(math.max(10, (length / 10).ceil()), 200);

      for (int i = 0; i <= sampleCount; i++) {
        final t = (i * length / sampleCount).clamp(0.0, length);
        final tangent = metric.getTangentForOffset(t);
        if (tangent == null) continue;

        final pathPoint = tangent.position;
        final distance = (point - pathPoint).distance;
        minDistance = math.min(minDistance, distance);

        // Early exit if we find a point within tolerance
        if (minDistance <= tolerance) {
          return true;
        }
      }

      // If we got close enough on this metric, accept it
      if (minDistance <= tolerance) {
        return true;
      }
    }

    return false;
  }
}
