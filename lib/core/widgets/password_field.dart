/// Password Field Widget
///
/// Şifre input field widget'ı. Görünürlük toggle ile.
/// Login ve register ekranlarında kullanılır.

import 'package:flutter/material.dart';

/// Password field widget'ı
///
/// Şifre input field'ı gösterir. Görünürlük toggle butonu ile.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.labelText = 'Şifre',
    this.helperText,
    this.validator,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
    this.onFieldSubmitted,
    this.autofocus = false,
  });

  /// Text editing controller
  final TextEditingController controller;

  /// Label text (varsayılan: "Şifre")
  final String labelText;

  /// Helper text (opsiyonel)
  final String? helperText;

  /// Validator fonksiyonu (opsiyonel)
  final String? Function(String?)? validator;

  /// On changed callback (opsiyonel)
  final void Function(String)? onChanged;

  /// Text input action (varsayılan: done)
  final TextInputAction textInputAction;

  /// On field submitted callback (opsiyonel)
  final void Function(String)? onFieldSubmitted;

  /// Autofocus (varsayılan: false)
  final bool autofocus;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: widget.labelText,
        prefixIcon: const Icon(Icons.lock_outline),
        helperText: widget.helperText,
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}
