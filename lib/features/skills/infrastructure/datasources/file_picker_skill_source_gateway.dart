import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/skill_failure.dart';
import '../../domain/entities/skill_import.dart';
import '../../domain/repositories/skill_source_gateway.dart';

/// ZIP über den Dateiwähler; Ordner über den Ordnerwähler (nur Desktop), dessen
/// Dateien hier gelesen werden. Der Server begrenzt zusätzlich.
class FilePickerSkillSourceGateway implements SkillSourceGateway {
  const FilePickerSkillSourceGateway();

  static const maximumBytes = 10 * 1024 * 1024;
  static const maximumFiles = 2000;
  static const _skippedNames = {
    '.git',
    'node_modules',
    '__MACOSX',
    '.DS_Store',
  };

  @override
  bool get canPickFolder =>
      !kIsWeb &&
      const {
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      }.contains(defaultTargetPlatform);

  @override
  Future<Result<SkillImportSource, SkillFailure>> pickArchive() async {
    try {
      final selection = await FilePicker.pickFiles(
        dialogTitle: 'Skill-ZIP auswählen',
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        withData: true,
      );
      final file = selection?.files.singleOrNull;
      if (file == null) return const Error(SkillFailure.cancelled);
      final bytes = file.bytes;
      if (bytes == null) return const Error(_readFailed);
      return Success(ArchiveImportSource(fileName: file.name, bytes: bytes));
    } on Object {
      return const Error(_readFailed);
    }
  }

  @override
  Future<Result<SkillImportSource, SkillFailure>> pickFolder() async {
    try {
      final path = await FilePicker.getDirectoryPath(
        dialogTitle: 'Skill-Ordner auswählen',
      );
      if (path == null) return const Error(SkillFailure.cancelled);
      return await _read(Directory(path));
    } on Object {
      return const Error(_readFailed);
    }
  }

  Future<Result<SkillImportSource, SkillFailure>> _read(Directory root) async {
    final files = <SkillSourceFile>[];
    var total = 0;
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = entity.path
          .substring(root.path.length + 1)
          .replaceAll(r'\', '/');
      if (relative.split('/').any(_skippedNames.contains)) continue;
      final Uint8List bytes = await entity.readAsBytes();
      total += bytes.length;
      if (total > maximumBytes || files.length >= maximumFiles) {
        return const Error(_tooLarge);
      }
      files.add(SkillSourceFile(path: relative, bytes: bytes));
    }
    final name =
        root.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? 'skills';
    return Success(FolderImportSource(name: name, files: files));
  }
}

const _readFailed = SkillFailure('Die Auswahl konnte nicht gelesen werden.');
const _tooLarge = SkillFailure(
  'Der Ordner ist zu groß (höchstens 10 MB und 2000 Dateien). '
  'Wähle den Ordner eines einzelnen Skills.',
);
