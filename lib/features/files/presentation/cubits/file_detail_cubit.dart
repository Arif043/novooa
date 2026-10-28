import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/file_version.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/team_folder.dart';
import '../../domain/usecases/download_file_version.dart';
import '../../domain/usecases/watch_file_version_limit.dart';
import '../../domain/usecases/watch_file_versions.dart';
import '../../domain/usecases/watch_team_file.dart';
import '../../domain/usecases/watch_team_folders.dart';
import 'file_detail_state.dart';

/// Datei, Verlauf und Inhalt der gewählten Version. Ändernde Aktionen liegen
/// im `FileActionsCubit`; ihre Folgen kommen über die beobachteten Streams an.
class FileDetailCubit extends Cubit<FileDetailState> {
  FileDetailCubit(
    this._watchTeamFile,
    this._watchFileVersions,
    this._watchTeamFolders,
    this._watchFileVersionLimit,
    this._downloadFileVersion,
  ) : super(const FileDetailLoading());

  final WatchTeamFile _watchTeamFile;
  final WatchFileVersions _watchFileVersions;
  final WatchTeamFolders _watchTeamFolders;
  final WatchFileVersionLimit _watchFileVersionLimit;
  final DownloadFileVersion _downloadFileVersion;
  final _subscriptions = <StreamSubscription<Object?>>[];
  TeamFile? _initialFile;

  void load(TeamFile file) {
    _initialFile = file;
    _cancelSubscriptions();
    emit(FileDetailReady(file: file));
    _subscriptions.addAll([
      _watchTeamFile(file.teamId, file.id).listen(_onFile, onError: _fail),
      _watchFileVersions(
        file.teamId,
        file.id,
      ).listen(_onVersions, onError: _fail),
      _watchTeamFolders(file.teamId).listen(_onFolders, onError: (_) {}),
      _watchFileVersionLimit().listen(_onLimit, onError: (_) {}),
    ]);
  }

  void retry() {
    final file = _initialFile;
    if (file != null) load(file);
  }

  Future<void> selectVersion(FileVersion version) async {
    final ready = _ready;
    if (ready == null) return;
    emit(
      ready.copyWith(
        selectedVersionId: version.id,
        content: const FileContentLoading(),
      ),
    );
    final bytesOrFailure = await _downloadFileVersion(version);
    final current = _ready;
    if (current == null || current.selectedVersionId != version.id) return;
    emit(
      current.copyWith(
        content: bytesOrFailure.when(
          FileContentLoaded.new,
          (_) => const FileContentFailed(),
        ),
      ),
    );
  }

  /// Zurück zum aktuellen Stand, z. B. aus dem Hinweis zu einer alten Version.
  Future<void> showCurrentVersion() async {
    final current = _currentVersion;
    if (current != null) await selectVersion(current);
  }

  void _onFile(TeamFile? file) {
    if (file == null) return emit(const FileDetailDeleted());
    final ready = _ready;
    if (ready != null) _emitFollowing(ready, ready.copyWith(file: file));
  }

  void _onVersions(List<FileVersion> versions) {
    final ready = _ready;
    if (ready == null || versions.isEmpty) return;
    _emitFollowing(ready, ready.copyWith(versions: versions));
  }

  /// Wer den aktuellen Stand ansah, folgt einer neuen Version — egal ob
  /// zuerst die Datei oder zuerst der Verlauf ankommt. Eine bewusst gewählte
  /// alte Version bleibt stehen.
  void _emitFollowing(FileDetailReady previous, FileDetailReady next) {
    final wasFollowing =
        previous.selectedVersionId == null ||
        previous.selectedVersionId == previous.file.currentVersionId;
    emit(next);
    final current = next.versions.where(next.isCurrent).firstOrNull;
    if (wasFollowing &&
        current != null &&
        current.id != next.selectedVersionId) {
      unawaited(selectVersion(current));
    }
  }

  void _onFolders(List<TeamFolder> folders) {
    final ready = _ready;
    if (ready != null) emit(ready.copyWith(folders: folders));
  }

  void _onLimit(int limit) {
    final ready = _ready;
    if (ready != null) emit(ready.copyWith(versionLimit: limit));
  }

  FileVersion? get _currentVersion {
    final ready = _ready;
    if (ready == null) return null;
    return ready.versions.where(ready.isCurrent).firstOrNull;
  }

  FileDetailReady? get _ready {
    if (isClosed) return null;
    return switch (state) {
      final FileDetailReady ready => ready,
      _ => null,
    };
  }

  void _fail(Object _) {
    if (!isClosed && state is! FileDetailDeleted) {
      emit(const FileDetailFailure());
    }
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
