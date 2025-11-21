/// Status Badge Widget
///
/// Job ve task status badge'leri için standart widget.
/// Durum gösterimi için kullanılır.
library;

import 'package:flutter/material.dart';
import '../models/job_models.dart';

/// Job status badge widget'ı
///
/// İş emri durumunu badge olarak gösterir.
class JobStatusBadge extends StatelessWidget {
  const JobStatusBadge({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius,
  });

  /// Job status
  final JobStatus status;

  /// Padding (varsayılan: horizontal 12, vertical 8)
  final EdgeInsets padding;

  /// Border radius (varsayılan: 8)
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: status.toColor(context),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: status.onColor(context),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Task status badge widget'ı
///
/// Görev durumunu badge olarak gösterir.
class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.borderRadius,
  });

  /// Task status
  final JobTaskStatus status;

  /// Padding (varsayılan: horizontal 10, vertical 6)
  final EdgeInsets padding;

  /// Border radius (varsayılan: 12)
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: status.toColor(context),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: status.onColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
