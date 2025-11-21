/// Phone Field Widget
///
/// Telefon input field widget'ı. Telefon formatı validasyonu ile.

import 'package:flutter/material.dart';
import 'form_validators.dart';

/// Phone field widget'ı
///
/// Telefon input field'ı gösterir. Telefon formatı validasyonu ile.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.labelText = 'Telefon',
    this.helperText,
    this.prefixText,
    this.required = true,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
  });

  /// Text editing controller
  final TextEditingController controller;

  /// Label text (varsayılan: "Telefon")
  final String labelText;

  /// Helper text (opsiyonel)
  final String? helperText;

  /// Prefix text (opsiyonel, örn: "+90 ")
  final String? prefixText;

  /// Zorunlu mu? (varsayılan: true)
  final bool required;

  /// On changed callback (opsiyonel)
  final void Function(String)? onChanged;

  /// Text input action (varsayılan: next)
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.phone_outlined),
        prefixText: prefixText,
        helperText: helperText,
      ),
      validator: required
          ? (value) => FormValidators.required(value) ?? FormValidators.phone(value)
          : FormValidators.phone,
      onChanged: onChanged,
    );
  }
}

