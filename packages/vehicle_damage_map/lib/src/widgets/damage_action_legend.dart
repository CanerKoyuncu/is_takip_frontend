import 'package:flutter/material.dart';
import '../core/damage_action_styles.dart';

/// Damage action legend widget.
/// Shows color meanings for damage actions.
class DamageActionLegend extends StatelessWidget {
  const DamageActionLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final entries = damageActionPriority
        .map(damageActionStyle)
        .whereType<DamageActionStyle>()
        .toList();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withAlpha(235), // ~0.92 opacity
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outlineVariant.withAlpha(153), // ~0.6 opacity
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(20), // ~0.08 opacity
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Renk Açıklamaları',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: entry.color,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: colorScheme.outline.withAlpha(
                              102,
                            ), // ~0.4 opacity
                            width: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          entry.label,
                          style: textTheme.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Bir parçada birden fazla işlem varsa renkler çizgili olarak birlikte gösterilir.',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
