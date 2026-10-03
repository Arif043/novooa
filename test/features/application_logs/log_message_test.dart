import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/application_logs/domain/entities/application_log.dart';
import 'package:syscat2/features/application_logs/domain/entities/script_log_events.dart';
import 'package:syscat2/features/application_logs/presentation/widgets/log_message.dart';

ApplicationLog _log(String event, String message, ApplicationLogLevel level) {
  return ApplicationLog(
    id: UniqueId('log'),
    level: level,
    source: ApplicationLogSource.runtime,
    event: event,
    message: message,
    data: const {},
    occurredAt: DateTime(2026, 10, 3),
  );
}

Future<TextStyle?> _styleOf(WidgetTester tester, ApplicationLog log) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorScheme: const ColorScheme.light()),
      home: Scaffold(body: LogMessage(log: log)),
    ),
  );
  final selectable = find.byType(SelectableText);
  if (selectable.evaluate().isNotEmpty) {
    return tester.widget<SelectableText>(selectable).style;
  }
  return tester.widget<Text>(find.byType(Text)).style;
}

void main() {
  const error = Color(0xFFB00020);

  testWidgets('stderr ist rötlich und in Festbreitenschrift', (tester) async {
    final style = await _styleOf(
      tester,
      _log(
        scriptStderrLogEvent,
        '[Script-Fehlerausgabe]\nWarnung',
        ApplicationLogLevel.error,
      ),
    );

    expect(style?.color, error);
    expect(style?.fontFamilyFallback, contains('monospace'));
    expect(find.text('[Script-Fehlerausgabe]\nWarnung'), findsOneWidget);
  });

  testWidgets(
    'stdout hat die normale Textfarbe, ebenfalls in Festbreitenschrift',
    (tester) async {
      final style = await _styleOf(
        tester,
        _log(
          scriptStdoutLogEvent,
          '[Script-Log]\nhallo',
          ApplicationLogLevel.info,
        ),
      );

      expect(style?.color, isNot(error));
      expect(style?.fontFamilyFallback, contains('monospace'));
    },
  );

  testWidgets('andere Einträge bleiben unverändert', (tester) async {
    final style = await _styleOf(
      tester,
      _log(
        'application.message',
        'Aufgabe gestartet',
        ApplicationLogLevel.info,
      ),
    );

    expect(style?.fontFamilyFallback, isNull);
    expect(find.text('Aufgabe gestartet'), findsOneWidget);
  });
}
