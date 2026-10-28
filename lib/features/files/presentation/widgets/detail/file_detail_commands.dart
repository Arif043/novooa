import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../domain/entities/file_version.dart';
import '../../cubits/file_actions_cubit.dart';
import '../../cubits/file_detail_cubit.dart';
import '../../cubits/file_detail_state.dart';
import '../../localization/file_display_texts.dart';
import '../../pages/image_editor_page.dart';
import '../delete_file_dialog.dart';
import '../file_upload_picker.dart';
import 'move_file_sheet.dart';
import 'rename_file_dialog.dart';
import 'restore_version_dialog.dart';

/// Was die Knöpfe der Detailseite auslösen: Dialoge öffnen, dann die
/// Aktion im `FileActionsCubit` starten (Command).
class FileDetailCommands {
  const FileDetailCommands(this._context, this._state);

  final BuildContext _context;
  final FileDetailReady _state;

  FileActionsCubit get _actions => _context.read<FileActionsCubit>();

  Future<void> rename() => showRenameFileDialog(
    _context,
    currentName: _state.file.displayName,
    onSubmit: (name) => _actions.rename(_state.file, name),
  );

  Future<void> move() async {
    final target = await showMoveFileSheet(
      _context,
      folders: _state.folders,
      currentFolderId: _state.file.folderId,
    );
    if (target != null) await _actions.move(_state.file, target.folderId);
  }

  Future<void> copy() =>
      _actions.copy(_state.file, LocaleKeys.files_copy_suffix.tr());

  Future<void> delete() async {
    final confirmed = await DeleteFileDialog.show(
      _context,
      _state.file.displayName,
    );
    if (confirmed == true) await _actions.delete(_state.file);
  }

  /// Ohne [version] die gerade angezeigte, sonst die aktuelle.
  Future<void> download([FileVersion? version]) async {
    final target = version ?? _state.selectedVersion ?? _currentVersion;
    if (target != null) await _actions.download(_state.file, target);
  }

  Future<void> restore(FileVersion version) async {
    final date = FileDisplayTexts.of(_context).dateTime(version.createdAt);
    if (!await confirmRestoreVersion(_context, versionDate: date)) return;
    await _actions.restore(version);
  }

  Future<void> uploadVersion() async {
    final input = await pickUploadFile();
    if (input != null) await _actions.uploadVersion(_state.file, input);
  }

  Future<void> editImage() async {
    final format = EditableImageFormat.of(_state.file.contentType);
    final content = _state.content;
    if (format == null || content is! FileContentLoaded) return;
    final edited = await ImageEditorPage.open(
      _context,
      bytes: content.bytes,
      format: format,
    );
    if (edited != null) await _actions.saveImage(_state.file, edited);
  }

  Future<void> showVersion(FileVersion version) =>
      _context.read<FileDetailCubit>().selectVersion(version);

  /// Bearbeiten nur, wenn die aktuelle Version eines PNG/JPEG geladen ist —
  /// sonst würde eine alte Version bearbeitet.
  bool get canEditImage =>
      EditableImageFormat.of(_state.file.contentType) != null &&
      !_state.isViewingOldVersion &&
      _state.content is FileContentLoaded;

  bool get isImage => _state.file.contentType.startsWith('image/');

  FileVersion? get _currentVersion =>
      _state.versions.where(_state.isCurrent).firstOrNull;
}
