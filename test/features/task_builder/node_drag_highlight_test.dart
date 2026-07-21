import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_drag_highlight.dart';

void main() {
  testWidgets('hebt den gezogenen Baustein animiert hervor', (tester) async {
    final hostKey = GlobalKey<_HighlightHostState>();
    await tester.pumpWidget(_HighlightHost(key: hostKey));
    final initialWidth = _contentWidth(tester);

    hostKey.currentState!.showHighlight();
    await tester.pump();
    expect(_contentWidth(tester), closeTo(initialWidth, 0.1));
    _expectActiveDecoration(tester);

    await tester.pump(const Duration(milliseconds: 110));
    expect(_contentWidth(tester), greaterThan(initialWidth));

    await tester.pump(const Duration(milliseconds: 110));
    expect(_contentWidth(tester), closeTo(initialWidth * 1.015, 0.1));
  });
}

double _contentWidth(WidgetTester tester) {
  return tester.getRect(find.byKey(const ValueKey('node-content'))).width;
}

void _expectActiveDecoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(NodeDragHighlight),
      matching: find.byType(AnimatedContainer),
    ),
  );
  final decoration = container.decoration! as BoxDecoration;
  expect(decoration.border, isNotNull);
  expect(decoration.boxShadow!.single.color.a, greaterThan(0));
}

class _HighlightHost extends StatefulWidget {
  const _HighlightHost({super.key});

  @override
  State<_HighlightHost> createState() => _HighlightHostState();
}

class _HighlightHostState extends State<_HighlightHost> {
  bool _active = false;

  void showHighlight() => setState(() => _active = true);

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
