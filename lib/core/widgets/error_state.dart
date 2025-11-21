/// Error State Widget
///
/// Hata durumu gösterimi için standart widget. API hataları,
/// yükleme hataları veya genel hatalar için kullanılır.
///
/// Özellikler:
/// - Hata icon'u
/// - Hata mesajı
/// - Retry butonu

import 'package:flutter/material.dart';

/// Hata durumu widget'ı
///
/// Icon, hata mesajı ve retry butonu ile hata durumu gösterir.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.iconSize = 48,
    this.showRetry = true,
  });

  /// Hata mesajı
  final String message;

  /// Retry callback'i
  final VoidCallback? onRetry;

  /// Icon boyutu (varsayılan: 48)
  final double iconSize;

  /// Retry butonu gösterilsin mi? (varsayılan: true)
  final bool showRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: iconSize, color: scheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
