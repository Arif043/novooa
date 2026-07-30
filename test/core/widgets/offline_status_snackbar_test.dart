import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/widgets/offline_status_snackbar.dart';

void main() {
  testWidgets('zeigt und schließt den Offline-Hinweis', (tester) async {
    final statusController = StreamController<bool>();
    addTearDown(statusController.close);
    final messengerKey = GlobalKey<ScaffoldMessengerState>();

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: OfflineStatusSnackbar(
          isOnline: statusController.stream,
          scaffoldMessengerKey: messengerKey,
          child: const Scaffold(body: SizedBox()),
        ),
      ),
    );

    statusController.add(false);
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Keine Internetverbindung. Offline-Daten werden angezeigt.'),
      findsOneWidget,
    );

    statusController.add(true);
    await tester.pump();

    expect(
      find.text('Keine Internetverbindung. Offline-Daten werden angezeigt.'),
      findsNothing,
    );
  });
}
