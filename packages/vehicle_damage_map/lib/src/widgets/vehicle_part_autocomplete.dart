import 'package:flutter/material.dart';
import '../models/vehicle_config.dart';

/// A search field that allows selecting a vehicle part by name.
///
/// Useful for quickly finding and selecting a part without interacting with the map directly.
class VehiclePartAutocomplete extends StatelessWidget {
  const VehiclePartAutocomplete({
    super.key,
    this.configuration,
    required this.onPartSelected,
    this.decoration,
    this.textInputAction,
  });

  /// Configuration providing the list of available parts.
  /// If null, [VehicleMapConfiguration.standard] is used.
  final VehicleMapConfiguration? configuration;

  /// Callback called when a part is selected from the list.
  final ValueChanged<VehiclePartConfig> onPartSelected;

  /// Custom decoration for the text field.
  final InputDecoration? decoration;

  /// Text input action for the keyboard.
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final config = configuration ?? VehicleMapConfiguration.standard();

    return Autocomplete<VehiclePartConfig>(
      displayStringForOption: (VehiclePartConfig option) => option.name,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<VehiclePartConfig>.empty();
        }
        return config.parts.where((VehiclePartConfig option) {
          return option.name.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: onPartSelected,
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              textInputAction: textInputAction,
              decoration:
                  decoration ??
                  const InputDecoration(
                    labelText: 'Parça Ara',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },
      optionsViewBuilder:
          (
            BuildContext context,
            AutocompleteOnSelected<VehiclePartConfig> onSelected,
            Iterable<VehiclePartConfig> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 32, // Adjust width
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final VehiclePartConfig option = options.elementAt(index);
                      return ListTile(
                        title: Text(option.name),
                        subtitle: option.description != null
                            ? Text(option.description!)
                            : null,
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
    );
  }
}
