import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/skills/domain/entities/skill.dart';
import 'package:syscat2/features/skills/domain/entities/skill_catalog.dart';
import 'package:syscat2/features/skills/domain/entities/skill_failure.dart';
import 'package:syscat2/features/skills/domain/entities/skill_import.dart';
import 'package:syscat2/features/skills/domain/repositories/skill_catalog_repository.dart';
import 'package:syscat2/features/skills/domain/repositories/skill_import_repository.dart';
import 'package:syscat2/features/skills/domain/repositories/skill_repository.dart';
import 'package:syscat2/features/skills/domain/repositories/skill_source_gateway.dart';
import 'package:syscat2/features/skills/domain/usecases/delete_skill.dart';
import 'package:syscat2/features/skills/domain/usecases/skill_catalog_use_cases.dart';
import 'package:syscat2/features/skills/domain/usecases/skill_import_use_cases.dart';
import 'package:syscat2/features/skills/domain/usecases/watch_skills.dart';
import 'package:syscat2/features/skills/presentation/cubits/skill_catalog_cubit.dart';
import 'package:syscat2/features/skills/presentation/cubits/skill_catalog_state.dart';
import 'package:syscat2/features/skills/presentation/cubits/skill_import_cubit.dart';
import 'package:syscat2/features/skills/presentation/cubits/skill_import_state.dart';
import 'package:syscat2/features/skills/presentation/cubits/skills_cubit.dart';
import 'package:syscat2/features/skills/presentation/cubits/skills_state.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

const _pdf = SkillImportCandidate(
  name: 'pdf',
  description: 'PDFs',
  fileCount: 2,
  totalBytes: 10,
  warnings: [],
  nameTaken: false,
);
const _word = SkillImportCandidate(
  name: 'word',
  description: 'Word',
  fileCount: 1,
  totalBytes: 5,
  warnings: [],
  nameTaken: true,
);
const _preview = SkillImportPreview(
  importId: 'imp-1',
  candidates: [_pdf, _word],
  rejected: [],
);

