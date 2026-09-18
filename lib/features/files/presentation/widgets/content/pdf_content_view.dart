import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Renders PDF bytes with built-in page navigation and zoom.
///
/// Wraps the `printing` package's [PdfPreview], hiding the print/share/page
/// format actions we don't need inside this internal viewer.
class PdfContentView extends StatelessWidget {
  const PdfContentView({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return PdfPreview(
      build: (format) async => bytes,
      useActions: false,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      loadingWidget: const Center(child: CircularProgressIndicator()),
      onError: (context, error) => Center(
        child: Text('PDF konnte nicht angezeigt werden: $error'),
      ),
    );
  }
}
