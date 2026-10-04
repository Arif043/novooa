import 'package:flutter/material.dart';

class ScanPreview extends StatelessWidget {
  const ScanPreview({super.key, required this.previewId});

  final String previewId;

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: previewId);
  }
}
