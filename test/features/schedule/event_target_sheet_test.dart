import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/schedule/domain/entities/event_trigger_config.dart';
import 'package:syscat2/features/schedule/presentation/cubits/event_target_options_cubit.dart';
import 'package:syscat2/features/schedule/presentation/cubits/event_target_options_state.dart';
import 'package:syscat2/features/schedule/presentation/widgets/event_target_sheet.dart';

class _FakeOptions extends Cubit<EventTargetOptionsState>
    implements EventTargetOptionsCubit {
  _FakeOptions()
    : super(
        const EventTargetOptionsState(status: EventTargetOptionsStatus.ready),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> open(
    WidgetTester tester,
    void Function(EventTriggerTarget?) onResult,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => onResult(
                await EventTargetSheet.show(
                  context,
                  source: EventTriggerSource.fileCreated,
                  initial: EventTriggerTarget.anywhere,
                  options: _FakeOptions(),
                ),
              ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
  }

  testWidgets('mobil: ein Bottom Sheet mit „Übernehmen“', (tester) async {
    EventTriggerTarget? result;
    await open(tester, (value) => result = value);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Abbrechen'), findsNothing);

    await tester.tap(find.text('Übernehmen'));
    await tester.pumpAndSettle();

    expect(result, isA<AnywhereTarget>());
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('Desktop: Karte mit Abbrechen und Übernehmen als Paar', (
    tester,
  ) async {
    EventTriggerTarget? result = const FileTarget(id: 'x', name: 'x');
    await open(tester, (value) => result = value);

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Abbrechen'), findsOneWidget);
    expect(find.text('Übernehmen'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
}
