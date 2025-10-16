import 'package:flutter/material.dart';

class ModernCard extends StatelessWidget {
  final Color? color;
  final Widget child;
  final EdgeInsets? padding;

  const ModernCard({
    super.key,
    this.color,
    this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    ),
  );
    }
  }
