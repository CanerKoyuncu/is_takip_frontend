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
  VehiclePartSelections _selections = {};
  String? _lastTappedPart;

  void _handlePartTapped(String partId) {
    setState(() {
      _lastTappedPart = partId;
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
                initialSelections: _selections,
                onSelectionsChanged: (newSelections) {
                  setState(() {
                    _selections = newSelections;
                  });
                },
                onPartTapped: _handlePartTapped,
                hasSearchBar: true,
                configuration: VehicleMapConfiguration.standard(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Interactive Mode: Tap parts to select damage types.\n'
              'Includes Legend and Action Sheets automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
