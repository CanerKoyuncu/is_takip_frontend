/// Email Field Widget
///
/// Email input field widget'ı. Email formatı validasyonu ile.

import 'package:flutter/material.dart';
import 'form_validators.dart';

/// Email field widget'ı
///
/// Email input field'ı gösterir. Email formatı validasyonu ile.
class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
    required this.controller,
    this.labelText = 'Email',
    this.helperText,
    this.required = false,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
  });

  /// Text editing controller
  final TextEditingController controller;

  /// Label text (varsayılan: "Email")
  final String labelText;

  /// Helper text (opsiyonel)
  final String? helperText;

  /// Zorunlu mu? (varsayılan: false)
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
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.email_outlined),
        helperText: helperText,
      ),
      validator: required
          ? (value) => FormValidators.required(value) ?? FormValidators.email(value)
          : FormValidators.email,
      onChanged: onChanged,
    );
  }
}

