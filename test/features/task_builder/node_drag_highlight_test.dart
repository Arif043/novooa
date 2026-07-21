import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_drag_highlight.dart';

void main() {
  testWidgets('blendet den Shadow des gezogenen Bausteins animiert ein', (
    tester,
  ) async {
    final hostKey = GlobalKey<_HighlightHostState>();
    await tester.pumpWidget(_HighlightHost(key: hostKey));

    hostKey.currentState!.showHighlight();
    await tester.pump();
    _expectActiveDecoration(tester);
    expect(find.byType(AnimatedScale), findsNothing);

    await tester.pump(const Duration(milliseconds: 110));
    hostKey.currentState!.hideHighlight();
    await tester.pump();
    expect(_shadowOpacity(tester), 0);
  });
}

void _expectActiveDecoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(NodeDragHighlight),
      matching: find.byType(AnimatedContainer),
    ),
  );
  final decoration = container.decoration! as BoxDecoration;
  expect(decoration.border, isNull);
  expect(decoration.boxShadow!.single.color.a, greaterThan(0));
}

double _shadowOpacity(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(NodeDragHighlight),
      matching: find.byType(AnimatedContainer),
    ),
  );
  final decoration = container.decoration! as BoxDecoration;
  return decoration.boxShadow!.single.color.a;
}

class _HighlightHost extends StatefulWidget {
  const _HighlightHost({super.key});

  @override
  State<_HighlightHost> createState() => _HighlightHostState();
}

class _HighlightHostState extends State<_HighlightHost> {
  bool _active = false;

  void showHighlight() => setState(() => _active = true);

  void hideHighlight() => setState(() => _active = false);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Center(
        child: NodeDragHighlight(
          active: _active,
          child: const SizedBox(
            key: ValueKey('node-content'),
            width: 100,
            height: 100,
          ),
        ),
      ),
    );
  }
}
