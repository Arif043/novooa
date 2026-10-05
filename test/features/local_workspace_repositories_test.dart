import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/files/domain/entities/upload_file_input.dart';
import 'package:syscat2/features/files/infrastructure/repositories/local_team_file_repository.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note_draft.dart';
import 'package:syscat2/features/knowledge_base/infrastructure/repositories/local_knowledge_base_repository.dart';
import 'package:syscat2/features/schedule/infrastructure/repositories/local_task_trigger_repository.dart';

// `watchWorkspaceChannel` lädt beim ersten Listener sofort per `load()` —
// unabhängig davon, ob der Realtime-Kanal erfolgreich verbindet. Für diese
// Mapping-Tests reicht daher ein Kanal auf eine unerreichbare Adresse, mit
// einem eigenen, nicht-aufzeichnenden Client für den Ticket-Abruf — sonst
// würde dessen `POST /v1/realtime/ticket` sowohl die `lastPostPath`-
// Aufzeichnung als auch den strikten Endpunkt-`switch` von `_LocalClient`
// durcheinanderbringen.
WorkspaceRealtimeChannel _fakeChannel() =>
    WorkspaceRealtimeChannel(Uri.parse('http://127.0.0.1:0'), _NoopClient());

void main() {
  test('loads and saves local knowledge notes', () async {
    final client = _LocalClient();
    final repository = LocalKnowledgeBaseRepository(client, _fakeChannel());

    final notes = await repository.watchNotes(const TeamId('team-1')).first;
    final noteOrFailure = await repository.createNote(
      teamId: const TeamId('team-1'),
      ownerUid: 'user-1',
      draft: const KnowledgeNoteDraft(
        title: 'Neu',
        path: 'neu.md',
        content: '# Neu',
        outgoingLinks: [],
      ),
    );

    expect(notes.single.title, 'Index');
    expect(noteOrFailure, isA<Success>());
    expect(client.lastPostPath, '/v1/knowledge-notes');
  });

  test('maps local task triggers', () async {
    final triggers = await LocalTaskTriggerRepository(
      _LocalClient(),
      _fakeChannel(),
      Uri.parse('http://runtime.test'),
    ).watchTriggers().first;

    expect(triggers.single.taskTitle, 'Tägliche Aufgabe');
    expect(triggers.single.schedule?.timeOfDay, '09:00');
  });

  test('uploads and downloads local file versions', () async {
    final client = _LocalClient();
    final repository = LocalTeamFileRepository(client, _fakeChannel());
    final fileOrFailure = await repository.uploadFile(
      teamId: const TeamId('team-1'),
      ownerUid: 'user-1',
      folderId: null,
      input: UploadFileInput(
        name: 'notiz.txt',
        bytes: Uint8List.fromList([72, 97, 108, 108, 111]),
        sizeBytes: 5,
        contentType: 'text/plain',
      ),
    );
    final files = await repository.watchFiles(const TeamId('team-1')).first;
    final versions = await repository
        .watchVersions(const TeamId('team-1'), files.single.id)
        .first;
    final bytesOrFailure = await repository.downloadVersion(versions.single);

    expect(fileOrFailure, isA<Success>());
    expect(client.lastPostPath, '/v1/files');
    expect(bytesOrFailure, isA<Success>());
    bytesOrFailure.when(
      (bytes) => expect(bytes, Uint8List.fromList([72, 97, 108, 108, 111])),
      (_) => fail('Die Version sollte heruntergeladen werden.'),
    );
  });
}

class _LocalClient extends WorkspaceApiClient {
  String? lastPostPath;

  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> get(String path) async => switch (path) {
    '/v1/knowledge-notes' => {
      'items': [_note()],
    },
    '/v1/task-triggers' => {
      'items': [_trigger()],
    },
    '/v1/files' => {
      'items': [_file()],
    },
    '/v1/folders' => const {'items': []},
    '/v1/files/file-1/versions' => {
      'items': [_version()],
    },
    '/v1/files/file-1/versions/version-1/content' => {
      'contentBase64': 'SGFsbG8=',
    },
    _ => throw StateError('Unerwarteter GET-Endpunkt: $path'),
  };

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async {
    lastPostPath = path;
    return switch (path) {
      '/v1/knowledge-notes' => _note(),
      '/v1/files' => _file(),
      _ => throw StateError('Unerwarteter POST-Endpunkt: $path'),
    };
  }

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async => _note();

  Map<String, Object?> _note() => {
    'id': 'note-1',
    'knowledgeBaseId': 'default',
    'title': 'Index',
    'path': 'index.md',
    'content': '# Index',
    'outgoingLinks': const <String>[],
    'updatedAt': '2026-09-08T10:00:00Z',
  };

  Map<String, Object?> _trigger() => {
    'id': 'trigger-1',
    'teamId': 'team-1',
    'taskId': 'task-1',
    'taskTitle': 'Tägliche Aufgabe',
    'type': 'schedule',
    'enabled': true,
    'config': {
      'kind': 'daily',
      'timezone': 'Europe/Berlin',
      'timeOfDay': '09:00',
      'weekdays': const <int>[],
      'slots': const <Object?>[],
    },
    'eventConfig': const <String, Object?>{},
    'policy': {'ifRunning': 'skipIfRunning'},
    'nextRunAt': '2026-09-09T07:00:00Z',
    'lastRunAt': null,
    'lastRunId': null,
  };

  Map<String, Object?> _file() => {
    'id': 'file-1',
    'teamId': 'team-1',
    'ownerUid': 'user-1',
    'displayName': 'notiz.txt',
    'storagePath': 'teams/team-1/files/file-1/versions/version-1/notiz.txt',
    'currentVersionId': 'version-1',
    'contentType': 'text/plain',
    'sizeBytes': 5,
    'createdAt': '2026-09-08T10:00:00Z',
    'updatedAt': '2026-09-08T10:00:00Z',
    'currentVersionCreatedAt': '2026-09-08T10:00:00Z',
    'folderId': null,
  };

  Map<String, Object?> _version() => {
    'id': 'version-1',
    'fileId': 'file-1',
    'teamId': 'team-1',
    'createdByUid': 'user-1',
    'displayName': 'notiz.txt',
    'storagePath': 'teams/team-1/files/file-1/versions/version-1/notiz.txt',
    'contentType': 'text/plain',
    'sizeBytes': 5,
    'createdAt': '2026-09-08T10:00:00Z',
  };
}

class _NoopClient extends WorkspaceApiClient {
  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> get(String path) async => const {};

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async => const {};

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async => const {};
}