void main() {
  group('SkillImportCubit', () {
    test('zeigt die Vorschau mit allen Kandidaten ausgewählt', () async {
      final cubit = _importCubit();

      await cubit.startFromGitHub(' https://github.com/o/r ');

      expect(cubit.state.step, SkillImportStep.review);
      expect(cubit.state.selected, {'pdf', 'word'});
      expect(cubit.state.canCommit, isTrue);
    });

    test(
      'ein Fehler der Quelle bleibt auf dem Auswahlschritt mit Meldung',
      () async {
        final cubit = _importCubit(
          preview: const Error(SkillFailure('Kein Skill gefunden.')),
        );

        await cubit.start(const GitHubImportSource('x'));

        expect(cubit.state.step, SkillImportStep.chooseSource);
        expect(cubit.state.message, 'Kein Skill gefunden.');
      },
    );

    test(
      'Auswahl lässt sich umschalten; ohne Auswahl ist Übernehmen gesperrt',
      () async {
        final cubit = _importCubit();
        await cubit.start(const GitHubImportSource('x'));

        cubit.toggle('pdf');
        expect(cubit.state.selected, {'word'});
        cubit.selectAll(false);
        expect(cubit.state.canCommit, isFalse);
        cubit.selectAll(true);
        expect(cubit.state.selected, {'pdf', 'word'});
      },
    );

    test('übernimmt die Auswahl und meldet die Anzahl', () async {
      final repository = _ImportRepository();
      final cubit = _importCubit(repository: repository);
      await cubit.start(const GitHubImportSource('x'));
      cubit.toggle('word');

      await cubit.commit();

      expect(repository.committed!.$1, 'imp-1');
      expect(repository.committed!.$2, ['pdf']);
      expect(cubit.state.step, SkillImportStep.done);
      expect(cubit.state.importedCount, 1);
    });

    test('ein Fehler beim Übernehmen führt zurück zur Vorschau', () async {
      final cubit = _importCubit(
        commit: const Error(SkillFailure('Der Import ist abgelaufen.')),
      );
      await cubit.start(const GitHubImportSource('x'));

      await cubit.commit();

      expect(cubit.state.step, SkillImportStep.review);
      expect(cubit.state.message, 'Der Import ist abgelaufen.');
      expect(cubit.state.selected, {'pdf', 'word'});
    });

    test('Katalog-Skills laden ihre Sicherheitsprüfungen nach', () async {
      final cubit = _importCubit(
        audits: const Success([
          CatalogAudit(
            provider: 'Socket',
            status: CatalogAuditStatus.pass,
            summary: 'ok',
          ),
        ]),
      );

      await cubit.startFromCatalog('a/b/c');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.audits.single.provider, 'Socket');
    });

    test('andere Quellen laden keine Prüfungen', () async {
      final catalog = _Catalog();
      final cubit = _importCubit(catalog: catalog);

      await cubit.startFromGitHub('x');
      await Future<void>.delayed(Duration.zero);

      expect(catalog.auditCalls, 0);
    });

    test(
      'abgebrochene Auswahl ändert nichts, ein Lesefehler zeigt Meldung',
      () async {
        final cancelled = _importCubit(
          gateway: _Gateway(const Error(SkillFailure.cancelled)),
        );
        final failed = _importCubit(
          gateway: _Gateway(const Error(SkillFailure('Ordner zu groß.'))),
        );

        await cancelled.pickArchive();
        await failed.pickFolder();

        expect(cancelled.state, const SkillImportState());
        expect(failed.state.message, 'Ordner zu groß.');
      },
    );

    test('eine gewählte ZIP-Datei startet die Vorschau', () async {
      final repository = _ImportRepository();
      final cubit = _importCubit(
        repository: repository,
        gateway: _Gateway(
          Success(ArchiveImportSource(fileName: 'a.zip', bytes: Uint8List(0))),
        ),
      );

      await cubit.pickArchive();

      expect(repository.sources.single, isA<ArchiveImportSource>());
      expect(cubit.state.step, SkillImportStep.review);
    });

    test('restart setzt den Ablauf zurück', () async {
      final cubit = _importCubit();
      await cubit.start(const GitHubImportSource('x'));

      cubit.restart();

      expect(cubit.state, const SkillImportState());
    });
  });

  group('SkillCatalogCubit', () {
    test('ohne Zugang meldet der Katalog "nicht eingerichtet"', () async {
      final cubit = SkillCatalogCubit(
        IsSkillCatalogAvailable(_Catalog(available: false)),
        SearchSkillCatalog(_Catalog()),
        BrowseSkillCatalog(_Catalog()),
      );

      await cubit.load();

      expect(cubit.state.status, SkillCatalogStatus.unavailable);
    });

    test('zeigt zuerst die Bestenliste', () async {
      final catalog = _Catalog();
      final cubit = _catalogCubit(catalog);

      await cubit.load();

      expect(cubit.state.status, SkillCatalogStatus.ready);
      expect(cubit.state.items.single.id, 'a/b/trending');
      expect(catalog.browses, 1);
    });

    test('Eingaben werden entprellt und erst ab zwei Zeichen gesucht', () {
      fakeAsync((async) {
        final catalog = _Catalog();
        final cubit = _catalogCubit(catalog);
        cubit.load();
        async.flushMicrotasks();

        cubit.queryChanged('r');
        cubit.queryChanged('re');
        cubit.queryChanged('rea');
        cubit.queryChanged('reac');
        async.elapse(
          SkillCatalogCubit.debounce - const Duration(milliseconds: 1),
        );
        expect(catalog.searches, isEmpty);
        async.elapse(const Duration(milliseconds: 2));
        async.flushMicrotasks();

        expect(catalog.searches, ['reac']);
        expect(cubit.state.items.single.id, 'a/b/reac');
      });
    });

    test(
      'ein Fehler der Suche zeigt die Meldung und lässt sich wiederholen',
      () async {
        final catalog = _Catalog(
          searchFailure: const SkillFailure(
            'Zu viele Anfragen an skills.sh. Bitte in 12 Sekunden erneut versuchen.',
          ),
        );
        final cubit = _catalogCubit(catalog);
        await cubit.load();

        cubit.queryChanged('react');
        await Future<void>.delayed(
          SkillCatalogCubit.debounce + const Duration(milliseconds: 50),
        );
        expect(cubit.state.status, SkillCatalogStatus.failure);
        expect(cubit.state.message, contains('12 Sekunden'));

        catalog.searchFailure = null;
        await cubit.retry();
        expect(cubit.state.status, SkillCatalogStatus.ready);
      },
    );
  });

  group('SkillsCubit', () {
    test('lädt die Skills', () async {
      final repository = _SkillRepository();
      final cubit = _skillsCubit(repository);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, SkillsStatus.ready);
      expect(cubit.state.skills.single.name, 'pdf');
    });

    test('Löschen meldet Erfolg und Fehler als Nachricht', () async {
      final repository = _SkillRepository();
      final cubit = _skillsCubit(repository);

      await cubit.delete('pdf');
      expect(cubit.state.message, 'Fähigkeit „pdf“ gelöscht.');
      cubit.messageShown();
      expect(cubit.state.message, isNull);

      repository.deleteFailure = const SkillFailure('Nicht gefunden.');
      await cubit.delete('pdf');
      expect(cubit.state.message, 'Nicht gefunden.');
    });

    test('ein Fehler des Ordners zeigt den Fehlerzustand', () async {
      final repository = _SkillRepository()..watchError = true;
      final cubit = _skillsCubit(repository);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, SkillsStatus.failure);
    });
  });
}

