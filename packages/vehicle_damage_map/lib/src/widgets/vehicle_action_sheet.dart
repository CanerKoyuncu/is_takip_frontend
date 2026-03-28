import 'package:flutter/material.dart';
import '../models/vehicle_area.dart';
import '../models/vehicle_config.dart';
import '../models/damage_operation.dart';
import '../core/damage_action_styles.dart';
import '../config/vehicle_parts_data.dart';
import 'spare_parts_editor_sheet.dart';

/// Result from VehicleActionSheet.
class VehicleActionSheetResult {
  const VehicleActionSheetResult({
    required this.selectedActions,
    required this.spareParts,
  });

  final List<String> selectedActions;
  final List<SparePartItem> spareParts;
}

/// Bottom sheet for selecting damage actions and managing spare parts for a vehicle part.
class VehicleActionSheet extends StatefulWidget {
  const VehicleActionSheet({
    super.key,
    required this.part,
    required this.selectedActions,
    this.initialSpareParts,
    this.availableActions, // Null means show all
    this.onActionToggled, // Callback when an action is selected/deselected
    this.showSpareParts = true, // Whether to show spare parts editor
  });

  final VehiclePart part;
  final List<String> selectedActions;

  /// Pre-filled spare parts list.
  final List<SparePartItem>? initialSpareParts;

  /// Optional list of actions to show. If null, all DamageOperationType.values are used.
  final List<DamageOperationType>? availableActions;

  /// Callback when a specific action is toggled.
  final void Function(String action, bool selected)? onActionToggled;

  /// Whether to show the spare parts badge/editor in the sheet.
  final bool showSpareParts;

  @override
  State<VehicleActionSheet> createState() => _VehicleActionSheetState();
}

class _VehicleActionSheetState extends State<VehicleActionSheet> {
  late List<String> _selectedActions;
  late List<SparePartItem> _spareParts;

  @override
  void initState() {
    super.initState();
    _selectedActions = List<String>.from(widget.selectedActions);

    if (widget.initialSpareParts != null) {
      _spareParts = List.from(widget.initialSpareParts!);
    } else {
      _spareParts = [];
    }
  }

  void _toggleAction(String action) {
    setState(() {
      final selected = !_selectedActions.contains(action);
      if (!selected) {
        _selectedActions.remove(action);
      } else {
        if (action == VehicleDamageActions.temizle) {
          _selectedActions.clear();
          _selectedActions.add(action);
        } else {
          _selectedActions.remove(VehicleDamageActions.temizle);
          _selectedActions.add(action);
        }
      }
      // Trigger callback
      widget.onActionToggled?.call(action, selected);
    });
  }

  Future<void> _openSparePartsEditor() async {
    final result = await showModalBottomSheet<List<SparePartItem>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SparePartsEditorSheet(
        partId: widget.part.id,
        partName: widget.part.displayName,
        initialSpareParts: _spareParts,
      ),
    );
    if (result != null && mounted) {
      setState(() => _spareParts = result);
    }
  }

  void _confirm() {
    Navigator.of(context).pop(
      VehicleActionSheetResult(
        selectedActions: _selectedActions,
        spareParts: _spareParts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // — Header —
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.part.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.showSpareParts) ...[
                    _SparePartsBadge(
                      count: _spareParts.length,
                      onTap: _openSparePartsEditor,
                    ),
                    const SizedBox(width: 4),
                  ],
                  TextButton(onPressed: _confirm, child: const Text('Tamam')),
                ],
              ),
            ),
            const Divider(height: 1),

            // — Actions List —
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ...(() {
                    final actionsToShow =
                        widget.availableActions ??
                        DamageOperationType.values
                            .where(
                              (t) =>
                                  t.category == DamageTaskCategory.kaporta ||
                                  t.category == DamageTaskCategory.boya,
                            )
                            .toList();

                    // Group by category
                    final grouped =
                        <DamageTaskCategory, List<DamageOperationType>>{};
                    for (final action in actionsToShow) {
                      grouped
                          .putIfAbsent(action.category, () => [])
                          .add(action);
                    }

                    return grouped.entries.map((entry) {
                      final category = entry.key;
                      final actions = entry.value;

                      return ExpansionTile(
                        leading: Icon(
                          category.icon,
                          color: category == DamageTaskCategory.boya
                              ? scheme.primary
                              : category == DamageTaskCategory.kaporta
                              ? scheme.tertiary
                              : scheme.secondary,
                        ),
                        initiallyExpanded: grouped.length == 1,
                        title: Text(
                          category.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: actions.map((type) {
                          final key = type.actionKey;
                          final selected = _selectedActions.contains(key);
                          return CheckboxListTile(
                            title: Text(type.label),
                            value: selected,
                            onChanged: (_) => _toggleAction(key),
                            secondary: _ActionIcon(
                              icon: type.icon,
                              color: category == DamageTaskCategory.boya
                                  ? scheme.primary
                                  : category == DamageTaskCategory.kaporta
                                  ? scheme.tertiary
                                  : scheme.secondary,
                              selected: selected,
                              selectedColor: scheme.primary,
                            ),
                          );
                        }).toList(),
                      );
                    });
                  })(),

                  // Clean (Special case usually not mapped to category:opearation)
                  CheckboxListTile(
                    title: const Text(VehicleDamageActions.temizle),
                    value: _selectedActions.contains(
                      VehicleDamageActions.temizle,
                    ),
                    onChanged: (_) =>
                        _toggleAction(VehicleDamageActions.temizle),
                    secondary: const _ActionColorPreview(
                      action: VehicleDamageActions.temizle,
                    ),
                  ),
                ],
              ),
            ),

            // — Selected Actions Chips —
            if (_selectedActions.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedActions.map((action) {
                    final label = damageActionLabel(action);
                    return Chip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      onDeleted: () => _toggleAction(action),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SparePartsBadge extends StatelessWidget {
  const _SparePartsBadge({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              count > 0 ? 'Yedek Parça ($count)' : 'Yedek Parça',
              style: TextStyle(
                fontSize: 13,
                color: scheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.selected,
    required this.selectedColor,
  });
  final IconData icon;
  final Color color;
  final bool selected;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        if (selected) ...[
          const SizedBox(width: 6),
          Icon(Icons.check_circle, color: selectedColor),
        ],
      ],
    );
  }
}

class _ActionColorPreview extends StatelessWidget {
  const _ActionColorPreview({required this.action});
  final String action;

  @override
  Widget build(BuildContext context) {
    final color = damageActionColor(action) ?? Colors.white;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}
