import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_availability.dart';
import 'package:syscat2/core/runtime/runtime_connection_cubit.dart';
import 'package:syscat2/core/runtime/runtime_connection_page.dart';
import 'package:syscat2/core/runtime/runtime_connection_state.dart';
import 'package:syscat2/core/runtime/runtime_credential_store.dart';
import 'package:syscat2/core/runtime/runtime_endpoint.dart';
import 'package:syscat2/core/runtime/runtime_endpoint_store.dart';
import 'package:syscat2/core/runtime/runtime_kind_store.dart';
import 'package:syscat2/core/runtime/runtime_login_client.dart';
import 'package:syscat2/core/runtime/runtime_onboarding_client.dart';

final _endpoint = RuntimeEndpoint.fromAddress('192.168.1.20');

void main() {
  testWidgets('die Anmeldung fragt Anmeldename und Passwort und führt zu '
      'Einladung und Notzugang', (tester) async {
    final cubit = await _pumpPage(tester);

    expect(find.widgetWithText(TextField, 'Anmeldename'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Passwort'), findsOneWidget);

    await tester.tap(find.text('Ich habe einen Einladungscode'));
    await tester.pumpAndSettle();
    expect(
      (cubit.state as RuntimeConnectionNeedsPassword).mode,
      RuntimeSignInMode.invitation,
    );
    expect(find.widgetWithText(TextField, 'Einladungscode'), findsOneWidget);

    await tester.tap(find.text('Zurück zur Anmeldung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin-Zugang wiederherstellen'));
    await tester.pumpAndSettle();
    expect(find.text('Admin-Passwort neu setzen'), findsOneWidget);
  });

  testWidgets('die Anmeldung schickt Anmeldename und Passwort', (tester) async {
    final login = _RecordingLogin();
    await _pumpPage(tester, login: login);

    await tester.enterText(
      find.widgetWithText(TextField, 'Anmeldename'),
      'anna',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Passwort'),
      'geheim1',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Anmelden'));
    await tester.pump();

    expect(login.calls, ['anna/geheim1']);
  });

  testWidgets('die Einrichtung legt das erste Konto als Admin an', (
    tester,
  ) async {
    final cubit = await _pumpPage(tester);
    cubit.emit(
      RuntimeConnectionNeedsPasswordSetup(_endpoint, activationToken: 'TOKEN'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin-Konto anlegen'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Anmeldename'), findsOneWidget);
  });
}

Future<RuntimeConnectionCubit> _pumpPage(
  WidgetTester tester, {
  RuntimeLoginClient? login,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final cubit = RuntimeConnectionCubit(
    _NoEndpoints(),
    _NoCredentials(),
    login ?? _RecordingLogin(),
    _Reachable(),
    onboarding: _NoOnboarding(),
    kindStore: _NoKind(),
  );
  addTearDown(cubit.close);
  cubit.showSignIn(_endpoint, RuntimeSignInMode.password);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const RuntimeConnectionPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

class _RecordingLogin implements RuntimeLoginClient {
  final calls = <String>[];

  @override
  Future<String> login(
    RuntimeEndpoint endpoint, {
    required String loginName,
    required String password,
  }) async {
    calls.add('$loginName/$password');
    return 'token';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoEndpoints implements RuntimeEndpointStore {
  @override
  Future<RuntimeEndpoint?> load() async => null;

  @override
  Future<void> save(RuntimeEndpoint endpoint) async {}

  @override
  Future<void> clear() async {}
}

class _NoCredentials implements RuntimeCredentialStore {
  @override
  Future<String?> sessionToken(String address) async => null;

  @override
  Future<void> saveSessionToken(String address, String token) async {}

  @override
  Future<void> clearSessionToken(String address) async {}
}

class _Reachable implements RuntimeAvailability {
  @override
  Future<void> check(RuntimeEndpoint endpoint) async {}
}

class _NoOnboarding implements RuntimeOnboardingClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoKind implements RuntimeKindStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
