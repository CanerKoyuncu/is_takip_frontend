import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/damage_action_styles.dart';
import '../models/vehicle_area.dart';
import '../models/vehicle_config.dart';
import '../models/damage_operation.dart';
import 'custom_svg_picture.dart';
import 'damage_action_legend.dart';
import 'vehicle_action_sheet.dart';
import 'vehicle_part_autocomplete.dart';

/// High-level interactive vehicle damage map.
/// Manages selection state, action sheets, and spare parts.
class VehicleDamageMap extends StatefulWidget {
  const VehicleDamageMap({
    super.key,
    required this.assetName,
    this.initialSelections = const {},
    this.onSelectionsChanged,
    this.initialSparePartsSelections = const {},
    this.onSparePartsChanged,
    this.readOnly = false,
    this.showActionSheet = true,
    this.showLegend = true,
    this.fit = BoxFit.contain,
    this.configuration,
    this.hasSearchBar = false,
    this.onPartTapped, // Low-level tap callback if needed
    this.availableActions, // Null means show all relevant
    this.onActionToggled, // Callback for each toggled action
    this.showSpareParts = true, // Whether to show spare parts editor in sheet
  });

  final String assetName;
  final VehiclePartSelections initialSelections;
  final ValueChanged<VehiclePartSelections>? onSelectionsChanged;

  /// User's previously entered spare parts (partId -> list).
  final PartSparePartsMap initialSparePartsSelections;

  /// Called when spare parts selection changes.
  final ValueChanged<PartSparePartsMap>? onSparePartsChanged;

  final bool readOnly;
  final bool showActionSheet;
  final bool showLegend;
  final BoxFit fit;
  final VehicleMapConfiguration? configuration;
  final bool hasSearchBar;

  /// Callback when a part is tapped (called before the action sheet).
  final void Function(String partId)? onPartTapped;

  /// Optional list of actions to show in the sheet.
  final List<DamageOperationType>? availableActions;

  /// Callback triggered whenever a specific action/damage is toggled on/off.
  final void Function(String partId, String action, bool selected)?
  onActionToggled;

  /// Whether to show the spare parts badge/editor in the sheet.
  final bool showSpareParts;

  @override
  State<VehicleDamageMap> createState() => _VehicleDamageMapState();
}

class _VehicleDamageMapState extends State<VehicleDamageMap> {
  late VehiclePartSelections _selections;
  late PartSparePartsMap _spareParts;

  @override
  void initState() {
    super.initState();
    _selections = Map<String, List<String>>.from(
      widget.initialSelections.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
    );
    _spareParts = Map<String, List<SparePartItem>>.from(
      widget.initialSparePartsSelections.map(
        (key, value) => MapEntry(key, List<SparePartItem>.from(value)),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant VehicleDamageMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(widget.initialSelections, oldWidget.initialSelections)) {
      _selections = Map<String, List<String>>.from(
        widget.initialSelections.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );
    }
    if (!mapEquals(
      widget.initialSparePartsSelections,
      oldWidget.initialSparePartsSelections,
    )) {
      _spareParts = Map<String, List<SparePartItem>>.from(
        widget.initialSparePartsSelections.map(
          (key, value) => MapEntry(key, List<SparePartItem>.from(value)),
        ),
      );
    }
  }

  void _handlePartTapped(String partId) async {
    widget.onPartTapped?.call(partId);

    if (widget.readOnly || !widget.showActionSheet) return;

    final config = widget.configuration ?? VehicleMapConfiguration.standard();
    if (!config.interactablePartIds.contains(partId)) {
      // Potentially resolve alias if not directly interactable but known
      debugPrint('[VehicleDamageMap] Tapped ID $partId is not interactable.');
      return;
    }

    // Find the display name or use technical ID
    final partDef = VehiclePartsRegistry.byId(partId);
    final partName = partDef?.name ?? partId;

    final result = await showModalBottomSheet<VehicleActionSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => VehicleActionSheet(
        part: VehiclePart(
          id: partId,
          displayName: partName,
          path:
              Path(), // Path isn't used in ActionSheet UI usually, just ID/Name
        ),
        selectedActions: _selections[partId] ?? [],
        initialSpareParts: _spareParts[partId],
        availableActions: widget.availableActions,
        showSpareParts: widget.showSpareParts,
        onActionToggled: (action, selected) {
          widget.onActionToggled?.call(partId, action, selected);
        },
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (result.selectedActions.isEmpty) {
          _selections.remove(partId);
        } else {
          _selections[partId] = result.selectedActions;
        }

        if (result.spareParts.isEmpty) {
          _spareParts.remove(partId);
        } else {
          _spareParts[partId] = result.spareParts;
        }
      });

      widget.onSelectionsChanged?.call(Map.unmodifiable(_selections));
      widget.onSparePartsChanged?.call(Map.unmodifiable(_spareParts));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Convert logical selections to maps for CustomSvgPicture
    final partColorMap = <String, Color>{};
    final partActionsMap = <String, List<String>>{};

    _selections.forEach((partId, actions) {
      if (actions.length == 1) {
        final color = damageActionColor(actions.first);
        if (color != null) {
          partColorMap[partId] = color;
        }
      } else if (actions.length > 1) {
        partActionsMap[partId] = actions;
      }
    });

    return Stack(
      children: [
        CustomSvgPicture(
          assetName: widget.assetName,
          fit: widget.fit,
          partColorMap: partColorMap,
          partActionsMap: partActionsMap,
          interactableIds:
              (widget.configuration ?? VehicleMapConfiguration.standard())
                  .interactablePartIds,
          onPartTapped: _handlePartTapped,
        ),
        if (widget.showLegend)
          const Positioned(
            top: 16,
            right: 16,
            child: IgnorePointer(child: DamageActionLegend()),
          ),
        if (widget.hasSearchBar)
          Positioned(
            top: widget.showLegend ? 180 : 16, // Shift if legend is visible
            right: 16,
            width: 250,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: VehiclePartAutocomplete(
                  configuration: widget.configuration,
                  onPartSelected: (part) => _handlePartTapped(part.id),
                  decoration: const InputDecoration(
                    hintText: 'Parça Ara...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, size: 20),
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
