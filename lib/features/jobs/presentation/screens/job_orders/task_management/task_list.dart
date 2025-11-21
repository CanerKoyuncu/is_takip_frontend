/// Task List Widget
///
/// Görev listesi widget'ı.

import 'package:flutter/material.dart';
import '../../../../models/job_models.dart';
import '../../../../../../core/widgets/empty_state.dart';
import 'task_card.dart';

/// Task list widget'ı
///
/// Görev listesini gösterir.
class TaskList extends StatelessWidget {
  const TaskList({
    super.key,
    required this.tasks,
    required this.jobId,
    required this.emptyMessage,
    this.isCompleted = false,
  });

  final List<JobTask> tasks;
  final String jobId;
  final String emptyMessage;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return EmptyState(message: emptyMessage, icon: Icons.task_outlined);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(task: task, jobId: jobId, isCompleted: isCompleted);
      },
    );
  }
}

