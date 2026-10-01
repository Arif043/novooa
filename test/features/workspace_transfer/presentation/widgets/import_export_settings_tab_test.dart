import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/workspace_transfer/domain/usecases/apply_workspace_import.dart';
import 'package:syscat2/features/workspace_transfer/domain/usecases/discard_workspace_import.dart';
import 'package:syscat2/features/workspace_transfer/domain/usecases/export_workspace_to_file.dart';
import 'package:syscat2/features/workspace_transfer/domain/usecases/stage_workspace_import.dart';
import 'package:syscat2/features/workspace_transfer/presentation/cubits/workspace_export_cubit.dart';
import 'package:syscat2/features/workspace_transfer/presentation/cubits/workspace_import_cubit.dart';
import 'package:syscat2/features/workspace_transfer/presentation/widgets/import_export_settings_tab.dart';

import '../../transfer_fakes.dart';

void main() {
  late FakeTransferRepository repository;

  setUp(() async {
    await serviceLocator.reset();
    repository = FakeTransferRepository();
    final files = FakeTransferFileGateway();
    serviceLocator
      ..registerFactory(
        () => WorkspaceExportCubit(ExportWorkspaceToFile(repository, files)),
      )
      ..registerFactory(
        () => WorkspaceImportCubit(
          StageWorkspaceImport(repository, files),
          ApplyWorkspaceImport(repository),
          DiscardWorkspaceImport(repository),
        ),
      );
  });

  tearDown(serviceLocator.reset);

  Future<void> pumpTab(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: ImportExportSettingsTab())),
  );

  testWidgets('offers all four categories for export without triggers', (
    tester,
  ) async {
    await pumpTab(tester);

    for (final label in [
      'Dateien & Ordner',
      'Daten-Collections',
      'Wissensbasis',
      'Aufgaben',
    ]) {
      expect(find.widgetWithText(CheckboxListTile, label), findsOneWidget);
    }
    expect(find.textContaining('Trigger'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'Trigger'), findsNothing);
  });

  testWidgets('previews and applies an import file', (tester) async {
    await pumpTab(tester);

    await tester.ensureVisible(find.text('Export-Datei auswählen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export-Datei auswählen'));
    await tester.pumpAndSettle();

    expect(find.text('Export vom 01.10.2026, 08:30 Uhr'), findsOneWidget);
    expect(find.text('3 Dateien'), findsOneWidget);
    expect(find.text('2 Aufgaben'), findsOneWidget);

    await tester.ensureVisible(find.text('Importieren'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importieren'));
    await tester.pumpAndSettle();

    expect(find.text('Import abgeschlossen.'), findsOneWidget);
    expect(
      repository.appliedCategories,
      sampleStagedImport.contents.categories.toSet(),
    );
  });
}
