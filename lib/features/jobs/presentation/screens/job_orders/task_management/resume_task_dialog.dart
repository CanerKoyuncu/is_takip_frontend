/// Resume Task Dialog
///
/// Görevi devam ettirme dialog'u.

import 'package:flutter/material.dart';
import '../../../../models/job_models.dart';
import '../../../../models/vehicle_area.dart';
import '../../../../presentation/widgets/worker_select_dialog.dart';

/// Resume task dialog widget'ı
///
/// Kullanıcıya görevi devam ettirme seçeneği sunar.
/// Devam ettirecek usta seçimi yapılır.
class ResumeTaskDialog extends StatelessWidget {
  const ResumeTaskDialog({super.key, required this.task});

  final JobTask task;

  static Future<String?> show(BuildContext context, JobTask task) async {
    return await showDialog<String?>(
      context: context,
      builder: (context) => ResumeTaskDialog(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Görevi Devam Ettir'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${task.area.label} - ${task.operationType.label}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Görevi devam ettirecek usta seçin. Farklı bir usta seçebilirsiniz.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () async {
            // Usta seçim dialogunu aç
            final selectedWorker = await WorkerSelectDialog.show(
              context,
              kioskMode: false,
            );

            if (selectedWorker != null && context.mounted) {
              Navigator.of(context).pop(selectedWorker.id);
            }
          },
          child: const Text('Usta Seç'),
        ),
      ],
    );
  }
}
