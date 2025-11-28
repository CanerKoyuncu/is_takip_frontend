import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/vehicle_area.dart';
import '../../utils/damage_action_styles.dart';
import '../../utils/svg_vehicle_part_loader.dart';
import '../widgets/custom_svg_picture.dart';
import 'vehicle_damage_map/damage_action_legend.dart';
import 'vehicle_damage_map/hit_test_utils.dart';
import 'vehicle_damage_map/vehicle_action_sheet.dart';
import 'vehicle_damage_map/vehicle_canvas_layout.dart';
import 'vehicle_damage_map/vehicle_parts_painter.dart';

/// Interactive vehicle damage map that renders the grouped SVG illustration and
/// overlays tappable paths parsed from the asset.
class VehicleDamageMap extends StatefulWidget {
  const VehicleDamageMap({
    super.key,
    this.parts,
    this.partsAssetName = 'assets/car-cutout-grouped.svg',
    this.backgroundAssetName = 'assets/car-cutout-grouped.svg',
    this.initialSelections = const {},
    this.onSelectionsChanged,
    this.readOnly = false,
    this.onPartTap,
    this.showActionSheet = true,
    this.artboardBounds,
    this.selectedPartId,
  });

  /// Pre-parsed parts. When provided, the loader will not read the SVG asset.
  final List<VehiclePart>? parts;

  /// SVG asset to parse when [parts] is null or empty.
  final String? partsAssetName;

  /// Background illustration drawn underneath the interactive overlay.
  final String backgroundAssetName;

  final VehiclePartSelections initialSelections;
  final ValueChanged<VehiclePartSelections>? onSelectionsChanged;
  final bool readOnly;
  final ValueChanged<VehiclePart>? onPartTap;
  final bool showActionSheet;
  final Rect? artboardBounds;
  final String? selectedPartId;

  @override
  State<VehicleDamageMap> createState() => _VehicleDamageMapState();
}

class _VehicleDamageMapState extends State<VehicleDamageMap> {
  late VehiclePartSelections _selections;
  Future<List<VehiclePart>>? _autoPartsFuture;

  @override
  void initState() {
    super.initState();
    _selections = Map<String, List<String>>.from(
      widget.initialSelections.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ),
    );
    _refreshAutoPartsFuture();
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
    if (oldWidget.parts != widget.parts ||
        oldWidget.partsAssetName != widget.partsAssetName) {
      _refreshAutoPartsFuture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final explicitParts = widget.parts;
    if (explicitParts != null && explicitParts.isNotEmpty) {
      return _buildInteractive(context, explicitParts);
    }

    final future = _autoPartsFuture;
    if (future == null) {
      return _buildBackgroundOnly(
        context,
        message: 'SVG parça tanımı bulunamadı.',
      );
    }

    return FutureBuilder<List<VehiclePart>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.active) {
          return _buildLoading(context);
        }

        if (snapshot.hasError) {
          debugPrint(
            'VehicleDamageMap failed to load ${widget.partsAssetName}: '
            '${snapshot.error}',
          );
          return _buildBackgroundOnly(
            context,
            message: 'Araç şeması yüklenemedi.',
          );
        }

        final autoParts = snapshot.data;
        if (autoParts == null || autoParts.isEmpty) {
          return _buildBackgroundOnly(
            context,
            message: 'SVG içerisinden parça bulunamadı.',
          );
        }

