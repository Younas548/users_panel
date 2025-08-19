import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  const AppTextField({super.key, required this.controller, required this.hint, this.validator, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(hintText: hint),
    );
  }
}
