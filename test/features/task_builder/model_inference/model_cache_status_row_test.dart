import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_cache_status.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/presentation/cubits/model_catalog_cubit.dart';
import 'package:syscat2/features/machine_learning/presentation/cubits/model_catalog_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_cache_status_row.dart';

import 'model_catalog_test_support.dart';

void main() {
  Future<void> pumpRow(
    WidgetTester tester,
    ModelCatalogCubit cubit,
    ModelCatalogState state,
  ) => tester.pumpWidget(
    hostWithCatalog(cubit, ModelCacheStatusRow(modelId: 'ocr', state: state)),
  );

  testWidgets('zeigt den laufenden Download', (tester) async {
    final cubit = await loadedCatalogCubit(
      tester,
      FakeModelCatalogRepository(),
    );
    await pumpRow(
      tester,
      cubit,
      const ModelCatalogState(
        cacheStatuses: {
          'ocr': ModelCacheStatus(
            modelId: 'ocr',
            state: ModelCacheState.downloading,
          ),
        },
      ),
    );

    expect(find.text('Wird geladen …'), findsOneWidget);
  });

  testWidgets('zeigt ein gecachtes Modell als bereit', (tester) async {
    final cubit = await loadedCatalogCubit(
      tester,
      FakeModelCatalogRepository(),
    );
    await pumpRow(
      tester,
      cubit,
      ModelCatalogState(
        entries: [modelEntry('ocr', origin: ModelOrigin.catalog)],
      ),
    );

    expect(find.text('Gecacht und bereit'), findsOneWidget);
  });

  testWidgets('bietet nach einem Fehler einen neuen Versuch an', (
    tester,
  ) async {
    final repository = FakeModelCatalogRepository();
    final cubit = await loadedCatalogCubit(tester, repository);
    await pumpRow(
      tester,
      cubit,
      const ModelCatalogState(
        cacheStatuses: {
          'ocr': ModelCacheStatus(
            modelId: 'ocr',
            state: ModelCacheState.failed,
            message: 'Netzwerkfehler.',
          ),
        },
      ),
    );

    expect(find.text('Netzwerkfehler.'), findsOneWidget);
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pump();

    expect(repository.cachedModelIds, ['ocr']);
  });

  testWidgets('lädt ein noch nicht gecachtes Modell auf Wunsch', (
    tester,
  ) async {
    final repository = FakeModelCatalogRepository();
    final cubit = await loadedCatalogCubit(tester, repository);
    await pumpRow(tester, cubit, const ModelCatalogState());

    await tester.tap(find.text('Jetzt laden'));
    await tester.pump();

    expect(repository.cachedModelIds, ['ocr']);
  });
}
