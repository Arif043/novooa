import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';
import 'package:syscat2/core/runtime/runtime_variant_switcher.dart';
import 'package:syscat2/core/widgets/runtime_variant_switch_hint.dart';
import 'package:syscat2/features/settings/presentation/widgets/runtime_variant_section.dart';

// Deckt den Wechsel der Betriebsvariante in den Einstellungen ab: Der
// Wechsel passiert zur Laufzeit (kein Neustart), der Hinweis zeigt sich nur
// während des laufenden Wechsels.
void main() {
  Future<_FakeSwitcher> pumpSection(
    WidgetTester tester, {
    required RuntimeKind currentKind,
  }) async {
    final switcher = _FakeSwitcher();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RuntimeVariantSection(
              currentKind: currentKind,
              switcher: switcher,
            ),
          ),
        ),
      ),
    );
    return switcher;
  }

  testWidgets('zeigt beide Varianten mit der laufenden vorausgewählt', (
    tester,
  ) async {
    await pumpSection(tester, currentKind: RuntimeKind.cloud);

    expect(find.text('Cloud'), findsOneWidget);
    expect(find.text('Eigene Runtime'), findsOneWidget);
    expect(find.text(runtimeVariantSwitchingHint), findsNothing);
    expect(
      tester
          .widget<RadioGroup<RuntimeKind>>(
            find.byType(RadioGroup<RuntimeKind>),
          )
          .groupValue,
      RuntimeKind.cloud,
    );
  });

  testWidgets(
    'ruft beim Wechsel switchTo auf und zeigt währenddessen den '
    'Wechsel-Hinweis',
    (tester) async {
      final switcher = await pumpSection(tester, currentKind: RuntimeKind.cloud);

      await tester.tap(find.text('Eigene Runtime'));
      await tester.pump();

      expect(switcher.requested, [RuntimeKind.standalone]);
      expect(find.text(runtimeVariantSwitchingHint), findsOneWidget);
    },
  );

  testWidgets('aus der Standalone-Variante führt der Weg zurück zur Cloud', (
    tester,
  ) async {
    final switcher = await pumpSection(
      tester,
      currentKind: RuntimeKind.standalone,
    );

    await tester.tap(find.text('Cloud'));
    await tester.pump();

    expect(switcher.requested, [RuntimeKind.cloud]);
  });

  testWidgets(
    'ein Tipp auf die bereits laufende Variante ruft switchTo nicht auf',
    (tester) async {
      final switcher = await pumpSection(tester, currentKind: RuntimeKind.cloud);

      await tester.tap(find.text('Cloud'));
      await tester.pump();

      expect(switcher.requested, isEmpty);
      expect(find.text(runtimeVariantSwitchingHint), findsNothing);
    },
  );

  testWidgets(
    'ein zweiter Tipp während eines laufenden Wechsels wird ignoriert',
    (tester) async {
      final switcher = await pumpSection(tester, currentKind: RuntimeKind.cloud);

      await tester.tap(find.text('Eigene Runtime'));
      await tester.pump();
      await tester.tap(find.text('Cloud'));
      await tester.pump();

      expect(switcher.requested, [RuntimeKind.standalone]);
    },
  );
}

/// `switchTo` schließt absichtlich nie von selbst ab — in echt ersetzt es
/// die gesamte Anwendung per `runApp` und kehrt nie "normal" zurück.
class _FakeSwitcher implements RuntimeVariantSwitcher {
  final requested = <RuntimeKind>[];
  final _completer = Completer<void>();

  @override
  Future<void> switchTo(RuntimeKind kind) {
    requested.add(kind);
    return _completer.future;
  }
}
