import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/google_accounts/domain/entities/google_account.dart';
import 'package:syscat2/features/google_accounts/domain/entities/google_drive_item.dart';
import 'package:syscat2/features/google_accounts/presentation/widgets/google_accounts_section.dart';

import 'google_account_test_doubles.dart';

const _folder = GoogleDriveItem(
  id: 'ordner-1',
  name: 'Rechnungen',
  mimeType: GoogleDriveItem.folderMimeType,
);

Future<FakeGoogleAccountRepository> _pump(
  WidgetTester tester, [
  List<GoogleAccount>? accounts,
]) async {
  final repository = FakeGoogleAccountRepository(accounts);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        // Der Baum schließt den Cubit beim Abbau, innerhalb der Testzeit.
        body: BlocProvider(
          create: (_) => googleAccountsCubitFor(repository)..load(),
          child: const SingleChildScrollView(child: GoogleAccountsSection()),
        ),
      ),
    ),
  );
  await tester.pump();
  return repository;
}

void _widgetTest(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    await body(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

void main() {
  _widgetTest('ohne Konto gibt es einen Hinweis und „Google-Konto verbinden“', (
    tester,
  ) async {
    await _pump(tester, const []);

    expect(find.text('Noch kein Google-Konto verbunden.'), findsOneWidget);
    expect(find.text('Google-Konto verbinden'), findsOneWidget);
  });

  _widgetTest(
    'ein Konto zeigt Adresse, Freigaben und „Weitere Dateien freigeben“',
    (tester) async {
      await _pump(tester, const [
        GoogleAccount(
          id: 'k1',
          email: 'team@example.com',
          status: GoogleAccountStatus.active,
          sharedItems: [_folder],
        ),
      ]);

      expect(find.text('team@example.com'), findsOneWidget);
      expect(find.text('1 freigegeben'), findsOneWidget);
      expect(find.text('Weitere Dateien freigeben'), findsOneWidget);
    },
  );

  _widgetTest('abgelaufene Anmeldung bietet „Neu verbinden“ an', (
    tester,
  ) async {
    await _pump(tester, const [
      GoogleAccount(
        id: 'k1',
        email: 'team@example.com',
        status: GoogleAccountStatus.reauthorizationRequired,
      ),
    ]);

    expect(find.text('Anmeldung abgelaufen'), findsOneWidget);
    expect(find.text('Neu verbinden'), findsOneWidget);
  });

  _widgetTest('nach einem Ladefehler lädt „Erneut versuchen“ neu', (
    tester,
  ) async {
    final repository = await _pump(tester);
    repository.fail();
    await tester.pump();
    expect(
      find.text('Google-Konten konnten nicht geladen werden.'),
      findsOneWidget,
    );

    repository.accountsOnListen = const [];
    await tester.tap(find.text('Erneut versuchen'));
    // Das Abbestellen des alten Abonnements endet erst außerhalb der Testzeit.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.text('Noch kein Google-Konto verbunden.'), findsOneWidget);
  });
}
