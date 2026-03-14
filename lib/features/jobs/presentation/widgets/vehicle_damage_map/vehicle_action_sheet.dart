/// Vehicle Action Sheet
///
/// Araç parçası için hasar işlemi seçim ve yedek parça yönetimi bottom sheet'i.

import 'package:flutter/material.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart';
import '../../../models/job_models.dart';
import '../../../models/vehicle_area.dart';
import '../../../utils/damage_action_styles.dart';
import 'spare_parts_editor_sheet.dart';

/// VehicleActionSheet sonucu — seçilen aksiyonlar ve yedek parçalar.
class VehicleActionSheetResult {
  const VehicleActionSheetResult({
    required this.selectedActions,
    required this.spareParts,
  });

  final List<String> selectedActions;
  final List<SparePartItem> spareParts;
}

/// Vehicle action sheet widget'ı
///
/// Kullanıcıya hasar işlemi seçenekleri ve yedek parça yönetimi sunar.
class VehicleActionSheet extends StatefulWidget {
  const VehicleActionSheet({
    super.key,
    required this.part,
    required this.selectedActions,
    this.initialSpareParts,
  });

  final VehiclePart part;
  final List<String> selectedActions;

  /// Önceden girilmiş yedek parçalar (null ise kayıt varsayılanlar ile açılır).
  final List<SparePartItem>? initialSpareParts;

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
      final def = VehiclePartsRegistry.byId(widget.part.id);
      _spareParts = List.from(def?.spareParts ?? const []);
    }
  }

  String _operationTypeToActionKey(JobOperationType type) =>
      '${type.category.name}:${type.name}';

  void _toggleAction(String action) {
    setState(() {
      if (_selectedActions.contains(action)) {
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
            // — Başlık —
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
                  // Yedek parça butonu
                  _SparePartsBadge(
                    count: _spareParts.length,
                    onTap: _openSparePartsEditor,
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: _confirm,
                    child: const Text('Tamam'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // — Aksiyon listesi —
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Kaporta Kategorisi
                  ExpansionTile(
                    leading: Icon(
                      TaskCategory.kaporta.icon,
                      color: scheme.tertiary,
                    ),
                    title: Text(
                      TaskCategory.kaporta.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: JobOperationType.values
                        .where((t) => t.category == TaskCategory.kaporta)
                        .map((type) {
                          final key = _operationTypeToActionKey(type);
                          final selected = _selectedActions.contains(key);
                          return CheckboxListTile(
                            title: Text(type.label),
                            value: selected,
                            onChanged: (_) => _toggleAction(key),
                            secondary: _ActionIcon(
                              icon: type.icon,
                              color: scheme.tertiary,
                              selected: selected,
                              selectedColor: scheme.primary,
                            ),
                          );
                        })
                        .toList(),
                  ),
                  // BOYA Kategorisi
                  ExpansionTile(
                    leading: Icon(TaskCategory.boya.icon, color: scheme.primary),
                    title: Text(
                      TaskCategory.boya.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: JobOperationType.values
                        .where((t) => t.category == TaskCategory.boya)
                        .map((type) {
                          final key = _operationTypeToActionKey(type);
                          final selected = _selectedActions.contains(key);
                          return CheckboxListTile(
                            title: Text(type.label),
                            value: selected,
                            onChanged: (_) => _toggleAction(key),
                            secondary: _ActionIcon(
                              icon: type.icon,
                              color: scheme.primary,
                              selected: selected,
                              selectedColor: scheme.primary,
                            ),
                          );
                        })
                        .toList(),
                  ),
                  // Temizle
                  CheckboxListTile(
                    title: Text(VehicleDamageActions.temizle),
                    value: _selectedActions.contains(VehicleDamageActions.temizle),
                    onChanged: (_) => _toggleAction(VehicleDamageActions.temizle),
                    secondary: _ActionColorPreview(action: VehicleDamageActions.temizle),
                  ),
                ],
              ),
            ),

            // — Seçili aksiyonlar —
            if (_selectedActions.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedActions.map((action) {
                    return Chip(
                      label: Text(action, style: const TextStyle(fontSize: 12)),
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

// ---------------------------------------------------------------------------
// Yardımcı widget'lar
// ---------------------------------------------------------------------------

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
