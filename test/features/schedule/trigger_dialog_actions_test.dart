import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/schedule/presentation/widgets/trigger_dialog_actions.dart';

Widget _host({
  VoidCallback? onCancel,
  VoidCallback? onConfirm,
  bool busy = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 400,
          child: TriggerDialogActions(
            cancelLabel: 'Abbrechen',
            confirmLabel: 'Auslöser erstellen',
            isBusy: busy,
            onCancel: onCancel,
            onConfirm: onConfirm,
          ),
        ),
      ),
    ),
  );
}

TextStyle _styleOf(WidgetTester tester, String label) {
  return tester
      .widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      )
      .style;
}

void main() {
  testWidgets('zeigt beide Aktionen nebeneinander in gleicher Breite', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onCancel: () {}, onConfirm: () {}));

    final cancel = tester.getRect(find.byType(TriggerDialogAction).first);
    final confirm = tester.getRect(find.byType(TriggerDialogAction).last);
    expect(cancel.top, confirm.top);
    expect(cancel.width, closeTo(confirm.width, 1));
    expect(cancel.right, lessThanOrEqualTo(confirm.left));
    expect(cancel.height, greaterThanOrEqualTo(48));
  });

  testWidgets('die Standardaktion ist fett, Abbrechen normal', (tester) async {
    await tester.pumpWidget(_host(onCancel: () {}, onConfirm: () {}));

    expect(_styleOf(tester, 'Auslöser erstellen').fontWeight, FontWeight.w600);
    expect(_styleOf(tester, 'Abbrechen').fontWeight, FontWeight.w400);
  });

  testWidgets('ruft die jeweilige Aktion beim Tippen auf', (tester) async {
    var cancelled = 0;
    var confirmed = 0;
    await tester.pumpWidget(
      _host(onCancel: () => cancelled++, onConfirm: () => confirmed++),
    );

    await tester.tap(find.text('Abbrechen'));
    await tester.tap(find.text('Auslöser erstellen'));
    await tester.tap(find.text('Auslöser erstellen'));

    expect(cancelled, 1);
    expect(confirmed, 2);
  });

  testWidgets('eine deaktivierte Aktion reagiert nicht und ist abgeblendet', (
    tester,
  ) async {
    var cancelled = 0;
    await tester.pumpWidget(_host(onCancel: () => cancelled++));

    await tester.tap(find.text('Auslöser erstellen'));

    expect(
      tester
          .widget<TriggerDialogAction>(find.byType(TriggerDialogAction).last)
          .onPressed,
      isNull,
    );
    expect(
      _styleOf(tester, 'Auslöser erstellen').color,
      isNot(_styleOf(tester, 'Abbrechen').color),
    );
    await tester.tap(find.text('Abbrechen'));
    expect(cancelled, 1);
  });

  testWidgets('im Ladezustand ersetzt ein Indikator die Beschriftung', (
    tester,
  ) async {
    await tester.pumpWidget(_host(busy: true));

    expect(find.text('Auslöser erstellen'), findsNothing);
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
  });

  testWidgets('gedrückt wird die Aktion hinterlegt', (tester) async {
    await tester.pumpWidget(_host(onCancel: () {}, onConfirm: () {}));

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Abbrechen')),
    );
    await tester.pump();
    final pressed = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(TriggerDialogAction).first,
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    await gesture.up();
    await tester.pump();
    final released = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(TriggerDialogAction).first,
            matching: find.byType(ColoredBox),
          )
          .first,
    );

    expect(pressed.color.a, greaterThan(0));
    expect(released.color.a, 0);
  });
}
