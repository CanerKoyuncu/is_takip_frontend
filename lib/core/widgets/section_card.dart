/// Section Card Widget
///
/// Section başlıklı card widget'ı. İçerik bölümleri için kullanılır.

import 'package:flutter/material.dart';

/// Section card widget'ı
///
/// Section başlığı ve içerik ile card gösterir.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.titleStyle,
    this.actions,
  });

  /// Section başlığı
  final String title;

  /// Card içeriği
  final List<Widget> children;

  /// Padding (varsayılan: 16)
  final EdgeInsets padding;

  /// Title stil (opsiyonel)
  final TextStyle? titleStyle;

  /// Başlık yanında gösterilecek action'lar (opsiyonel)
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (actions != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style:
                        titleStyle ??
                        textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  ...actions!,
                ],
              )
            else
              Text(
                title,
                style:
                    titleStyle ??
                    textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
