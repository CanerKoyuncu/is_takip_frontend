import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> saveBytes(
  Uint8List bytes,
  String filename, {
  String? mimeType,
}) async {
  final safeName = _sanitizeFilename(filename);
  Directory? targetDir;

  try {
    targetDir = await getDownloadsDirectory();
  } catch (_) {
    targetDir = null;
  }

  targetDir ??= await getApplicationDocumentsDirectory();

  final file = File('${targetDir.path}/$safeName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

String _sanitizeFilename(String filename) {
  final sanitized = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  return sanitized.isEmpty ? 'download.bin' : sanitized;
}


