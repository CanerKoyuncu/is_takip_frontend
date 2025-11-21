/// Empty State Widget
///
/// Boş durum gösterimi için standart widget. Liste, arama sonuçları
/// veya herhangi bir içerik olmadığında kullanılır.
///
/// Özellikler:
/// - Özelleştirilebilir icon
/// - Mesaj gösterimi
/// - Opsiyonel action button

import 'package:flutter/material.dart';

/// Boş durum widget'ı
///
/// Icon, mesaj ve opsiyonel action button ile boş durum gösterir.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
  });

  /// Gösterilecek mesaj
  final String message;

  /// Icon (varsayılan: info_outline)
  final IconData? icon;

  /// Action button etiketi
  final String? actionLabel;

  /// Action button callback'i
  final VoidCallback? onAction;

  /// Icon boyutu (varsayılan: 64)
  final double iconSize;

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
            Icon(
              icon ?? Icons.info_outline,
              size: iconSize,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
