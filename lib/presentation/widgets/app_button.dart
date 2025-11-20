import 'package:flutter/material.dart';

/// Common button widget used across the app
class AppButton extends StatelessWidget {
  final String label;           // Text displayed inside the button
  final VoidCallback onPressed; // Callback executed when the button is pressed
  final bool filled;            // true = filled button, false = outlined button

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      // Default: filled button
      return ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      );
    } else {
      // Optional: outlined button
      return OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      );
    }
  }
}