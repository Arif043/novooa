import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Woher Skills importiert werden.
sealed class SkillImportSource {
  const SkillImportSource();
}

/// Öffentliches GitHub-Repository oder Unterordner (`…/tree/<branch>/<pfad>`).
class GitHubImportSource extends SkillImportSource {
  const GitHubImportSource(this.url);

  final String url;
}

/// Vom Nutzer gewählter Ordner; [name] benennt einen Skill, dessen `SKILL.md`
/// direkt darin liegt.
class FolderImportSource extends SkillImportSource {
  const FolderImportSource({required this.name, required this.files});

  final String name;
  final List<SkillSourceFile> files;
}

class ArchiveImportSource extends SkillImportSource {
  const ArchiveImportSource({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}

/// Eintrag aus dem skills.sh-Katalog, per Kennung `{quelle}/{slug}`.
class CatalogImportSource extends SkillImportSource {
  const CatalogImportSource(this.id);

  final String id;
}

class SkillSourceFile {
  const SkillSourceFile({required this.path, required this.bytes});

  /// Relativ zum gewählten Ordner, mit `/` getrennt.
  final String path;
  final Uint8List bytes;
}

class SkillImportCandidate extends Equatable {
  const SkillImportCandidate({
    required this.name,
    required this.description,
    required this.fileCount,
    required this.totalBytes,
    required this.warnings,
    required this.nameTaken,
  });

  final String name;
  final String description;
  final int fileCount;
  final int totalBytes;
  final List<String> warnings;

  /// Der Name ist schon vergeben; beim Übernehmen wird `-2`, `-3` … angehängt.
  final bool nameTaken;

  @override
  List<Object?> get props => [
    name,
    description,
    fileCount,
    totalBytes,
    warnings,
    nameTaken,
  ];
}

class SkillImportRejection extends Equatable {
  const SkillImportRejection({required this.directory, required this.reason});

  final String directory;
  final String reason;

  @override
  List<Object?> get props => [directory, reason];
}

class SkillImportPreview extends Equatable {
  const SkillImportPreview({
    required this.importId,
    required this.candidates,
    required this.rejected,
  });

  final String importId;
  final List<SkillImportCandidate> candidates;
  final List<SkillImportRejection> rejected;

  @override
  List<Object?> get props => [importId, candidates, rejected];
}
