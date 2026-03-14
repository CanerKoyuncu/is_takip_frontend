import 'package:flutter/material.dart';
import 'package:vehicle_damage_map/vehicle_damage_map.dart';

void main() {
  runApp(const MaterialApp(home: VehicleDamageMapExample()));
}

class VehicleDamageMapExample extends StatefulWidget {
  const VehicleDamageMapExample({super.key});

  @override
  State<VehicleDamageMapExample> createState() =>
      _VehicleDamageMapExampleState();
}

class _VehicleDamageMapExampleState extends State<VehicleDamageMapExample> {
  final Map<String, Color> _partColors = {};
  String? _lastTappedPart;

  void _handlePartTapped(String partId) {
    setState(() {
      _lastTappedPart = partId;

      if (_partColors.containsKey(partId)) {
        _partColors.remove(partId);
      } else {
        _partColors[partId] = Colors.red.withValues(alpha: 0.7);
      }
    });
  }

  void _selectAllParts() {
    setState(() {
      final allParts = VehiclePartsConfig.getAllPartIds();
      for (final partId in allParts) {
        _partColors[partId] = Colors.red.withValues(alpha: 0.7);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Damage Map Demo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _lastTappedPart != null
                  ? 'Last Tapped: $_lastTappedPart'
                  : 'Tap a vehicle part',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: VehicleDamageMap(
                assetName:
                    'packages/vehicle_damage_map/assets/car-cutout-grouped.svg',
                fit: BoxFit.contain,
                partColorMap: _partColors,
                onPartTapped: _handlePartTapped,
                hasSearchBar: true,
                configuration: VehicleMapConfiguration.custom(
                  removedPartIds: [
                    // Example: Exclude specific parts from selection and search
                    // 'yakit-depo-kapagi',
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Red = Damaged (Tap to toggle)'),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ElevatedButton(
              onPressed: _selectAllParts,
              child: const Text('Hepsini Seç'),
            ),
          ),
        ],
      ),
    );
  }
}
