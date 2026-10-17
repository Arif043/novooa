import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/scanned_document.dart';
import '../../domain/services/scan_quad_stabilizer.dart';
import '../../domain/usecases/open_document_scan_session.dart';
import '../cubits/document_scan_cubit.dart';
import '../cubits/document_scan_state.dart';
import '../widgets/document_scan_camera_view.dart';
import '../widgets/document_scan_message_view.dart';
import '../widgets/document_scan_review_view.dart';

/// Vollbild-Scanner. Liefert das begradigte Dokument oder `null`, wenn der
/// Nutzer abbricht.
class DocumentScanPage extends StatelessWidget {
  const DocumentScanPage({super.key});

  static Future<ScannedDocument?> open(BuildContext context) {
    return Navigator.of(context).push<ScannedDocument>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const DocumentScanPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DocumentScanCubit(
        serviceLocator<OpenDocumentScanSession>(),
        ScanQuadStabilizer(),
      )..start(),
      child: const DocumentScanView(),
    );
  }
}

class DocumentScanView extends StatelessWidget {
  const DocumentScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dokument scannen')),
      body: BlocBuilder<DocumentScanCubit, DocumentScanState>(
        builder: (context, state) => switch (state) {
          DocumentScanOpening() => const DocumentScanMessageView(
            message: 'Kamera wird gestartet …',
            isLoading: true,
          ),
          DocumentScanScanning() => DocumentScanCameraView(
            previewId: state.previewId,
            aspectRatio: state.aspectRatio,
            quad: state.quad,
            isCapturing: false,
            onCapture: context.read<DocumentScanCubit>().capture,
          ),
          DocumentScanCapturing() => DocumentScanCameraView(
            previewId: state.previewId,
            aspectRatio: state.aspectRatio,
            quad: state.quad,
            isCapturing: true,
            onCapture: () {},
          ),
          DocumentScanReview() => DocumentScanReviewView(
            document: state.document,
            onRetake: context.read<DocumentScanCubit>().retry,
            onAccept: () => Navigator.of(context).pop(state.document),
          ),
          DocumentScanFailed() => _failureView(context, state),
        },
      ),
    );
  }

  Widget _failureView(BuildContext context, DocumentScanFailed state) {
    return DocumentScanMessageView(
      message: state.failure.message,
      actions: [
        if (state.failure.isRetryable)
          FilledButton(
            onPressed: context.read<DocumentScanCubit>().retry,
            child: const Text('Erneut versuchen'),
          ),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
      ],
    );
  }
}
