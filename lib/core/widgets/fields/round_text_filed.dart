import 'package:flutter/material.dart';

class RoundTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final Function(String)? onFieldSubmitted;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;

  const RoundTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.onFieldSubmitted,
    this.autovalidateMode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: autovalidateMode,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        // labelStyle: Constants.labelAndHintTextStyle(colorScheme),
        hintText: hintText,
        // hintStyle: Constants.labelAndHintTextStyle(colorScheme),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
