import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import '../cubits/task_builder_state.dart';
import 'baustein_palette.dart';
import 'node_configuration_panel.dart';
import 'workflow_canvas.dart';
import 'workflow_canvas_layout.dart';
import 'workflow_editor_scope.dart';
import 'task_builder_theme.dart';

class TaskBuilderBody extends StatefulWidget {
  const TaskBuilderBody({super.key, required this.state});
  final TaskBuilderState state;
  @override
  State<TaskBuilderBody> createState() => _TaskBuilderBodyState();
}

class _TaskBuilderBodyState extends State<TaskBuilderBody> {
  NodeId? _editing;
  BausteinInsertion? _insertion;
  bool _showPalette = false;

  void _open(WorkflowNode node) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editing = node.id;
      _insertion = null;
      _showPalette = false;
    });
    context.read<TaskBuilderCubit>().selectNode(node.id);
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _editing = null);
  }

  Future<void> _add(BausteinChoice choice, BausteinInsertion insertion) async {
    await context.read<TaskBuilderCubit>().addConnectedNode(
      primitive: choice.primitive,
      ownerId: insertion.owner,
      branchId: insertion.branchId,
      afterId: insertion.after,
      channelKind: choice.kind,
    );
    if (!mounted) return;
    setState(() {
      _insertion = null;
      _showPalette = false;
    });
  }

  @override
  Widget build(BuildContext context) => switch (widget.state) {
    TaskBuilderLoading() => const Center(child: CircularProgressIndicator()),
    TaskBuilderFailure(:final message) => Center(child: Text(message)),
    TaskBuilderLoaded(:final editingTask) => _workspace(editingTask),
  };

  Widget _workspace(Task task) {
    final entries = WorkflowCanvasLayout(task.graph).entries;
    final selected = entries[_editing?.value];
    return WorkflowEditorScope(
      onSelect: _open,
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 850;
            final paletteWidth = desktop
                ? TaskBuilderTheme.paletteWidth
                : math.min(280.0, constraints.maxWidth - 48);
            final palette = BausteinPalette(
              onAdd: (choice) => _add(
                choice,
                _insertion ??
                    selected?.insertion ??
                    BausteinInsertion(after: task.selectedNodeOrNull?.id),
              ),
            );
            return Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    children: [
                      if (desktop)
                        SizedBox(width: paletteWidth, child: palette),
                      Expanded(
                        child: WorkflowCanvas(
                          graph: task.graph,
                          inspectorWidth: desktop && selected?.node != null
                              ? 560
                              : 0,
                          selected: _editing,
                          onSelect: _open,
                          onDrop: _add,
                          onChoose: (insertion) => setState(() {
                            _insertion = insertion;
                            _showPalette = true;
                            _editing = null;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!desktop)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: FilledButton.tonalIcon(
                      onPressed: () => setState(() {
                        _showPalette = !_showPalette;
                        _editing = null;
                      }),
                      icon: const Icon(Icons.widgets_outlined),
                      label: const Text('Bausteine'),
                    ),
                  ),
                if (_insertion != null && desktop)
                  Positioned(
                    top: 16,
                    left: paletteWidth + 16,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.west, size: 18),
                            const SizedBox(width: 8),
                            const Text('Baustein links auswählen'),
                            IconButton(
                              tooltip: 'Auswahl abbrechen',
                              onPressed: () =>
                                  setState(() => _insertion = null),
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!desktop && _showPalette) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _showPalette = false),
                      child: ColoredBox(color: Colors.black26),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: paletteWidth,
                    child: palette,
                  ),
                ],
                if (selected?.node case final WorkflowNode node)
                  Positioned(
                    top: 24,
                    bottom: 24,
                    right: 20,
                    width: math.min(
                      540,
                      constraints.maxWidth - (desktop ? paletteWidth + 48 : 40),
                    ),
                    child: Focus(
                      autofocus: true,
                      child: NodeConfigurationPanel(
                        key: ValueKey(node.id),
                        node: node,
                        onClose: _close,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
