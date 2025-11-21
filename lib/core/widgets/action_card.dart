/// Action Card Widget
///
/// Tıklanabilir action card widget'ı. Dashboard ve menü ekranlarında kullanılır.

import 'package:flutter/material.dart';

/// Action card widget'ı
///
/// Tıklanabilir card gösterir. Icon, title, description ve onTap callback'i ile.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.color,
    this.iconSize = 36,
  });

  /// Icon
  final IconData icon;

  /// Başlık
  final String title;

  /// Açıklama
  final String description;

  /// Tıklama callback'i
  final VoidCallback onTap;

  /// Arka plan rengi (opsiyonel)
  final Color? color;

  /// Icon boyutu (varsayılan: 36)
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cardColor = color ?? scheme.surfaceContainerHighest;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: iconSize, color: scheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(description, style: textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
