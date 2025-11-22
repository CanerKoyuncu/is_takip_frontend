/// Vehicle Action Sheet
///
/// Araç parçası için hasar işlemi seçim bottom sheet'i.

import 'package:flutter/material.dart';
import '../../../models/job_models.dart';
import '../../../models/vehicle_area.dart';
import '../../../utils/damage_action_styles.dart';

/// Vehicle action sheet widget'ı
///
/// Kullanıcıya hasar işlemi seçenekleri sunar.
class VehicleActionSheet extends StatefulWidget {
  const VehicleActionSheet({
    super.key,
    required this.part,
    required this.selectedActions,
  });

  final VehiclePart part;
  final List<String> selectedActions;

  @override
  State<VehicleActionSheet> createState() => _VehicleActionSheetState();
}

class _VehicleActionSheetState extends State<VehicleActionSheet> {
  late List<String> _selectedActions;

  @override
  void initState() {
    super.initState();
    _selectedActions = List<String>.from(widget.selectedActions);
  }

  /// JobOperationType'ı action key'e çevirir
  /// Backend'e gönderilirken enum_mapper kullanılacak
  String _operationTypeToActionKey(JobOperationType type) {
    // Kategori bazlı action key oluştur
    // Format: "category:operationType" (örn: "kaporta:onarim", "boya:yeniBoya")
    return '${type.category.name}:${type.name}';
  }

  void _toggleAction(String action) {
    setState(() {
      if (_selectedActions.contains(action)) {
        _selectedActions.remove(action);
      } else {
        // Temizle seçildiyse diğerlerini kaldır
        if (action == VehicleDamageActions.temizle) {
          _selectedActions.clear();
          _selectedActions.add(action);
        } else {
          // Diğer işlemler seçildiyse temizle'yi kaldır
          _selectedActions.remove(VehicleDamageActions.temizle);
          _selectedActions.add(action);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.part.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_selectedActions),
                    child: const Text('Tamam'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Kaporta Kategorisi
                  ExpansionTile(
                    leading: Icon(
                      TaskCategory.kaporta.icon,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    title: Text(
                      TaskCategory.kaporta.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      ...JobOperationType.values
                          .where(
                            (type) => type.category == TaskCategory.kaporta,
                          )
                          .map((type) {
                            final actionKey = _operationTypeToActionKey(type);
                            final isSelected = _selectedActions.contains(
                              actionKey,
                            );
                            return CheckboxListTile(
                              title: Text(type.label),
                              value: isSelected,
                              onChanged: (_) => _toggleAction(actionKey),
                              secondary: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    type.icon,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.tertiary,
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                    ],
                  ),
                  // BOYA Kategorisi
                  ExpansionTile(
                    leading: Icon(
                      TaskCategory.boya.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      TaskCategory.boya.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      ...JobOperationType.values
                          .where((type) => type.category == TaskCategory.boya)
                          .map((type) {
                            final actionKey = _operationTypeToActionKey(type);
                            final isSelected = _selectedActions.contains(
                              actionKey,
                            );
                            return CheckboxListTile(
                              title: Text(type.label),
                              value: isSelected,
                              onChanged: (_) => _toggleAction(actionKey),
                              secondary: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    type.icon,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                    ],
                  ),
                  // Temizle (görev oluşturmaz)
                  CheckboxListTile(
                    title: Text(VehicleDamageActions.temizle),
                    value: _selectedActions.contains(
                      VehicleDamageActions.temizle,
                    ),
                    onChanged: (_) =>
                        _toggleAction(VehicleDamageActions.temizle),
                    secondary: _ActionColorPreview(
                      action: VehicleDamageActions.temizle,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedActions.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedActions.map((action) {
                    return Chip(
                      label: Text(action),
                      onDeleted: () => _toggleAction(action),
                      deleteIcon: const Icon(Icons.close, size: 18),
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
