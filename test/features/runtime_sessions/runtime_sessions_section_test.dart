import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/runtime_sessions/domain/entities/runtime_session.dart';
import 'package:syscat2/features/runtime_sessions/domain/entities/runtime_session_failure.dart';
import 'package:syscat2/features/runtime_sessions/domain/entities/session_device.dart';
import 'package:syscat2/features/runtime_sessions/presentation/widgets/runtime_sessions_section.dart';

import 'runtime_sessions_fakes.dart';

Future<void> _pumpSection(
  WidgetTester tester,
  FakeRuntimeSessionRepository repository,
) async {
  final cubit = cubitWith(repository);
  addTearDown(cubit.close);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit..load(),
          child: const RuntimeSessionsSection(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('zeigt Geräte; nur fremde lassen sich abmelden', (tester) async {
    final repository = FakeRuntimeSessionRepository()
      ..sessionsOrFailure = Success([
        sessionFixture('a', isCurrent: true),
        RuntimeSession(
          id: const RuntimeSessionId('b'),
          isCurrent: false,
          signedInAt: DateTime(2026, 10, 1),
          lastActiveAt: DateTime.now(),
          device: const SessionDevice(app: 'novooa', os: DeviceOs.windows),
        ),
      ]);
    await _pumpSection(tester, repository);

    expect(find.text('Chrome auf macOS'), findsOneWidget);
    expect(find.text('Windows-App'), findsOneWidget);
    expect(find.text('Dieses Gerät'), findsOneWidget);
    expect(find.byTooltip('Windows-App abmelden'), findsOneWidget);
    expect(find.byTooltip('Chrome auf macOS abmelden'), findsNothing);
  });

  testWidgets('ein Gerät abmelden fragt nach und meldet das Ergebnis', (
    tester,
  ) async {
    final repository = FakeRuntimeSessionRepository();
    await _pumpSection(tester, repository);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Abmelden'));
    await tester.pumpAndSettle();

    expect(repository.revokedIds, [const RuntimeSessionId('b')]);
    expect(find.text('Das Gerät wurde abgemeldet.'), findsOneWidget);
    expect(find.text('Kein anderes Gerät ist angemeldet.'), findsOneWidget);
  });

  testWidgets('ein Ladefehler bietet „Erneut versuchen“', (tester) async {
    final repository = FakeRuntimeSessionRepository()
      ..sessionsOrFailure = const Error(
        RuntimeSessionFailure(RuntimeSessionFailureKind.unexpected),
      );
    await _pumpSection(tester, repository);

    expect(
      find.text('Die angemeldeten Geräte konnten nicht geladen werden.'),
      findsOneWidget,
    );
    repository.sessionsOrFailure = Success([
      sessionFixture('a', isCurrent: true),
    ]);
    await tester.tap(find.text('Erneut versuchen'));
    await tester.pumpAndSettle();

    expect(find.text('Dieses Gerät'), findsOneWidget);
  });
}
