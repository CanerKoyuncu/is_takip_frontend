import 'package:flutter/material.dart';

import 'custom_svg_picture.dart';
import 'vehicle_part_autocomplete.dart';
import '../models/vehicle_config.dart';

/// Main widget for displaying and interacting with vehicle damage map
class VehicleDamageMap extends StatefulWidget {
  const VehicleDamageMap({
    super.key,
    required this.assetName,
    this.partColorMap,
    this.partActionsMap,
    this.fit = BoxFit.contain,
    this.onPartTapped,
    this.configuration,
    this.hasSearchBar = false,
  });

  final String assetName;
  final Map<String, Color>? partColorMap;
  final Map<String, List<String>>? partActionsMap;
  final BoxFit fit;
  final void Function(String partId)? onPartTapped;
  final VehicleMapConfiguration? configuration;
  final bool hasSearchBar;

  @override
  State<VehicleDamageMap> createState() => _VehicleDamageMapState();
}

class _VehicleDamageMapState extends State<VehicleDamageMap> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomSvgPicture(
          assetName: widget.assetName,
          fit: widget.fit,
          partColorMap: widget.partColorMap,
          partActionsMap: widget.partActionsMap,
          interactableIds:
              (widget.configuration ?? VehicleMapConfiguration.standard())
                  .interactablePartIds,
          onPartTapped: widget.onPartTapped,
        ),
        if (widget.hasSearchBar)
          Positioned(
            top: 16,
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
                  onPartSelected: (part) => widget.onPartTapped?.call(part.id),
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
