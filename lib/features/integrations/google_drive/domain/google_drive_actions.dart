import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';

/// Eine Aktion des Drive-Bausteins. Für Nutzer:innen ist jede ein eigener
/// Baustein; im Backend teilen sie sich das Primitive `googleDrive`.
class GoogleDriveActionSpec {
  const GoogleDriveActionSpec({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.outputBase,
    required this.primaryOutput,
    required this.outputFields,
  });

  /// Muss zur gleichnamigen Aktion unter `integrations/google_drive/actions` passen.
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String outputBase;
  final NodeOutputType primaryOutput;
  final Map<String, NodeOutputType> outputFields;
}

class GoogleDriveActions {
  const GoogleDriveActions._();

  static const upload = GoogleDriveActionSpec(
    id: 'upload',
    titleKey: LocaleKeys.google_drive_upload_title,
    descriptionKey: LocaleKeys.google_drive_upload_description,
    outputBase: 'driveLink',
    primaryOutput: NodeOutputType.string,
    outputFields: {
      'driveFileId': NodeOutputType.string,
      'name': NodeOutputType.string,
      'mimeType': NodeOutputType.string,
      'sizeBytes': NodeOutputType.number,
    },
  );

  static const read = GoogleDriveActionSpec(
    id: 'read',
    titleKey: LocaleKeys.google_drive_read_title,
    descriptionKey: LocaleKeys.google_drive_read_description,
    outputBase: 'driveDatei',
    primaryOutput: NodeOutputType.file,
    outputFields: {
      'driveFileId': NodeOutputType.string,
      'name': NodeOutputType.string,
      'mimeType': NodeOutputType.string,
    },
  );

  static const all = [upload, read];

  static GoogleDriveActionSpec? byId(String id) {
    for (final action in all) {
      if (action.id == id) return action;
    }
    return null;
  }
}
