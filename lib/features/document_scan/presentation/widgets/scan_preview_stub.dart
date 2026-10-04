import 'package:flutter/material.dart';

/// Außerhalb des Browsers gibt es kein Kamerabild; die Fläche bleibt leer.
class ScanPreview extends StatelessWidget {
  const ScanPreview({super.key, required this.previewId});

  final String previewId;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
