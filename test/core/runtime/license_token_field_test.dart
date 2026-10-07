import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/license_token_field.dart';

void main() {
  testWidgets('zeigt 16 Einzelfelder und springt beim Tippen weiter', (
    tester,
  ) async {
    final tokens = await _pumpField(tester);

    expect(find.byType(TextField), findsNWidgets(16));
    await tester.enterText(_cell(0), 'a');
    await tester.pump();

    expect(_text(tester, 0), 'A');
    expect(_focusedCell(tester), 1);
    expect(tokens.last, 'A');
  });

  testWidgets('verteilt einen eingefügten Token mit Bindestrichen auf alle '
      'Felder', (tester) async {
    final tokens = await _pumpField(tester);

    await tester.enterText(_cell(0), 'a3k9-n7p2-q4r6-t8w5');
    await tester.pump();

    expect(tokens.last, 'A3K9N7P2Q4R6T8W5');
    expect(_text(tester, 15), '5');
  });

  testWidgets('lässt nur erlaubte Zeichen zu (ohne I, O, 0, 1)', (
    tester,
  ) async {
    final tokens = await _pumpField(tester);

    await tester.enterText(_cell(0), 'IO01B');
    await tester.pump();

    expect(tokens.last, 'B');
  });

  testWidgets('Rücktaste in einem leeren Feld löscht das vorige Zeichen', (
    tester,
  ) async {
    final tokens = await _pumpField(tester);
    await tester.enterText(_cell(0), 'AB');
    await tester.pump();
    expect(_focusedCell(tester), 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(_focusedCell(tester), 1);
    expect(tokens.last, 'A');
  });

  testWidgets('zeigt eine Fehlermeldung unter den Feldern', (tester) async {
    await _pumpField(tester, errorText: 'Token unbekannt.');

    expect(find.text('Token unbekannt.'), findsOneWidget);
  });

  testWidgets('zeigt alle 16 Felder in einer Reihe, gruppiert zu je vier', (
    tester,
  ) async {
    await _pumpField(tester, width: 856);

    final rows = {
      for (var index = 0; index < 16; index++)
        tester.getTopLeft(_cell(index)).dy,
    };
    expect(rows, hasLength(1));
    final inGroup =
        tester.getTopLeft(_cell(1)).dx - tester.getTopRight(_cell(0)).dx;
    final betweenGroups =
        tester.getTopLeft(_cell(4)).dx - tester.getTopRight(_cell(3)).dx;
    expect(betweenGroups, greaterThan(inGroup));
    final size = tester.getSize(find.byType(TextField).first);
    expect(size.width, greaterThanOrEqualTo(48));
  });

  testWidgets('die Felder sind quadratisch', (tester) async {
    for (final width in [856.0, 260.0]) {
      await _pumpField(tester, width: width);
      final cell = tester.getSize(
        find.ancestor(of: _cell(0), matching: find.byType(SizedBox)).first,
      );
      expect(cell.width, cell.height, reason: 'Breite $width');
    }
  });

  testWidgets('jedes Feld nennt seine Position für Screenreader', (
    tester,
  ) async {
    await _pumpField(tester);

    expect(
      find.bySemanticsLabel('Lizenz-Token, Zeichen 16 von 16'),
      findsOneWidget,
    );
  });

  testWidgets('bricht auf schmalen Bildschirmen in mehrere Zeilen um, ohne '
      'zu überlaufen', (tester) async {
    await _pumpField(tester, width: 260);

    expect(tester.takeException(), isNull);
    final first = tester.getTopLeft(_cell(0));
    final ninth = tester.getTopLeft(_cell(8));
    expect(ninth.dy, greaterThan(first.dy));
    expect(tester.getSize(_cell(0)).width, greaterThanOrEqualTo(32));
  });
}

Future<List<String>> _pumpField(
  WidgetTester tester, {
  String? errorText,
  double width = 856,
}) async {
  // Breiter als die Karte, damit die volle Kartenbreite messbar ist.
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final tokens = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: LicenseTokenField(
              errorText: errorText,
              onChanged: tokens.add,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tokens;
}

Finder _cell(int index) => find.byType(TextField).at(index);

String _text(WidgetTester tester, int index) =>
    tester.widget<TextField>(_cell(index)).controller!.text;

int _focusedCell(WidgetTester tester) {
  final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
  return fields.indexWhere((field) => field.focusNode!.hasFocus);
}
