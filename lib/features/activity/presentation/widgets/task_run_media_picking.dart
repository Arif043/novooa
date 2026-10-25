import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/platform/document_scan_support.dart';
import '../../../document_scan/presentation/pages/document_scan_page.dart';
import '../../domain/entities/media_input_submission.dart';
import '../../domain/entities/task_run_media_input.dart';
import '../cubits/activity_cubit.dart';

/// Im Browser scannt eine eigene Seite mit Kamerabild und Randerkennung; auf
/// Android und iOS übernimmt das native Plugin hinter dem [ActivityCubit].
Future<MediaInputSubmission?> pickImageSubmission(
  BuildContext context,
  TaskRunMediaInputSource source,
) {
  final scansInBrowser =
      source == TaskRunMediaInputSource.documentScan &&
      webDocumentScanSupportedOnThisPlatform();
  if (scansInBrowser) return _scanInBrowser(context);
  return context.read<ActivityCubit>().pickImage(source);
}

Future<MediaInputSubmission?> _scanInBrowser(BuildContext context) async {
  final document = await DocumentScanPage.open(context);
  if (document == null) return null;
  return MediaInputSubmission(
    name: document.name,
    bytes: document.bytes,
    contentType: document.contentType,
  );
}
