import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/di/preview_dependency_configuration.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';
import 'package:syscat2/features/knowledge_base/domain/repositories/knowledge_base_repository.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note_draft.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/licensing/domain/repositories/runtime_license_repository.dart';
import 'package:syscat2/features/licensing/domain/entities/runtime_license.dart';

void main() {
  setUp(() async {
    await resetDependencies();
    registerPreviewSessionEvents(serviceLocator);
    await configureDependencies(
      runtimeProfile: RuntimeProfile.forKind(RuntimeKind.standalone),
      standaloneTransport: previewTransport,
    );
  });
  tearDown(resetDependencies);

  test('die Lizenz gilt in der Vorschau ohne Aktivierung als aktiv', () async {
    final statusOrFailure = await serviceLocator<RuntimeLicenseRepository>()
        .loadStatus();

    expect(statusOrFailure.tryGetSuccess()?.state, RuntimeLicenseState.active);
  });

  test('Notizen werden im Speicher angelegt und live gemeldet', () async {
    final repository = serviceLocator<KnowledgeBaseRepository>();
    const team = TeamId('local');
    final emissions = repository.watchNotes(team).map((n) => n.length);
    final expectation = expectLater(emissions, emitsInOrder([0, 1]));

    await Future<void>.delayed(Duration.zero);
    await repository.createNote(
      teamId: team,
      ownerUid: 'local-user',
      draft: const KnowledgeNoteDraft(
        title: 'Erste',
        path: '',
        content: 'Hi',
        outgoingLinks: [],
      ),
    );

    await expectation;
  });

  test('Einzeldokumente und Sammlungen teilen sich einen Pfad', () async {
    final client = serviceLocator<WorkspaceApiClient>();
    await client.put('/v1/file-settings', {'versionLimit': 7});
    final created = await client.post('/v1/folders', {'name': 'Ablage'});

    expect((await client.get('/v1/file-settings'))['versionLimit'], 7);
    expect(created['id'], isNotEmpty);
    await client.delete('/v1/folders/${created['id']}');
    expect((await client.get('/v1/folders'))['items'], isEmpty);
  });
}
