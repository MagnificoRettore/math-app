import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Campo password con l'occhio che mostra e nasconde.
///
/// È un `TextFormField`, non un `TextField`: dentro un `Form` deve poter
/// restituire l'errore come gli altri campi.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final List<String>? autofillHints;
  final AutovalidateMode autovalidateMode;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autofillHints,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      autofillHints: widget.autofillHints,
      autovalidateMode: widget.autovalidateMode,
      decoration: InputDecoration(
        labelText: widget.label,
        filled: true,
        fillColor: c.surface,
        labelStyle: TextStyle(color: c.textSecondary),
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Mostra la password' : 'Nascondi la password',
          icon: Icon(
            _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: c.textSecondary,
          ),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
      ),
    );
  }
}
