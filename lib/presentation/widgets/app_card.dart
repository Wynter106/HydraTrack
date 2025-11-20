import 'package:flutter/material.dart';

/// Common card widget with rounded corners and a light shadow
class AppCard extends StatelessWidget {
  final Widget child;                // Content displayed inside the card
  final EdgeInsetsGeometry padding;  // Inner padding for the card

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1, // Slight shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}