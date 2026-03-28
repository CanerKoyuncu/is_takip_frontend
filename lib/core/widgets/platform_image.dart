import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Tüm platformlarda (Web, Android) çalışan görsel yükleyici.
///
/// [path] parametresi:
/// - Web'de: Blob URL (blob:) veya Data URL (data:)
/// - Android'de: Dosya yolu (/storage/...) veya asset yolu
class PlatformImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const PlatformImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return _buildError();
    }

    // Web Platformu
    if (kIsWeb) {
      // Web'de Image.network blob, data ve http URL'lerini destekler
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildError(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildPlaceholder();
        },
      );
    }

    // Native Platformlar (Android/iOS)
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildError(),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(path, width: width, height: height, fit: fit);
    } else if (path.startsWith('data:image')) {
      // Base64 desteği (Android'de nadir ama mümkün)
      final Uri uri = Uri.parse(path);
      return Image.memory(
        uri.data!.contentAsBytes(),
        width: width,
        height: height,
        fit: fit,
      );
    } else {
      // Yerel dosya yolu (dart:io File)
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildError(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildError() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
  }
}
