import 'package:flutter/material.dart';

class PageTemplate extends StatelessWidget {
  const PageTemplate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1680),
          child: child,
        ),
      ),
    );
  }
}
