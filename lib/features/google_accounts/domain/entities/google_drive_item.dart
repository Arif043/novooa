import 'package:equatable/equatable.dart';

/// Eine Datei oder ein Ordner, den jemand beim Verbinden im Google-Picker
/// freigegeben hat. Nur solche Einträge (und selbst angelegte Dateien) sieht
/// novooa mit dem Scope `drive.file`.
class GoogleDriveItem extends Equatable {
  const GoogleDriveItem({
    required this.id,
    required this.name,
    required this.mimeType,
  });

  static const folderMimeType = 'application/vnd.google-apps.folder';

  final String id;
  final String name;
  final String mimeType;

  bool get isFolder => mimeType == folderMimeType;

  @override
  List<Object?> get props => [id, name, mimeType];
}
