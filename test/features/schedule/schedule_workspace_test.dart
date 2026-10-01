import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/schedule/domain/entities/schedule_config.dart';
import 'package:syscat2/features/schedule/domain/entities/task_trigger.dart';
import 'package:syscat2/features/schedule/domain/entities/event_trigger_config.dart';
import 'package:syscat2/features/schedule/presentation/cubits/schedule_cubit.dart';
import 'package:syscat2/features/schedule/presentation/cubits/schedule_state.dart';
import 'package:syscat2/features/schedule/presentation/pages/schedule_page.dart';
import 'package:syscat2/features/schedule/presentation/widgets/create_schedule_trigger_dialog.dart';
import 'package:syscat2/features/schedule/presentation/widgets/schedule_choice_control.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';

class _Cubit extends Fake implements ScheduleCubit {
  _Cubit(this.state);
  @override
  final ScheduleState state;
  @override
  Stream<ScheduleState> get stream => const Stream.empty();
  bool? enabled;
  bool deleted = false;
  bool fail = false;
  int creates = 0;
  Completer<void>? pending;
  @override
  Future<void> setEnabled(TaskTrigger trigger, bool value) async {
    enabled = value;
  }

  @override
  Future<void> deleteTrigger(TaskTrigger trigger) async {
    deleted = true;
  }

  @override
  Future<void> createTrigger(Task task, ScheduleConfig schedule) async {
    creates++;
    if (pending != null) await pending!.future;
    if (fail) throw StateError('offline');
  }

  @override
  Future<void> createEventTrigger(Task task, EventTriggerConfig event) async {
    creates++;
  }
}

const _trigger = TaskTrigger(
  id: 'trigger',
  teamId: 'team',
  taskId: 'task',
  taskTitle: 'Tägliche Zusammenfassung meiner Aufgaben und Termine',
  type: TriggerType.schedule,
  enabled: true,
  policy: TriggerRunPolicy.skipIfRunning,
  schedule: ScheduleConfig(
    kind: ScheduleKind.daily,
    timezone: 'Europe/Berlin',
    timeOfDay: '09:00',
  ),
);

