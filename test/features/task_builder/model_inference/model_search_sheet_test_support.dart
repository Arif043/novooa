import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/presentation/cubits/model_catalog_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_filter_option_tile.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_search_filter.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_search_sheet.dart';

import 'model_catalog_test_support.dart';

/// Öffnet die Modellsuche über einen Knopf; [onSelected] erhält das Ergebnis.
Future<void> openModelSearch(
  WidgetTester tester,
  ModelCatalogCubit cubit, {
  SpeechModelDirection? speechDirection,
  ValueChanged<ModelCatalogEntry?>? onSelected,
}) async {
  await tester.pumpWidget(
    hostWithCatalog(
      cubit,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final selected = await showModelSearchSheet(
              context,
              speechDirection: speechDirection,
            );
            onSelected?.call(selected);
          },
          child: const Text('Suchen'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Suchen'));
  await tester.pumpAndSettle();
}

/// Wie ein Desktop mit breitem Fenster: Fenster-Sheet mit Filterspalte.
void useWideDesktop(WidgetTester tester) {
  debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Auf schmalen Bildschirmen liegen die Filter auf einer eigenen Seite.
Future<void> openFilterPage(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(OutlinedButton, 'Filter'));
  await tester.pumpAndSettle();
}

Future<void> showMatches(WidgetTester tester) async {
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
}

Finder filterOption(String label) =>
    find.widgetWithText(ModelFilterOptionTile, label);

/// Option mit Bezeichnung und Trefferzahl, z. B. „Text vorlesen“ mit 2.
Finder filterOptionWithCount(String label, int count) =>
    find.descendant(of: filterOption(label), matching: find.text('$count'));

Future<void> tapFilterOption(WidgetTester tester, String label) async {
  await tester.ensureVisible(filterOption(label));
  await tester.pumpAndSettle();
  await tester.tap(filterOption(label));
  await tester.pumpAndSettle();
}
