/// Info Row Widget
///
/// Icon, label ve value gösterimi için standart widget.
/// Bilgi gösterimi için kullanılır (araç bilgileri, müşteri bilgileri vb.)

import 'package:flutter/material.dart';

/// Info row widget'ı
///
/// Icon, label ve value ile bilgi satırı gösterir.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconSize = 20,
    this.labelStyle,
    this.valueStyle,
  });

  /// Label (başlık)
  final String label;

  /// Value (değer)
  final String value;

  /// Icon (opsiyonel)
  final IconData? icon;

  /// Icon boyutu (varsayılan: 20)
  final double iconSize;

  /// Label stil (opsiyonel)
  final TextStyle? labelStyle;

  /// Value stil (opsiyonel)
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    labelStyle ??
                    textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 2),
              Text(value, style: valueStyle ?? textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}
