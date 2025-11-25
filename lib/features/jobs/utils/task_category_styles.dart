import 'package:flutter/material.dart';

import '../models/job_models.dart';

/// Helper utilities for styling task categories (Kaporta / Boya).
class TaskCategoryStyles {
  TaskCategoryStyles._();

  static Color containerColor(BuildContext context, TaskCategory category) {
    final scheme = Theme.of(context).colorScheme;
    switch (category) {
      case TaskCategory.kaporta:
        return scheme.tertiaryContainer;
      case TaskCategory.boya:
        return scheme.primaryContainer;
    }
  }

  static Color onContainerColor(BuildContext context, TaskCategory category) {
    final scheme = Theme.of(context).colorScheme;
    switch (category) {
      case TaskCategory.kaporta:
        return scheme.onTertiaryContainer;
      case TaskCategory.boya:
        return scheme.onPrimaryContainer;
    }
  }

  static String noteTitle(TaskCategory category) {
    switch (category) {
      case TaskCategory.kaporta:
        return 'Kaporta Notları';
      case TaskCategory.boya:
        return 'Boya Notları';
    }
  }

  static String noteMissingMessage(TaskCategory category) {
    switch (category) {
      case TaskCategory.kaporta:
        return 'Kaporta notu bulunamadı';
      case TaskCategory.boya:
        return 'Boya notu bulunamadı';
    }
  }
}
