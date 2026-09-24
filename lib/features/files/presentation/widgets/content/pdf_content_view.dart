import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Renders PDF bytes with built-in page navigation and pinch-to-zoom.
///
/// Wraps `pdfx`'s [PdfViewPinch]/[PdfControllerPinch], hiding the
/// loading/error builders behind app-consistent widgets.
class PdfContentView extends StatefulWidget {
  const PdfContentView({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<PdfContentView> createState() => _PdfContentViewState();
}

class _PdfContentViewState extends State<PdfContentView> {
  late PdfControllerPinch _controller;

  @override
  void initState() {
    super.initState();
    _controller = _controllerFor(widget.bytes);
  }

  @override
  void didUpdateWidget(covariant PdfContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.bytes, widget.bytes)) return;
    final previous = _controller;
    _controller = _controllerFor(widget.bytes);
    previous.dispose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PdfControllerPinch _controllerFor(Uint8List bytes) {
    return PdfControllerPinch(document: PdfDocument.openData(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return PdfViewPinch(
      controller: _controller,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error) => Center(
          child: Text('PDF konnte nicht angezeigt werden: $error'),
        ),
      ),
    );
  }
}
