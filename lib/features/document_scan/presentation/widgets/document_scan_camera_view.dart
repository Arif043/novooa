import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/scan_quad.dart';
import 'scan_preview.dart';
import 'scan_quad_overlay.dart';

/// Kamerabild mit erkannter Kontur und der Aufnahme-Schaltfläche darunter.
class DocumentScanCameraView extends StatelessWidget {
  const DocumentScanCameraView({
    super.key,
    required this.previewId,
    required this.aspectRatio,
    required this.quad,
    required this.isCapturing,
    required this.onCapture,
  });

  final String previewId;
  final double aspectRatio;
  final ScanQuad? quad;
  final bool isCapturing;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ScanPreview(previewId: previewId),
                  ScanQuadOverlay(quad: quad),
                ],
              ),
            ),
          ),
        ),
        _Controls(quad: quad, isCapturing: isCapturing, onCapture: onCapture),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.quad,
    required this.isCapturing,
    required this.onCapture,
  });

  final ScanQuad? quad;
  final bool isCapturing;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final hint = quad == null
        ? 'Lege das Dokument flach in das Bild.'
        : 'Dokument erkannt. Zum Aufnehmen tippen.';
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(hint, textAlign: TextAlign.center),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isCapturing ? null : onCapture,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(isCapturing ? 'Wird aufgenommen …' : 'Aufnehmen'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
