import 'package:flutter/material.dart';
import '../core/damage_action_styles.dart';

/// Damage action legend widget.
/// Shows color meanings for damage actions.
class DamageActionLegend extends StatelessWidget {
  const DamageActionLegend({super.key, this.actions});

  /// Optional filtered actions to display in legend.
  final List<String>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final actionsToShow = actions ?? damageActionPriority;
    final entries = actionsToShow
      .map((action) => canonicalDamageActionKey(action))
      .toSet()
      .toList()
      ..sort((a, b) => damageActionPriorityIndex(a).compareTo(damageActionPriorityIndex(b)));

    final styles = entries
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
              for (final entry in styles)
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
            ],
          ),
        ),
      ),
    );
  }
}
