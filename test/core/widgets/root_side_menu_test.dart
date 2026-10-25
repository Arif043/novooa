import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/widgets/root_side_menu.dart';
import 'package:syscat2/root_tab.dart';

void main() {
  testWidgets('zeigt Abmelden und ruft onSignOut auf, wenn gesetzt', (
    tester,
  ) async {
    var signedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 600,
            child: RootSideMenu(
              tabs: _tabs,
              selectedIndex: 0,
              onSelected: (_) {},
              onSignOut: () => signedOut = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Abmelden'), findsOneWidget);
    await tester.tap(find.text('Abmelden'));
    expect(signedOut, isTrue);
  });

  testWidgets('blendet Abmelden aus, wenn onSignOut null ist', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 600,
            child: RootSideMenu(
              tabs: _tabs,
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Abmelden'), findsNothing);
  });
}

final _tabs = [
  const RootTab(path: '/tasks', title: 'Aufgaben', icon: Icons.task_outlined),
];
