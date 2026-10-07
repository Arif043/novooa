import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/presentation/widgets/model_catalog_list.dart';

import '../../../task_builder/model_inference/model_catalog_test_support.dart';

void main() {
  testWidgets('entfernt ein gecachtes Modell nach Rückfrage aus dem Cache', (
    tester,
  ) async {
    final entry = modelEntry(
      'ocr',
      title: 'Texterkennung',
      origin: ModelOrigin.catalog,
    );
    final cubit = await loadedCatalogCubit(
      tester,
      FakeModelCatalogRepository(),
      local: [entry],
    );
    await tester.pumpWidget(
      hostWithCatalog(
        cubit,
        ModelCatalogList(
          state: cubit.state,
          entries: cubit.state.cachedEntries,
          emptyText: 'Leer',
        ),
      ),
    );

    expect(find.textContaining('2,0 MB'), findsOneWidget);
    await tester.tap(find.byTooltip('Aus dem Cache entfernen'));
    await tester.pumpAndSettle();

    expect(find.textContaining('beim nächsten Lauf erneut'), findsOneWidget);
  });

  testWidgets('zeigt den leeren Zustand', (tester) async {
    final cubit = await loadedCatalogCubit(
      tester,
      FakeModelCatalogRepository(),
    );
    await tester.pumpWidget(
      hostWithCatalog(
        cubit,
        ModelCatalogList(
          state: cubit.state,
          entries: cubit.state.cachedEntries,
          emptyText: 'Noch keine Modelle gecacht.',
        ),
      ),
    );

    expect(find.text('Noch keine Modelle gecacht.'), findsOneWidget);
  });
}
