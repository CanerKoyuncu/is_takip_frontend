/// Complete Task Dialog
///
/// Görevi tamamlama dialog'u.
library;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/job_models.dart';
import '../../../../models/vehicle_area.dart';

/// Complete task dialog widget'ı
///
/// Kullanıcıya görevi tamamlama seçeneği sunar.
class CompleteTaskDialog extends StatefulWidget {
  const CompleteTaskDialog({super.key, required this.task});

  final JobTask task;

  @override
  State<CompleteTaskDialog> createState() => _CompleteTaskDialogState();
}

class _CompleteTaskDialogState extends State<CompleteTaskDialog> {
  final _noteController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String? _completionPhotoPath;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickCompletionPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _completionPhotoPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fotoğraf seçilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Görevi Tamamla'),
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
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Not (Opsiyonel)',
                hintText: 'Tamamlanma notu ekleyin...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickCompletionPhoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(
                _completionPhotoPath == null
                    ? 'Tamamlanma Fotoğrafı Ekle (Opsiyonel)'
                    : 'Fotoğraf Değiştir',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (_completionPhotoPath != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Fotoğraf seçildi',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _completionPhotoPath = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop({
              'note': _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
              'photoPath': _completionPhotoPath,
            });
          },
          child: const Text('Tamamla'),
        ),
      ],
    );
  }
}
