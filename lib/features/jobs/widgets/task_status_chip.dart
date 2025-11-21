/// Task Status Chip Widget
///
/// Görev durumu için chip widget'ı.
/// Daha kompakt gösterim için kullanılır.
library;

import 'package:flutter/material.dart';
import '../models/job_models.dart';

/// Task status chip widget'ı
///
/// Görev durumunu chip olarak gösterir.
class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({
    super.key,
    required this.status,
    this.size = ChipSize.medium,
  });

  /// Task status
  final JobTaskStatus status;

  /// Chip boyutu
  final ChipSize size;

  @override
  Widget build(BuildContext context) {
    final textStyle = size == ChipSize.small
        ? Theme.of(context).textTheme.labelSmall
        : Theme.of(context).textTheme.labelMedium;

    final padding = size == ChipSize.small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: status.toColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: textStyle?.copyWith(
          color: status.onColor(context),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Chip boyutu enum'ı
enum ChipSize { small, medium, large }
