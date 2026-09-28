import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';
import 'package:syscat2/core/runtime/runtime_variant_switcher.dart';
import 'package:syscat2/core/widgets/runtime_variant_switch_hint.dart';

// Deckt den Variantenwechsel **vor** der Anmeldung ab. Ohne ihn käme man
// nie zur eigenen Runtime, wenn man kein Cloud-Konto hat — die Auswahl in
// den Einstellungen liegt hinter dem Login.
void main() {
  Future<_FakeSwitcher> pumpHint(
    WidgetTester tester, {
    required RuntimeKind currentKind,
    bool isEnabled = true,
  }) async {
    final switcher = _FakeSwitcher();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RuntimeVariantSwitchHint(
            currentKind: currentKind,
            isEnabled: isEnabled,
            switcher: switcher,
          ),
        ),
      ),
    );
    return switcher;
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

  testWidgets(
    'ruft beim Tippen switchTo auf und zeigt währenddessen den '
    'Wechsel-Hinweis statt des Neustart-Hinweises',
    (tester) async {
      final switcher = await pumpHint(tester, currentKind: RuntimeKind.cloud);

      await tester.tap(find.text('Zur eigenen Runtime wechseln'));
      await tester.pump();

      expect(switcher.requested, [RuntimeKind.standalone]);
      expect(find.text(runtimeVariantSwitchingHint), findsOneWidget);
      expect(find.text('Zur eigenen Runtime wechseln'), findsNothing);
    },
  );

  testWidgets('während des Absendens ist der Wechsel gesperrt', (tester) async {
    final switcher = await pumpHint(
      tester,
      currentKind: RuntimeKind.cloud,
      isEnabled: false,
    );

    await tester.tap(find.text('Zur eigenen Runtime wechseln'));
    await tester.pump();

    expect(switcher.requested, isEmpty);
    expect(find.text(runtimeVariantSwitchingHint), findsNothing);
  });
}

/// `switchTo` schließt absichtlich nie von selbst ab — in echt ersetzt es
/// die gesamte Anwendung per `runApp` und kehrt nie "normal" zurück. Der
/// nie erfüllte Future macht den Wechsel-Hinweis testbar, ohne dass der
/// Test auf ein `pumpAndSettle`-Timeout liefe.
class _FakeSwitcher implements RuntimeVariantSwitcher {
  final requested = <RuntimeKind>[];
  final _completer = Completer<void>();

  @override
  Future<void> switchTo(RuntimeKind kind) {
    requested.add(kind);
    return _completer.future;
  }
}
