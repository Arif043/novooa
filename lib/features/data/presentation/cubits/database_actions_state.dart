import '../../domain/entities/data_failure.dart';

enum DatabaseNoticeKind {
  collectionCreated,
  collectionRenamed,
  collectionDeleted,
  collectionCleared,
  recordsDeleted,
  recordsImported,
  exported,
  failed,
}

/// Einmalige Rückmeldung für eine Snackbar; ohne Gleichheit, damit gleiche Meldungen erneut
/// erscheinen.
class DatabaseNotice {
  const DatabaseNotice(this.kind, {this.name, this.count, this.failure});

  final DatabaseNoticeKind kind;
  final String? name;
  final int? count;
  final DataFailure? failure;
}

class DatabaseActionsState {
  const DatabaseActionsState({this.isBusy = false, this.notice});

  final bool isBusy;
  final DatabaseNotice? notice;
}