Widget _app(_Cubit cubit, {bool dark = false, double scale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: dark ? SyscatTheme.darkTheme : SyscatTheme.lightTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: Scaffold(
    body: BlocProvider<ScheduleCubit>.value(
      value: cubit,
      child: const ScheduleView(),
    ),
  ),
);

void main() {
  testWidgets('form exposes weekly slots and event configuration', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final cubit = _Cubit(
      ScheduleState(status: ScheduleStatus.ready, tasks: [Task.empty()]),
    );
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auslöser hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wöchentlich'));
    await tester.pumpAndSettle();
    expect(find.text('Zeit hinzufügen'), findsOneWidget);
    await tester.tap(find.byTooltip('Mo 09:00 entfernen'));
    await tester.pumpAndSettle();
    expect(find.text('Noch kein Zeitpunkt ausgewählt.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Auslöser erstellen'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Zeit hinzufügen'));
    await tester.pumpAndSettle();
    expect(find.text('Mo 09:00'), findsOneWidget);
    await tester.tap(find.text('Ereignis'));
    await tester.pumpAndSettle();
    expect(find.text('Welches Postfach?'), findsOneWidget);
    await tester.tap(find.text('Weitere Optionen'));
    await tester.pumpAndSettle();
    expect(find.text('Textfilter (optional)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'rechnung');
    await tester.tap(find.text('Auslöser erstellen'));
    await tester.pumpAndSettle();
    expect(cubit.creates, 1);
    expect(tester.takeException(), isNull);
  });

  if (const bool.fromEnvironment('CAPTURE_SCHEDULE')) {
    testWidgets('capture schedule preview', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.runAsync(() async {
        final path = Platform.environment['WORKSPACE_PREVIEW_FONT'];
        if (path != null) {
          final bytes = await File(path).readAsBytes();
          await (FontLoader(
            'Inter',
          )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
        }
        await (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
              rootBundle.load(
                'packages/cupertino_icons/assets/CupertinoIcons.ttf',
              ),
            ))
            .load();
      });
      final key = GlobalKey();
      final cubit = _Cubit(
        ScheduleState(
          status: ScheduleStatus.ready,
          tasks: [Task.empty()],
          triggers: [
            _trigger,
            const TaskTrigger(
              id: 'second',
              teamId: 'team',
              taskId: 'task',
              taskTitle: 'Neue Nachrichten zusammenfassen',
              type: TriggerType.event,
              enabled: false,
              policy: TriggerRunPolicy.skipIfRunning,
              event: EventTriggerConfig(
                source: EventTriggerSource.emailReceived,
                filter: '',
              ),
            ),
          ],
        ),
      );
      await tester.pumpWidget(RepaintBoundary(key: key, child: _app(cubit)));
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/tmp/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('novooa-schedule');
      await tester.tap(find.text('Auslöser hinzufügen'));
      await tester.pumpAndSettle();
      await capture('novooa-schedule-form');
    });
  }
  testWidgets(
    'schedule supports small, landscape and desktop layouts in both themes',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cubit = _Cubit(
        ScheduleState(
          status: ScheduleStatus.ready,
          tasks: [Task.empty()],
          triggers: const [_trigger],
        ),
      );
      for (final size in [
        const Size(375, 812),
        const Size(812, 375),
        const Size(1280, 900),
      ]) {
        await tester.binding.setSurfaceSize(size);
        for (final dark in [false, true]) {
          await tester.pumpWidget(_app(cubit, dark: dark, scale: 2));
          await tester.pumpAndSettle();
          expect(find.text('Zeitplan'), findsOneWidget);
          expect(find.text(_trigger.taskTitle), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets('toggle and confirmed deletion keep existing actions', (
    tester,
  ) async {
    final cubit = _Cubit(
      ScheduleState(
        status: ScheduleStatus.ready,
        tasks: [Task.empty()],
        triggers: const [_trigger],
      ),
    );
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();
    expect(cubit.enabled, false);
    await tester.tap(find.byTooltip('Auslöser löschen'));
    await tester.pumpAndSettle();
    expect(cubit.deleted, false);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(cubit.deleted, false);
    await tester.tap(find.byTooltip('Auslöser löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();
    expect(cubit.deleted, true);
  });

  testWidgets('form prevents double submission and preserves failed input', (
    tester,
  ) async {
    final cubit = _Cubit(
      ScheduleState(status: ScheduleStatus.ready, tasks: [Task.empty()]),
    );
    cubit.pending = Completer<void>();
    cubit.fail = true;
    await tester.pumpWidget(_app(cubit));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auslöser hinzufügen'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Auslöser erstellen'));
    await tester.tap(find.text('Auslöser erstellen'));
    await tester.pump();
    expect(cubit.creates, 1);
    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byType(CreateScheduleTriggerDialog),
        matching: find.byType(FilledButton),
      ),
    );
    // The label is replaced by a spinner during the request.
    expect(button.onPressed, isNull);
    cubit.pending!.complete();
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Deine Eingaben bleiben erhalten'),
      findsOneWidget,
    );
    expect(find.byType(CreateScheduleTriggerDialog), findsOneWidget);
    cubit.fail = false;
    await tester.ensureVisible(find.text('Auslöser erstellen'));
    await tester.tap(find.text('Auslöser erstellen'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateScheduleTriggerDialog), findsNothing);
  });

  testWidgets(
    'large text form is scrollable with accessible selector fallback',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final cubit = _Cubit(
        ScheduleState(status: ScheduleStatus.ready, tasks: [Task.empty()]),
      );
      await tester.pumpWidget(_app(cubit, dark: true, scale: 2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Auslöser hinzufügen'));
      await tester.pumpAndSettle();
      expect(find.byType(ScheduleChoiceControl<ScheduleKind>), findsOneWidget);
      await tester.ensureVisible(find.text('Auslöser erstellen'));
      expect(tester.takeException(), isNull);
    },
  );
}