SkillImportCubit _importCubit({
  _ImportRepository? repository,
  Result<SkillImportPreview, SkillFailure> preview = const Success(_preview),
  Result<List<Skill>, SkillFailure>? commit,
  Result<List<CatalogAudit>, SkillFailure> audits = const Success([]),
  _Catalog? catalog,
  SkillSourceGateway? gateway,
}) {
  final imports =
      repository ??
      _ImportRepository(previewResult: preview, commitResult: commit);
  return SkillImportCubit(
    PreviewSkillImport(imports),
    CommitSkillImport(imports),
    LoadSkillAudits(catalog ?? _Catalog(auditResult: audits)),
    gateway ?? _Gateway(const Error(SkillFailure.cancelled)),
  );
}

SkillCatalogCubit _catalogCubit(_Catalog catalog) => SkillCatalogCubit(
  IsSkillCatalogAvailable(catalog),
  SearchSkillCatalog(catalog),
  BrowseSkillCatalog(catalog),
);

SkillsCubit _skillsCubit(_SkillRepository repository) => SkillsCubit(
  WatchSkills(repository),
  DeleteSkill(repository),
  GetCurrentTeamId(_Teams()),
);

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team-1');
}

class _ImportRepository implements SkillImportRepository {
  _ImportRepository({
    this.previewResult = const Success(_preview),
    this.commitResult,
  });

  final Result<SkillImportPreview, SkillFailure> previewResult;
  final Result<List<Skill>, SkillFailure>? commitResult;
  final sources = <SkillImportSource>[];
  (String, List<String>)? committed;

  @override
  Future<Result<SkillImportPreview, SkillFailure>> preview(
    SkillImportSource source,
  ) async {
    sources.add(source);
    return previewResult;
  }

  @override
  Future<Result<List<Skill>, SkillFailure>> commit(
    String importId,
    List<String> names,
  ) async {
    committed = (importId, names);
    return commitResult ??
        Success([
          for (final name in names)
            Skill(name: name, description: '', fileCount: 1),
        ]);
  }
}

class _Gateway implements SkillSourceGateway {
  _Gateway(this.result);

  final Result<SkillImportSource, SkillFailure> result;

  @override
  bool get canPickFolder => true;

  @override
  Future<Result<SkillImportSource, SkillFailure>> pickArchive() async => result;

  @override
  Future<Result<SkillImportSource, SkillFailure>> pickFolder() async => result;
}

class _Catalog implements SkillCatalogRepository {
  _Catalog({
    this.available = true,
    this.searchFailure,
    this.auditResult = const Success([]),
  });

  final bool available;
  SkillFailure? searchFailure;
  final Result<List<CatalogAudit>, SkillFailure> auditResult;
  final searches = <String>[];
  var browses = 0;
  var auditCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<Result<List<CatalogSkill>, SkillFailure>> search(String query) async {
    searches.add(query);
    final failure = searchFailure;
    if (failure != null) return Error(failure);
    return Success([
      CatalogSkill(id: 'a/b/$query', name: query, source: 'a/b', installs: 1),
    ]);
  }

  @override
  Future<Result<CatalogPage, SkillFailure>> browse(
    CatalogView view,
    int page,
  ) async {
    browses++;
    return const Success(
      CatalogPage(
        items: [
          CatalogSkill(
            id: 'a/b/trending',
            name: 'trending',
            source: 'a/b',
            installs: 9,
          ),
        ],
        hasMore: false,
      ),
    );
  }

  @override
  Future<Result<List<CatalogAudit>, SkillFailure>> audits(
    String skillId,
  ) async {
    auditCalls++;
    return auditResult;
  }
}

class _SkillRepository implements SkillRepository {
  SkillFailure? deleteFailure;
  bool watchError = false;

  @override
  Stream<List<Skill>> watchSkills(TeamId teamId) {
    if (watchError) return Stream.error(StateError('kaputt'));
    return Stream.value(const [
      Skill(name: 'pdf', description: 'D', fileCount: 2),
    ]);
  }

  @override
  Future<Result<Unit, SkillFailure>> deleteSkill(String name) async {
    final failure = deleteFailure;
    return failure == null ? const Success(unit) : Error(failure);
  }
}
