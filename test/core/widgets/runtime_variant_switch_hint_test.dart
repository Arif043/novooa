import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_kind_store.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';
import 'package:syscat2/core/widgets/runtime_variant_switch_hint.dart';

// Deckt den Variantenwechsel **vor** der Anmeldung ab. Ohne ihn käme man
// nie zur eigenen Runtime, wenn man kein Cloud-Konto hat — die Auswahl in
// den Einstellungen liegt hinter dem Login.
void main() {
  Future<_MemoryKindStore> pumpHint(
    WidgetTester tester, {
    required RuntimeKind currentKind,
    bool isEnabled = true,
  }) async {
    final store = _MemoryKindStore();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RuntimeVariantSwitchHint(
            currentKind: currentKind,
            isEnabled: isEnabled,
            store: store,
          ),
        ),
      ),
    );
    return store;
  }

  testWidgets('bietet aus der Cloud den Weg zur eigenen Runtime an', (
    tester,
  ) async {
    await pumpHint(tester, currentKind: RuntimeKind.cloud);

    expect(find.text('Du nutzt novooa Standalone?'), findsOneWidget);
    expect(find.text('Zur eigenen Runtime wechseln'), findsOneWidget);
  });

  testWidgets('bietet aus der eigenen Runtime den Weg zur Cloud an', (
    tester,
  ) async {
    await pumpHint(tester, currentKind: RuntimeKind.standalone);

    expect(find.text('Du nutzt die novooa-Cloud?'), findsOneWidget);
    expect(find.text('Zur Cloud wechseln'), findsOneWidget);
  });

  testWidgets('speichert die Zielvariante und zeigt den Neustart-Hinweis', (
    tester,
  ) async {
    final store = await pumpHint(tester, currentKind: RuntimeKind.cloud);

    await tester.tap(find.text('Zur eigenen Runtime wechseln'));
    await tester.pumpAndSettle();

    expect(store.saved, [RuntimeKind.standalone]);
    expect(find.text(runtimeRestartHint), findsOneWidget);
    expect(find.text('Zur eigenen Runtime wechseln'), findsNothing);
  });

  testWidgets('während des Absendens ist der Wechsel gesperrt', (tester) async {
    final store = await pumpHint(
      tester,
      currentKind: RuntimeKind.cloud,
      isEnabled: false,
    );

    await tester.tap(find.text('Zur eigenen Runtime wechseln'));
    await tester.pumpAndSettle();

    expect(store.saved, isEmpty);
    expect(find.text(runtimeRestartHint), findsNothing);
  });
}

class _MemoryKindStore implements RuntimeKindStore {
  final saved = <RuntimeKind>[];

  @override
  Future<RuntimeKind?> load() async => saved.isEmpty ? null : saved.last;

  @override
  Future<void> save(RuntimeKind kind) async => saved.add(kind);
}
