import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/widgets/adaptive_sheet.dart';

/// Logische Fenstergröße; `setSurfaceSize` wirkt auf die MediaQuery nicht.
void _useWindowSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          captured = context;
          return const Scaffold(body: Text('Fenster'));
        },
      ),
    ),
  );
  return captured;
}

void main() {
  testWidgets('mobil: Bottom Sheet mit Greifer', (tester) async {
    final context = await _pumpHost(tester);
    final styles = <AdaptiveSheetStyle>[];

    showAdaptiveSheet<void>(
      context: context,
      builder: (_, style) {
        styles.add(style);
        return const Text('Inhalt');
      },
    );
    await tester.pumpAndSettle();

    expect(styles.last, AdaptiveSheetStyle.bottom);
    expect(find.byType(BottomSheet), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('iOS behält das Bottom Sheet', (tester) async {
    final context = await _pumpHost(tester);

    showAdaptiveSheet<void>(
      context: context,
      builder: (_, _) => const Text('Inhalt'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  group('Desktop (macOS-Sheet)', () {
    testWidgets('schwebt als Karte oben mittig und ist kein Bottom Sheet', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      final styles = <AdaptiveSheetStyle>[];

      showAdaptiveSheet<void>(
        context: context,
        builder: (_, style) {
          styles.add(style);
          return const SizedBox(height: 200, child: Text('Inhalt'));
        },
      );
      await tester.pumpAndSettle();

      expect(styles.last, AdaptiveSheetStyle.window);
      expect(find.byType(BottomSheet), findsNothing);
      final card = tester.getRect(
        find
            .ancestor(of: find.text('Inhalt'), matching: find.byType(Material))
            .first,
      );
      final window = tester.getSize(find.byType(Scaffold).first);
      expect(card.center.dx, closeTo(window.width / 2, 1));
      expect(card.top, lessThan(window.height / 3));
      expect(card.width, lessThanOrEqualTo(480));
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('ist modal: Tippen daneben schließt nicht, Escape bricht ab', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      Object? result = 'offen';
      showAdaptiveSheet<String>(
        context: context,
        builder: (_, _) => const SizedBox(height: 200, child: Text('Inhalt')),
      ).then((value) => result = value);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 590));
      await tester.pumpAndSettle();
      expect(find.text('Inhalt'), findsOneWidget);
      expect(result, 'offen');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Inhalt'), findsNothing);
      expect(result, isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('Windows und Linux nutzen ebenfalls die Fensterform', (
      tester,
    ) async {
      final context = await _pumpHost(tester);

      showAdaptiveSheet<void>(
        context: context,
        builder: (_, _) => const Text('Inhalt'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Inhalt'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });

  group('Breite entscheidet', () {
    testWidgets('schmales Fenster auf einem Desktop-System: Bottom Sheet', (
      tester,
    ) async {
      _useWindowSize(tester, const Size(425, 876));
      final context = await _pumpHost(tester);
      final styles = <AdaptiveSheetStyle>[];

      showAdaptiveSheet<void>(
        context: context,
        builder: (_, style) {
          styles.add(style);
          return const Text('Inhalt');
        },
      );
      await tester.pumpAndSettle();

      expect(styles.last, AdaptiveSheetStyle.bottom);
      expect(find.byType(BottomSheet), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    for (final (width, expected) in [
      (599.0, AdaptiveSheetStyle.bottom),
      (600.0, AdaptiveSheetStyle.window),
    ]) {
      testWidgets('Grenze: $width px ergibt $expected', (tester) async {
        _useWindowSize(tester, Size(width, 800));
        final context = await _pumpHost(tester);
        final styles = <AdaptiveSheetStyle>[];

        showAdaptiveSheet<void>(
          context: context,
          builder: (_, style) {
            styles.add(style);
            return const Text('Inhalt');
          },
        );
        await tester.pumpAndSettle();

        expect(styles.last, expected);
      }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
    }

    testWidgets(
      'breites Fenster auf einem Handy-System bleibt beim Bottom Sheet',
      (tester) async {
        _useWindowSize(tester, const Size(1000, 800));
        final context = await _pumpHost(tester);

        showAdaptiveSheet<void>(
          context: context,
          builder: (_, _) => const Text('Inhalt'),
        );
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  });

  group('SheetFooter', () {
    Widget footer({VoidCallback? onBack, VoidCallback? onConfirm}) {
      return MaterialApp(
        home: Scaffold(
          body: SheetFooter(
            onCancel: () {},
            onBack: onBack,
            confirmLabel: 'Übernehmen',
            onConfirm: onConfirm,
          ),
        ),
      );
    }

    testWidgets('zeigt Abbrechen immer, Zurück und Bestätigen getrennt', (
      tester,
    ) async {
      await tester.pumpWidget(footer(onBack: () {}));
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(find.text('Zurück'), findsOneWidget);
      expect(find.text('Übernehmen'), findsNothing);

      await tester.pumpWidget(footer(onConfirm: () {}));
      expect(find.text('Abbrechen'), findsOneWidget);
      expect(find.text('Übernehmen'), findsOneWidget);
      expect(find.text('Zurück'), findsNothing);
    });

    test('Cancel, Back und Done zugleich sind nicht zulässig', () {
      expect(
        () => SheetFooter(onCancel: () {}, onBack: () {}, onConfirm: () {}),
        throwsAssertionError,
      );
    });
  });
}