        return _buildInteractive(context, autoParts);
      },
    );
  }

  void _refreshAutoPartsFuture() {
    final parts = widget.parts;
    if (parts != null && parts.isNotEmpty) {
      _autoPartsFuture = null;
      return;
    }

    final asset = widget.partsAssetName;
    if (asset == null) {
      _autoPartsFuture = null;
      return;
    }

    _autoPartsFuture = SvgVehiclePartLoader.instance.load(assetName: asset);
  }

  Widget _buildInteractive(BuildContext context, List<VehiclePart> parts) {
    const defaultArtboard = Rect.fromLTWH(0, 0, 1668, 1160);
    final colorScheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1668 / 1160,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.surface,
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final layout = VehicleCanvasLayout.from(
                  canvasSize,
                  parts,
                  boundsHint: widget.artboardBounds ?? defaultArtboard,
                );

                // Build part color map for SVG fill coloring
                // Only set fill color for single action parts
                // For multiple actions, use striped pattern as fill
                final partColorMap = <String, Color>{};
                final partActionsMap = <String, List<String>>{};
                for (final part in parts) {
                  final rawActions = _selections[part.id];
                  final normalizedActions = _normalizedActions(rawActions);
                  if (normalizedActions.length == 1) {
                    // Single action: use the action color
                    final color = _baseColorForActions(normalizedActions);
                    partColorMap[part.id] = color;
                    if (kDebugMode) {
                      debugPrint(
                        '[VehicleDamageMap] Fill color assigned -> '
                        'part=${part.id}, action=${normalizedActions.first}, '
                        'color=$color',
                      );
                    }
                  } else if (normalizedActions.length > 1) {
                    // Multiple actions: use striped pattern as fill
                    partActionsMap[part.id] = normalizedActions;
                    if (kDebugMode) {
                      debugPrint(
                        '[VehicleDamageMap] Stripe fill assigned -> '
                        'part=${part.id}, actions=$normalizedActions',
                      );
                    }
                  }
                }

                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomSvgPicture(
                        assetName: widget.backgroundAssetName,
                        partColorMap: partColorMap.isEmpty
                            ? null
                            : partColorMap,
                        partActionsMap: partActionsMap.isEmpty
                            ? null
                            : partActionsMap,
                      ),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: widget.readOnly
                            ? null
                            : (details) => _handleTap(
                                details.localPosition,
                                layout,
                                parts,
                              ),
                        child: CustomPaint(
                          painter: VehiclePartsPainter(
                            parts: parts,
                            selections: _selections,
                            layout: layout,
                            colorScheme: colorScheme,
                            selectedPartId: widget.selectedPartId,
                            drawFill: false, // Fill is now done in SVG
                            drawOutline: false,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: const IgnorePointer(child: DamageActionLegend()),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1668 / 1160,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.surface,
                scheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomSvgPicture(
                  assetName: widget.backgroundAssetName,
                  placeholder: const SizedBox.shrink(),
                ),
              ),
              const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundOnly(BuildContext context, {String? message}) {
    final scheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1668 / 1160,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.surface,
                scheme.surfaceContainerHighest.withValues(alpha: 0.25),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomSvgPicture(
                    assetName: widget.backgroundAssetName,
                    placeholder: const SizedBox.shrink(),
                  ),
                ),
              ),
              if (message != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(
    Offset localPosition,
    VehicleCanvasLayout layout,
    List<VehiclePart> parts,
  ) async {
    final artboardPoint = layout.toArtboard(localPosition);
    VehiclePart? tapped;

    // Try to find the tapped part using multiple detection methods
    for (final part in parts.reversed) {
      // First check bounds (quick rejection test)
      if (!part.bounds.contains(artboardPoint)) continue;

      // Try standard contains check first (works for closed/filled paths)
      try {
        if (part.path.contains(artboardPoint)) {
          tapped = part;
          break;
        }
      } catch (e) {
        debugPrint('Error checking path.contains for ${part.id}: $e');
      }

      // For known closed shapes (rect, circle) that come from SVG rect/circle elements,
      // use bounds-based hit test since they may have fill:none
      // This includes: sunroof (rect), and other rect/circle parts
      if (HitTestUtils.isKnownClosedShape(part.id) || part.allowBoundsHitTest) {
        tapped = part;
        break;
      }

      if (HitTestUtils.isPathClosed(part.path)) {
        tapped = part;
        break;
      }

      // For open/stroke paths, check if point is near the path
      // This handles cases like "tavan" which is a stroke-only path
      // Use the inverse scale for tolerance calculation
      final tolerance = 20.0; // Fixed tolerance in SVG coordinates
      if (HitTestUtils.isPointNearPath(artboardPoint, part.path, tolerance)) {
        tapped = part;
        break;
      }
    }

    if (tapped == null || !mounted) {
      return;
    }

    debugPrint('Part tapped: ${tapped.displayName} (${tapped.id})');

    widget.onPartTap?.call(tapped);

    if (!widget.showActionSheet) {
      return;
    }

    final currentActions = List<String>.from(_selections[tapped.id] ?? []);
    final updatedActions = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          VehicleActionSheet(part: tapped!, selectedActions: currentActions),
    );

    if (!mounted || updatedActions == null) {
      return;
    }

    setState(() {
      _selections = Map<String, List<String>>.from(
        _selections.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );
      if (updatedActions.isEmpty) {
        _selections.remove(tapped!.id);
      } else {
        _selections[tapped!.id] = updatedActions;
      }
    });

    debugPrint(
      '[VehicleDamageMap] Updated selections: ${_selections.length} parts, '
      'tapped part: ${tapped.id}, actions: $updatedActions',
    );

    widget.onSelectionsChanged?.call(
      Map<String, List<String>>.unmodifiable(
        _selections.map(
          (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
        ),
      ),
    );

    debugPrint(
      '[VehicleDamageMap] onSelectionsChanged callback called: '
      '${widget.onSelectionsChanged != null}',
    );
  }

  List<String> _normalizedActions(List<String>? actions) {
    if (actions == null || actions.isEmpty) {
      return const <String>[];
    }

    final normalized = List<String>.from(actions);
    normalized.sort(
      (a, b) =>
          damageActionPriorityIndex(a).compareTo(damageActionPriorityIndex(b)),
    );
    return normalized;
  }

  Color _baseColorForActions(List<String> actions) {
    if (actions.isEmpty) {
      return Colors.white.withValues(alpha: 0.6);
    }
    final color = damageActionColor(actions.first);
    return color ?? Colors.white;
  }
}
