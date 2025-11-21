/// Photo Picker Dialog
///
/// Kamera veya galeri seçimi için standart dialog widget'ı.
/// Fotoğraf yükleme ekranlarında kullanılır.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Photo picker dialog gösterir
///
/// Kullanıcıya kamera veya galeri seçeneği sunar.
///
/// Parametreler:
/// - context: BuildContext
///
/// Döner: Future<ImageSource?> - Seçilen kaynak veya null
Future<ImageSource?> showPhotoPickerDialog(BuildContext context) {
  return showDialog<ImageSource?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Fotoğraf Kaynağı'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Kamera'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galeri'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}
