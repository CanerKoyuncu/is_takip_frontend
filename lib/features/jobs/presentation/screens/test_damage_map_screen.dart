import 'package:flutter/material.dart';

import 'package:vehicle_damage_map/vehicle_damage_map.dart';

class TestDamageMapScreen extends StatefulWidget {
  const TestDamageMapScreen({super.key});

  @override
  State<TestDamageMapScreen> createState() => _TestDamageMapScreenState();
}

class _TestDamageMapScreenState extends State<TestDamageMapScreen> {
  bool _isLoading = true;
  String? _error;
  VehiclePartSelections _pkgActions = {};

  @override
  void initState() {
    super.initState();
    _loadLibParts();
  }

  Future<void> _loadLibParts() async {
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Damage Map Comparison')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Error: $_error'))
            : VehicleDamageMap(
                assetName: 'assets/car-cutout-grouped.svg',
                initialSelections: _pkgActions,
                onSelectionsChanged: (selections) {
                  setState(() {
                    _pkgActions = selections;
                  });
                },
              ),
    );
  }
}
