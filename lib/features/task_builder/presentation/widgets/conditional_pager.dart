import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_predecessor.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/conditional_widget.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

class ConditionalPager extends StatefulWidget {
  const ConditionalPager({super.key, required this.node});

  final WorkflowNode node;

  @override
  State<ConditionalPager> createState() => _ConditionalPagerState();
}

class _ConditionalPagerState extends State<ConditionalPager> {
  late List<_ConditionalPage> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [_rootPage()];
  }

  @override
  void didUpdateWidget(ConditionalPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id) {
      _pages = [_rootPage()];
      return;
    }
    _pages = _refreshPages(_pages);
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages.last;
    final branch = page.branch;
    if (branch == null) return _conditionalPage(page);
    return BranchWidget(
      branch: branch,
      conditionalNodeId: page.conditionalNodeId,
      onBack: _popPage,
    );
  }

  Widget _conditionalPage(_ConditionalPage page) {
    return ConditionalWidget(
      nodeConfig: page.config,
      derivedFromDecisionPrompt: _isDrivenByDecisionPrompt(context, page),
      onValueTemplateChanged: (value) => context
          .read<TaskBuilderCubit>()
          .updateConditionalValue(page.conditionalNodeId, value),
      onBranchSelected: (branch) {
        setState(() => _pages.add(page.withBranch(branch)));
      },
    );
  }

  /// Ist der direkte Vorgänger dieses Bedingter-Ablauf-Bausteins ein
  /// Entscheidungs-Prompt, hält `TaskBuilderGraphMutations` seine Choices
  /// und `valueTemplate` bereits automatisch synchron — die manuelle
  /// „Wenn"-Eingabe wäre hier nur verwirrend/redundant.
  bool _isDrivenByDecisionPrompt(BuildContext context, _ConditionalPage page) {
    final state = context.watch<TaskBuilderCubit>().state;
    if (state is! TaskBuilderLoaded) return false;
    final predecessor = directPredecessorOf(
      state.editingTask.graph,
      page.conditionalNodeId,
    );
    return predecessor?.config is PromptNodeConfig &&
        (predecessor!.config as PromptNodeConfig).outputType ==
            PromptOutputType.decision;
  }

  void _popPage() {
    if (_pages.length == 1) return;
    setState(() => _pages = _pages.sublist(0, _pages.length - 1));
  }

  _ConditionalPage _rootPage() {
    return _ConditionalPage(
      conditionalNodeId: widget.node.id,
      config: widget.node.config as ConditionalNodeConfig,
    );
  }

  List<_ConditionalPage> _refreshPages(List<_ConditionalPage> oldPages) {
    final refreshed = <_ConditionalPage>[];
    var config = widget.node.config as ConditionalNodeConfig;
    for (var index = 0; index < oldPages.length; index++) {
      final oldPage = oldPages[index];
      final branch = _branchOrNull(config, oldPage.branch?.id);
      refreshed.add(
        _ConditionalPage(
          conditionalNodeId: oldPage.conditionalNodeId,
          config: config,
          branch: branch,
        ),
      );
      if (branch == null) {
        if (index + 1 >= oldPages.length) break;
        continue;
      }
      if (index + 1 >= oldPages.length) break;
      final nextNode = _nodeOrNull(
        branch,
        oldPages[index + 1].conditionalNodeId,
      );
      if (nextNode?.config is! ConditionalNodeConfig) break;
      config = nextNode!.config as ConditionalNodeConfig;
    }
    return refreshed.isEmpty ? [_rootPage()] : refreshed;
  }

  ConditionalBranch? _branchOrNull(
    ConditionalNodeConfig config,
    String? branchId,
  ) {
    if (branchId == null) return null;
    for (final branch in config.branches) {
      if (branch.id == branchId) return branch;
    }
    return null;
  }

  WorkflowNode? _nodeOrNull(ConditionalBranch branch, NodeId nodeId) {
    for (final node in branch.graph.nodes) {
      if (node.id == nodeId) return node;
    }
    return null;
  }
}

class _ConditionalPage {
  const _ConditionalPage({
    required this.conditionalNodeId,
    required this.config,
    this.branch,
  });

  final NodeId conditionalNodeId;
  final ConditionalNodeConfig config;
  final ConditionalBranch? branch;

  _ConditionalPage withBranch(ConditionalBranch branch) {
    return _ConditionalPage(
      conditionalNodeId: conditionalNodeId,
      config: config,
      branch: branch,
    );
  }
}
