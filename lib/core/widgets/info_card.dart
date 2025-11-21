/// Info Card Widget
///
/// Bilgi gösterimi için standart card widget'ı.
/// Title ve content ile bilgi kartı gösterir.

import 'package:flutter/material.dart';

/// Info card widget'ı
///
/// Title ve content ile bilgi kartı gösterir.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    required this.children,
    this.padding = const EdgeInsets.all(16),
  });

  /// Card başlığı
  final String title;

  /// Card içeriği
  final List<Widget> children;

  /// Padding (varsayılan: 16)
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
