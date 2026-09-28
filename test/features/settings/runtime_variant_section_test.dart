import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_kind_store.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';
import 'package:syscat2/features/settings/presentation/widgets/runtime_variant_section.dart';

// Deckt den Wechsel der Betriebsvariante in den Einstellungen ab: die Wahl
// wird persistiert und der Neustart-Hinweis erscheint erst, wenn sich die
// Wahl tatsächlich von der laufenden Variante unterscheidet.
void main() {
  const restartHint =
      'Gespeichert. Starte novooa neu, damit die Variante übernommen wird.';

  Future<_MemoryKindStore> pumpSection(
    WidgetTester tester, {
    required RuntimeKind currentKind,
  }) async {
    final store = _MemoryKindStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RuntimeVariantSection(
              currentKind: currentKind,
              store: store,
            ),
          ),
        ),
      ),
    );
    return store;
  }

  testWidgets('zeigt beide Varianten mit der laufenden vorausgewählt', (
    tester,
  ) async {
    await pumpSection(tester, currentKind: RuntimeKind.cloud);

    expect(find.text('Cloud'), findsOneWidget);
    expect(find.text('Eigene Runtime'), findsOneWidget);
    expect(find.text(restartHint), findsNothing);
    expect(
      tester
          .widget<RadioGroup<RuntimeKind>>(
            find.byType(RadioGroup<RuntimeKind>),
          )
          .groupValue,
      RuntimeKind.cloud,
    );
  });

  testWidgets('speichert die neue Variante und zeigt den Neustart-Hinweis', (
    tester,
  ) async {
    final store = await pumpSection(tester, currentKind: RuntimeKind.cloud);

    await tester.tap(find.text('Eigene Runtime'));
    await tester.pumpAndSettle();

    expect(store.saved, [RuntimeKind.standalone]);
    expect(find.text(restartHint), findsOneWidget);
    expect(
      tester
          .widget<RadioGroup<RuntimeKind>>(
            find.byType(RadioGroup<RuntimeKind>),
          )
          .groupValue,
      RuntimeKind.standalone,
    );
  });

  testWidgets('aus der Standalone-Variante führt der Weg zurück zur Cloud', (
    tester,
  ) async {
    final store = await pumpSection(tester, currentKind: RuntimeKind.standalone);

    await tester.tap(find.text('Cloud'));
    await tester.pumpAndSettle();

    expect(store.saved, [RuntimeKind.cloud]);
    expect(find.text(restartHint), findsOneWidget);
  });

  testWidgets(
    'ein Tipp auf die bereits laufende Variante speichert nichts und zeigt '
    'keinen Hinweis',
    (tester) async {
      final store = await pumpSection(tester, currentKind: RuntimeKind.cloud);

      await tester.tap(find.text('Cloud'));
      await tester.pumpAndSettle();

      expect(store.saved, isEmpty);
      expect(find.text(restartHint), findsNothing);
    },
  );

  testWidgets('ein erneuter Wechsel zurück nimmt den Hinweis wieder weg', (
    tester,
  ) async {
    final store = await pumpSection(tester, currentKind: RuntimeKind.cloud);

    await tester.tap(find.text('Eigene Runtime'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cloud'));
    await tester.pumpAndSettle();

    expect(store.saved, [RuntimeKind.standalone, RuntimeKind.cloud]);
    expect(find.text(restartHint), findsNothing);
  });
}

class _MemoryKindStore implements RuntimeKindStore {
  final saved = <RuntimeKind>[];

  @override
  Future<RuntimeKind?> load() async => saved.isEmpty ? null : saved.last;

  @override
  Future<void> save(RuntimeKind kind) async => saved.add(kind);
}
