import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_anchor.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_controller.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_overlay.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_scope.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_target.dart';

const _target = AgentCursorTarget('feld');

Widget _app(AgentCursorController controller) {
  return MaterialApp(
    home: AgentCursorScope(
      controller: controller,
      child: Stack(
        children: [
          const Center(
            child: AgentCursorAnchor(
              target: _target,
              child: SizedBox(key: Key('ziel'), width: 100, height: 40),
            ),
          ),
          Positioned.fill(child: AgentCursorOverlay(controller: controller)),
        ],
      ),
    ),
  );
}

AgentCursorController _fastController() => AgentCursorController(
  travelDuration: Duration.zero,
  maxTypingDuration: Duration.zero,
);

void main() {
  testWidgets('fährt zur Mitte des Ziels und blendet sich wieder aus', (
    tester,
  ) async {
    final controller = _fastController();
    await tester.pumpWidget(_app(controller));

    await tester.runAsync(() => controller.moveTo(_target));
    await tester.pump();

    expect(
      controller.globalPosition,
      tester.getCenter(find.byKey(const Key('ziel'))),
    );
    expect(find.text('KI-Agent'), findsOneWidget);

    controller.hide();
    await tester.pump();
    expect(find.text('KI-Agent'), findsNothing);
  });

  testWidgets('tippt Text schrittweise und endet mit dem vollen Wert', (
    tester,
  ) async {
    final controller = _fastController();
    await tester.pumpWidget(_app(controller));
    final seen = <String>[];

    await tester.runAsync(
      () => controller.typeInto(_target, 'Hallo', (text) async {
        seen.add(text);
      }),
    );

    expect(seen.last, 'Hallo');
    expect(controller.clickCount, 1);
  });

  testWidgets('ein unbekanntes Ziel bricht nichts ab', (tester) async {
    final controller = _fastController();
    await tester.pumpWidget(_app(controller));

    await tester.runAsync(
      () => controller.moveTo(const AgentCursorTarget('fehlt')),
    );

    expect(controller.isVisible, isFalse);
  });
}
