import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import '../cubits/task_builder_state.dart';
import 'animated_node_configuration_panel.dart';
import 'animated_workflow_canvas.dart';
import 'baustein_palette.dart';
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
  WorkflowNode? _panelNode;
  BausteinInsertion? _insertion;
  bool _showPalette = false;
  bool _panelVisible = false;

  void _open(WorkflowNode node) {
    FocusManager.instance.primaryFocus?.unfocus();
    final shouldAnimateIn = _panelNode == null;
    setState(() {
      _editing = node.id;
      _panelNode = node;
      _panelVisible = !shouldAnimateIn;
      _insertion = null;
      _showPalette = false;
    });
    context.read<TaskBuilderCubit>().selectNode(node.id);
    if (shouldAnimateIn) _showPanelAfterBuild(node.id);
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editing = null;
      _panelVisible = false;
    });
  }

  void _showPanelAfterBuild(NodeId nodeId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _panelNode?.id != nodeId) return;
      setState(() => _panelVisible = true);
    });
  }

  void _removeClosedPanel() {
    if (mounted && !_panelVisible) setState(() => _panelNode = null);
  }

  Future<void> _add(BausteinChoice choice, BausteinInsertion insertion) async {
    await context.read<TaskBuilderCubit>().addConnectedNode(
      primitive: choice.primitive,
      ownerId: insertion.owner,
      branchId: insertion.branchId,
      afterId: insertion.after,
      channelKind: choice.kind,
      pluginTypeId: choice.pluginTypeId,
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
    final panelNode = selected?.node ?? _panelNode;
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
              // Ohne explizit gewählten Einfügepunkt (`_insertion`, ein
              // Klick auf "+ Baustein hier verbinden") fügt das Menü links
              // immer in den Hauptfluss ein — direkt nach dem fokussierten
              // Baustein, unabhängig davon, ob der gerade fokussierte
              // Baustein selbst in einem Zweig oder einer Schleife liegt
              // (`task.selectedNodeOrNull` findet dort nichts, dann wird an
              // das Ende des Hauptflusses angehängt). `selected?.insertion`
              // bewusst NICHT hier: Das würde bei einem in einem Zweig
              // fokussierten Baustein dessen `owner`/`branchId` übernehmen
              // und dort statt im Hauptfluss einfügen.
              onAdd: (choice) => _add(
                choice,
                _insertion ??
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
                        child: AnimatedWorkflowCanvas(
                          graph: task.graph,
                          selected: _editing,
                          isInspectorVisible: desktop && _panelVisible,
                          onSelect: _open,
                          onDrop: _add,
                          onChoose: (insertion) => setState(() {
                            _insertion = insertion;
                            _showPalette = true;
                            _editing = null;
                            _panelVisible = false;
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
                        _panelVisible = false;
                      }),
                      icon: const Icon(Icons.widgets_outlined),
                      label: Text(
                        LocaleKeys.task_builder_body_blocks_button.tr(),
                      ),
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
                            Text(LocaleKeys.task_builder_body_pick_left.tr()),
                            IconButton(
                              tooltip: LocaleKeys.task_builder_body_cancel_pick
                                  .tr(),
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
                if (panelNode case final WorkflowNode node)
                  Positioned(
                    top: 24,
                    bottom: 24,
                    right: 20,
                    width: math.min(
                      540,
                      constraints.maxWidth - (desktop ? paletteWidth + 48 : 40),
                    ),
                    child: AnimatedNodeConfigurationPanel(
                      node: node,
                      isVisible: _panelVisible,
                      onClose: _close,
                      onDismissed: _removeClosedPanel,
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
