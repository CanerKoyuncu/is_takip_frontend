/// Add Photo Dialog
///
/// Fotoğraf türü seçimi dialog'u.

import 'package:flutter/material.dart';
import '../../../../models/job_models.dart';

/// Add photo dialog widget'ı
///
/// Kullanıcıya fotoğraf türü seçeneği sunar.
class AddPhotoDialog extends StatelessWidget {
  const AddPhotoDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fotoğraf Türü Seçin'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded),
            title: const Text('Hasar Fotoğrafı'),
            subtitle: const Text('Görev başlamadan önceki hasar durumu'),
            onTap: () => Navigator.of(context).pop(TaskPhotoType.damage),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('Tamamlanma Fotoğrafı'),
            subtitle: const Text('Görev tamamlandıktan sonraki durum'),
            onTap: () => Navigator.of(context).pop(TaskPhotoType.completion),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
      ],
    );
  }
}
