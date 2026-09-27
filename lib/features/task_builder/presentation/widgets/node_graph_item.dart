import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/conditional_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/dialog_input_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/media_input_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/for_each_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/human_approval_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/iterative_refinement_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_output_name_field.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_output_chips.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/read_email_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/read_file_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/script_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/send_message_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/notification_send_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/string_input_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/document_lookup_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/save_document_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/table_from_collection_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_scope.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_suggestion.dart';

class NodeGraphItem extends StatelessWidget {
  const NodeGraphItem({
    super.key,
    required this.node,
    required this.dragSourceNodeIds,
    required this.isSource,
    required this.isDragActive,
    required this.onDragStarted,
    required this.onDragEnded,
    this.configurationOnly = false,
  });

  static const animationDuration = Duration(milliseconds: 500);

  final WorkflowNode node;
  final Set<NodeId> dragSourceNodeIds;
  final bool isSource;
  final bool isDragActive;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final bool configurationOnly;

  @override
  Widget build(BuildContext context) {
    if (configurationOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: NodeOutputNameField(node: node),
          ),
          const SizedBox(height: AppSpacing.md),
          _templateAwareNodeWidget(context),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Ergebnis für nächste Bausteine',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          NodeOutputChips(node: node),
        ],
      );
    }
    return DragTarget<NodeId>(
      key: ValueKey('node-target-${node.id.value}'),
      onWillAcceptWithDetails: _accepts,
      onAcceptWithDetails: (details) {
        context.read<TaskBuilderCubit>().swapNodes(details.data, node.id);
      },
      builder: _buildTarget,
    );
  }

  bool _accepts(DragTargetDetails<NodeId> details) {
    return details.data != node.id && dragSourceNodeIds.contains(details.data);
  }

  Widget _buildTarget(
    BuildContext context,
    List<NodeId?> candidates,
    List<dynamic> rejected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AnimatedContainer(
        duration: animationDuration,
        clipBehavior: Clip.none,
        curve: Curves.easeOutCubic,
        decoration: _dropDecoration(context, candidates.isNotEmpty),
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xxl),
              child: _templateAwareNodeWidget(context),
            ),
            if (!isDragActive) ..._nodeActions(context),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              width: AppSpacing.xxl,
              child: _dragStrip(context),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xxl),
          child: NodeOutputChips(node: node),
        ),
      ],
    );
  }

  List<Widget> _nodeActions(BuildContext context) {
    return [
      if (node.config.primitive != .conditional)
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.xxl + AppSpacing.sm,
          child: NodeOutputNameField(node: node),
        ),
      Positioned(
        top: AppSpacing.xs,
        right: AppSpacing.xs,
        child: IconButton(
          tooltip: 'Baustein löschen',
          onPressed: () => context.read<TaskBuilderCubit>().removeNode(node.id),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    ];
  }

  Widget _dragStrip(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: isDragActive
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,
      child: Draggable<NodeId>(
        data: node.id,
        feedback: const SizedBox.shrink(),
        childWhenDragging: _strip(colors),
        onDragStarted: () {
          context.read<TaskBuilderCubit>().selectNode(node.id);
          onDragStarted();
        },
        onDragEnd: (_) => onDragEnded(),
        onDragCompleted: onDragEnded,
        onDraggableCanceled: (_, _) => onDragEnded(),
        child: _strip(colors),
      ),
    );
  }

  Widget _strip(ColorScheme colors) {
    return Semantics(
      label: 'Baustein tauschen',
      button: true,
      child: DecoratedBox(
        key: ValueKey('node-drag-strip-${node.id.value}'),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border(right: BorderSide(color: colors.outlineVariant)),
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(AppSpacing.md),
          ),
        ),
        child: const Center(child: Icon(Icons.drag_indicator)),
      ),
    );
  }

  Decoration _dropDecoration(BuildContext context, bool isTargeted) {
    final color = Theme.of(context).colorScheme.primary;
    final highlighted = isTargeted || isSource;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: highlighted ? 0.24 : 0),
          blurRadius: highlighted ? AppSpacing.lg : 0,
          spreadRadius: highlighted ? AppSpacing.xs : 0,
        ),
      ],
    );
  }

  Widget _nodeWidget() {
    final child = switch (node.config.primitive) {
      .stringInput => StringInputWidget(node: node),
      .script => ScriptWidget(node: node),
      .prompt => PromptWidget(node: node),
      .conditional => ConditionalWidget(key: ValueKey(node.id), node: node),
      .iterativeRefinement => IterativeRefinementWidget(node: node),
      .writeFile => WriteFileWidget(node: node),
      .readFile => ReadFileWidget(node: node),
      .readEmail || .readChannelEvent => ReadEventWidget(node: node),
      .sendChannelMessage => SendMessageWidget(node: node),
      .notificationSend => NotificationSendWidget(node: node),
      .humanApproval => HumanApprovalWidget(node: node),
      .dialogInput => DialogInputWidget(node: node),
      .mediaInput => MediaInputWidget(node: node),
      .modelInference => ModelInferenceWidget(node: node),
      .textToSpeech => ModelInferenceWidget(
        node: node,
        speechDirection: SpeechModelDirection.textToSpeech,
      ),
      .speechToText => ModelInferenceWidget(
        node: node,
        speechDirection: SpeechModelDirection.speechToText,
      ),
      .forEach => ForEachWidget(node: node),
      .documentLookup => DocumentLookupWidget(node: node),
      .saveDocument => SaveDocumentWidget(node: node),
      .tableFromCollection => TableFromCollectionWidget(node: node),
      _ => const SizedBox.shrink(),
    };
    return FocusScope(
      key: ValueKey('node-focus-${node.id.value}'),
      canRequestFocus: !isDragActive,
      descendantsAreFocusable: !isDragActive,
      child: IgnorePointer(
        key: ValueKey('node-input-${node.id.value}'),
        ignoring: isDragActive,
        child: child,
      ),
    );
  }

  Widget _templateAwareNodeWidget(BuildContext context) {
    final suggestions = context
        .select<TaskBuilderCubit, List<TemplateExpressionSuggestion>>(
          (cubit) => switch (cubit.state) {
            TaskBuilderLoaded(:final editingTask) =>
              templateExpressionSuggestions(
                graph: editingTask.graph,
                targetNodeId: node.id,
              ),
            _ => const [],
          },
        );
    return TemplateExpressionScope(
      suggestions: suggestions,
      child: _nodeWidget(),
    );
  }
}
