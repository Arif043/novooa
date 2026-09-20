import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/workflow_canvas.dart';

void main() {
  testWidgets(
    'zoom interpolates around the center and accumulates rapid clicks',
    (tester) async {
      await tester.pumpWidget(_workspace());
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final controller = viewer.transformationController!;
      final center = tester
          .getSize(find.byType(InteractiveViewer))
          .center(Offset.zero);
      final sceneCenter = controller.toScene(center);
      await tester.tap(find.byTooltip('Vergrößern'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(controller.value.getMaxScaleOnAxis(), inExclusiveRange(1, 1.25));
      expect(
        (controller.toScene(center) - sceneCenter).distance,
        lessThan(.001),
      );
      await tester.tap(find.byTooltip('Vergrößern'));
      await tester.pumpAndSettle();
      expect(controller.value.getMaxScaleOnAxis(), closeTo(1.5625, .001));
      expect(
        (controller.toScene(center) - sceneCenter).distance,
        lessThan(.001),
      );
      await tester.tap(find.byTooltip('Verkleinern'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      viewer.onInteractionStart!(ScaleStartDetails());
      final interrupted = controller.value.clone();
      await tester.pump(const Duration(milliseconds: 400));
      expect(controller.value, interrupted);
      await tester.tap(find.byTooltip('Gesamten Arbeitsplan anzeigen'));
      await tester.pumpAndSettle();
      expect(controller.value.getMaxScaleOnAxis(), lessThanOrEqualTo(1));
    },
  );

  testWidgets('reduced motion applies the zoom immediately', (tester) async {
    await tester.pumpWidget(_workspace(reducedMotion: true));
    final controller = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!;
    await tester.tap(find.byTooltip('Vergrößern'));
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1.25, .001));
    await tester.pumpAndSettle();
  });
}

Widget _workspace({bool reducedMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reducedMotion),
    child: Scaffold(
      body: WorkflowCanvas(
        graph: const WorkflowGraph(nodes: [], edges: []),
        selected: null,
        onSelect: (_) {},
        onChoose: (_) {},
        onDrop: (_, _) {},
      ),
    ),
  ),
);
