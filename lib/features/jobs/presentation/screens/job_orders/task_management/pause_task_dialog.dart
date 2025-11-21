/// Pause Task Dialog
///
/// Görevi duraklatma dialog'u.

import 'package:flutter/material.dart';
import '../../../../models/job_models.dart';
import '../../../../models/vehicle_area.dart';

/// Pause task dialog widget'ı
///
/// Kullanıcıya görevi duraklatma seçeneği sunar.
class PauseTaskDialog extends StatefulWidget {
  const PauseTaskDialog({super.key, required this.task});

  final JobTask task;

  @override
  State<PauseTaskDialog> createState() => _PauseTaskDialogState();
}

class _PauseTaskDialogState extends State<PauseTaskDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Görevi Duraklat'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.task.area.label} - ${widget.task.operationType.label}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Görev duraklatılacak. Mevcut çalışma oturumu kaydedilecek.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Duraklatma Notu (Opsiyonel)',
                hintText: 'Duraklatma nedeni...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
          onPressed: () {
            Navigator.of(context).pop(
              _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Duraklat'),
        ),
      ],
    );
  }
}
