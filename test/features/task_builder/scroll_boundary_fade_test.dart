import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/scroll_boundary_fade.dart';

void main() {
  testWidgets('blendet einen scrollbaren Inhalt ohne Interaktionsfehler ein', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_ScrollFadeHost(controller: controller));

    expect(find.byType(ShaderMask), findsOneWidget);
    controller.jumpTo(48);
    await tester.pump();

    expect(controller.offset, greaterThan(0));
  });
}

class _ScrollFadeHost extends StatelessWidget {
  const _ScrollFadeHost({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 100,
          child: ScrollBoundaryFade(
            controller: controller,
            child: SingleChildScrollView(
              controller: controller,
              child: const SizedBox(height: 300),
            ),
          ),
        ),
      ),
    );
  }
}
