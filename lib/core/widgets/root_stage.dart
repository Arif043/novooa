import 'package:flutter/material.dart';

class RootStage extends StatelessWidget {
  const RootStage({super.key, required this.child});

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
