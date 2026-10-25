import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/google_accounts/domain/entities/google_account.dart';
import 'package:syscat2/features/google_accounts/presentation/cubits/google_accounts_state.dart';

import 'google_account_test_doubles.dart';

const _account = GoogleAccount(
  id: 'konto-1',
  email: 'team@example.com',
  status: GoogleAccountStatus.active,
);

void main() {
  test('lädt die Konten und zeigt Änderungen aus dem Realtime-Kanal', () async {
    final repository = FakeGoogleAccountRepository(const []);
    final cubit = googleAccountsCubitFor(repository);
    addTearDown(cubit.close);

    expect(cubit.state, isA<GoogleAccountsLoading>());
    await cubit.load();
    await pumpEventQueue();
    expect(cubit.state, const GoogleAccountsLoaded([]));

    repository.emit(const [_account]);
    await pumpEventQueue();
    expect(cubit.state, const GoogleAccountsLoaded([_account]));
  });

  test('ein Ladefehler führt in den Fehlerzustand, Neuladen hilft', () async {
    final repository = FakeGoogleAccountRepository();
    final cubit = googleAccountsCubitFor(repository);
    addTearDown(cubit.close);

    await cubit.load();
    await pumpEventQueue();
    repository.fail();
    await pumpEventQueue();
    expect(cubit.state, isA<GoogleAccountsFailure>());

    await cubit.load();
    await pumpEventQueue();
    repository.emit(const [_account]);
    await pumpEventQueue();
    expect(cubit.state, const GoogleAccountsLoaded([_account]));
  });

  test('die Anmeldung reicht das vorgewählte Konto an die Runtime', () async {
    final repository = FakeGoogleAccountRepository(const []);
    final cubit = googleAccountsCubitFor(repository);
    addTearDown(cubit.close);

    final url = await cubit.beginAuthorization(loginHint: 'team@example.com');

    expect(url, 'https://accounts.google.test/auth');
    expect(repository.loginHints, ['team@example.com']);
  });

  test('scheitert der Start der Anmeldung, gibt es keine Adresse', () async {
    final repository = FakeGoogleAccountRepository(const [])
      ..authorizationUrl = null;
    final cubit = googleAccountsCubitFor(repository);
    addTearDown(cubit.close);

    expect(await cubit.beginAuthorization(), isNull);
  });
}
