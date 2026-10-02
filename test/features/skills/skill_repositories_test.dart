import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_binary_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';
import 'package:syscat2/features/skills/domain/entities/skill_catalog.dart';
import 'package:syscat2/features/skills/domain/entities/skill_import.dart';
import 'package:syscat2/features/skills/infrastructure/repositories/local_skill_catalog_repository.dart';
import 'package:syscat2/features/skills/infrastructure/repositories/local_skill_import_repository.dart';
import 'package:syscat2/features/skills/infrastructure/repositories/local_skill_repository.dart';

void main() {
  const previewJson = {
    'importId': 'imp-1',
    'candidates': [
      {
        'name': 'pdf',
        'description': 'Verarbeitet PDFs',
        'fileCount': 3,
        'totalBytes': 1200,
        'warnings': ['Hinweis'],
        'nameTaken': true,
      },
    ],
    'rejected': [
      {'directory': 'kaputt', 'reason': 'Beschreibung fehlt'},
    ],
  };

  test('liest die Vorschau eines GitHub-Imports', () async {
    final client = _Api({'/v1/skills/imports': previewJson});

    final result = await LocalSkillImportRepository(
      client,
      _Binary(),
    ).preview(const GitHubImportSource('https://github.com/o/r'));

    final preview = result.tryGetSuccess()!;
    expect(client.posts.single.$2, {
      'github': {'url': 'https://github.com/o/r'},
    });
    expect(preview.importId, 'imp-1');
    expect(preview.candidates.single.nameTaken, isTrue);
    expect(preview.candidates.single.warnings, ['Hinweis']);
    expect(preview.rejected.single.reason, 'Beschreibung fehlt');
  });

  test(
    'sendet Katalog-Kennung, Ordnerdateien und ZIP an die richtigen Routen',
    () async {
      final client = _Api({'/v1/skills/imports': previewJson});
      final binary = _Binary(previewJson);
      final repository = LocalSkillImportRepository(client, binary);

      await repository.preview(const CatalogImportSource('a/b/c'));
      await repository.preview(
        FolderImportSource(
          name: 'skills',
          files: [
            SkillSourceFile(
              path: 'a/SKILL.md',
              bytes: Uint8List.fromList(utf8.encode('x')),
            ),
          ],
        ),
      );
      await repository.preview(
        ArchiveImportSource(
          fileName: 'mein skill.zip',
          bytes: Uint8List.fromList([1, 2]),
        ),
      );

      expect(client.posts[0].$2, {
        'skillsSh': {'id': 'a/b/c'},
      });
      expect(client.posts[1].$2, {
        'folder': {
          'name': 'skills',
          'files': [
            {
              'path': 'a/SKILL.md',
              'contentBase64': base64Encode(utf8.encode('x')),
            },
          ],
        },
      });
      expect(binary.path, '/v1/skills/imports/archive?name=mein+skill.zip');
      expect(binary.contentType, 'application/zip');
    },
  );

  test(
    'übernimmt die Fehlermeldung des Servers und ein generisches Scheitern',
    () async {
      final rejecting = _Api(
        {},
        failure: WorkspaceHttpException(
          400,
          const WorkspaceApiError(
            message: 'Im Archiv wurde kein Skill gefunden.',
          ),
        ),
      );
      final broken = _Api({}, failure: StateError('offline'));

      final server = await LocalSkillImportRepository(
        rejecting,
        _Binary(),
      ).preview(const GitHubImportSource('x'));
      final generic = await LocalSkillImportRepository(
        broken,
        _Binary(),
      ).preview(const GitHubImportSource('x'));

      expect(
        server.tryGetError()!.message,
        'Im Archiv wurde kein Skill gefunden.',
      );
      expect(generic.tryGetError()!.message, 'Der Import ist fehlgeschlagen.');
    },
  );

  test('übernimmt die Auswahl und liest die gespeicherten Skills', () async {
    final client = _Api({
      '/v1/skills/imports/imp%201/commit': {
        'items': [
          {'name': 'pdf', 'description': 'D', 'fileCount': 2, 'warnings': []},
        ],
      },
    });

    final result = await LocalSkillImportRepository(
      client,
      _Binary(),
    ).commit('imp 1', ['pdf']);

    expect(client.posts.single.$2, {
      'names': ['pdf'],
    });
    expect(result.tryGetSuccess()!.single.name, 'pdf');
  });

  test(
    'der Skills-Ordner wird gelesen, Pfad und Löschen gehen an die Runtime',
    () async {
      final client = _Api({
        '/v1/skills': {
          'items': [
            {
              'name': 'pdf',
              'description': 'D',
              'license': 'MIT',
              'fileCount': 3,
              'warnings': ['x'],
            },
          ],
        },
        '/v1/skills/location': {'path': '/data/skills'},
      });
      final repository = LocalSkillRepository(client, _FakeChannel());

      final location = await repository.loadLocation();
      final deleted = await repository.deleteSkill('mein skill');

      expect(location.tryGetSuccess(), '/data/skills');
      expect(deleted.isSuccess(), isTrue);
      expect(client.deletes.single, '/v1/skills/mein%20skill');
    },
  );

  test(
    'der Katalog meldet Verfügbarkeit, Suche, Bestenliste und Prüfungen',
    () async {
      final client = _Api({
        '/v1/skills/catalog/status': {'available': true},
        '/v1/skills/catalog/search?q=react+native': {
          'items': [
            {
              'id': 'expo/skills/rn',
              'name': 'RN',
              'source': 'expo/skills',
              'installs': 5,
            },
          ],
        },
        '/v1/skills/catalog/browse?view=trending&page=1': {
          'items': [],
          'hasMore': true,
        },
        '/v1/skills/catalog/audits?id=a%2Fb%2Fc': {
          'items': [
            {'provider': 'Socket', 'status': 'pass', 'summary': 'ok'},
            {'provider': 'Snyk', 'status': 'komisch', 'summary': 'x'},
          ],
        },
      });
      final catalog = LocalSkillCatalogRepository(client);

      expect(await catalog.isAvailable(), isTrue);
      expect(
        (await catalog.search('react native')).tryGetSuccess()!.single.installs,
        5,
      );
      expect(
        (await catalog.browse(
          CatalogView.trending,
          1,
        )).tryGetSuccess()!.hasMore,
        isTrue,
      );
      final audits = (await catalog.audits('a/b/c')).tryGetSuccess()!;
      expect(audits.map((a) => a.status), [
        CatalogAuditStatus.pass,
        CatalogAuditStatus.warn,
      ]);
    },
  );

  test(
    'ohne erreichbare Runtime gilt der Katalog als nicht verfügbar',
    () async {
      final catalog = LocalSkillCatalogRepository(
        _Api({}, failure: StateError('x')),
      );

      expect(await catalog.isAvailable(), isFalse);
      expect(
        (await catalog.search('react')).tryGetError()!.message,
        'Der Katalog ist nicht erreichbar.',
      );
    },
  );
}

class _Api implements WorkspaceApiClient {
  _Api(this.responses, {this.failure});

  final Map<String, Map<String, Object?>> responses;
  final Object? failure;
  final posts = <(String, Map<String, Object?>)>[];
  final deletes = <String>[];

  @override
  Future<Map<String, Object?>> get(String path) async {
    if (failure != null) throw failure!;
    return responses[path] ?? (throw StateError('Keine Antwort für $path'));
  }

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async {
    posts.add((path, body));
    if (failure != null) throw failure!;
    return responses[path] ?? (throw StateError('Keine Antwort für $path'));
  }

  @override
  Future<Map<String, Object?>> delete(String path) async {
    deletes.add(path);
    return {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Binary implements WorkspaceBinaryClient {
  _Binary([this.response = const {}]);

  final Map<String, Object?> response;
  String? path;
  String? contentType;

  @override
  Future<Map<String, Object?>> postBytes(
    String path, {
    required Uint8List body,
    required String contentType,
  }) async {
    this.path = path;
    this.contentType = contentType;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeChannel implements WorkspaceRealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
