/// Update Task Status Dialog
///
/// Görev durumunu güncelleme dialog'u.

import 'package:flutter/material.dart';
import '../../../../models/job_models.dart';
import '../../../../models/vehicle_area.dart';

/// Update task status dialog widget'ı
///
/// Kullanıcıya görev durumunu güncelleme seçeneği sunar.
class UpdateTaskStatusDialog extends StatefulWidget {
  const UpdateTaskStatusDialog({super.key, required this.task});

  final JobTask task;

  @override
  State<UpdateTaskStatusDialog> createState() => _UpdateTaskStatusDialogState();
}

class _UpdateTaskStatusDialogState extends State<UpdateTaskStatusDialog> {
  TaskBlockingReason? _selectedBlockingReason;
  bool _isTaskAvailable = true;

  @override
  void initState() {
    super.initState();
    _selectedBlockingReason = widget.task.blockingReason;
    _isTaskAvailable = widget.task.isTaskAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Görev Durumunu Güncelle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.task.area.label} - ${widget.task.operationType.label}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 24),
            // Engelleme nedeni seçimi
            Text(
              'Engelleme Nedeni',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            ...TaskBlockingReason.values.map((reason) {
              return RadioListTile<TaskBlockingReason>(
                title: Row(
                  children: [
                    Icon(reason.icon, size: 20),
                    const SizedBox(width: 8),
                    Text(reason.label),
                  ],
                ),
                value: reason,
                groupValue: _selectedBlockingReason,
                onChanged: (value) {
                  setState(() {
                    _selectedBlockingReason = value;
                  });
                },
                dense: true,
              );
            }),
            RadioListTile<TaskBlockingReason?>(
              title: const Text('Yok (Temizle)'),
              value: null,
              groupValue: _selectedBlockingReason,
              onChanged: (value) {
                setState(() {
                  _selectedBlockingReason = null;
                });
              },
              dense: true,
            ),
            const SizedBox(height: 24),
            // Görev çalışılabilirlik durumu
            Text('Görev Durumu', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Görev üzerinde çalışılabilir'),
              subtitle: Text(
                _isTaskAvailable
                    ? 'Bu görev üzerinde çalışılabilir'
                    : 'Bu görev üzerinde çalışılamaz',
              ),
              value: _isTaskAvailable,
              onChanged: (value) {
                setState(() {
                  _isTaskAvailable = value;
                });
              },
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
            Navigator.of(context).pop({
              'blockingReason': _selectedBlockingReason,
              'isTaskAvailable': _isTaskAvailable,
            });
          },
          child: const Text('Güncelle'),
        ),
      ],
    );
  }
}
