import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/adaptive_sheet.dart';
import '../../../../../core/widgets/luminous_card.dart';
import '../../cubits/run_result_cubit.dart';
import '../../cubits/run_result_state.dart';
import '../graph/run_result_graph.dart';
import 'run_result_node_details.dart';
import 'run_step_list.dart';

/// Der Ablauf des Laufs: als Graph mit Details daneben (Desktop) bzw. im
/// Sheet (Handy); alte Läufe ohne Graph als Liste der Bausteine.
class RunResultFlow extends StatelessWidget {
  const RunResultFlow({super.key, required this.state, required this.wide});

  final RunResultReady state;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final graph = state.result.graph;
    if (graph == null) {
      return LuminousCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: RunStepList(result: state.result),
        ),
      );
    }
    final cubit = context.read<RunResultCubit>();
    final selected = state.selectedNodeId;
    final canvas = LuminousCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: RunResultGraph(
          graph: graph,
          state: state,
          onSelectNode: (id) =>
              wide ? cubit.selectNode(id) : _showDetails(context, id),
          onSelectRound: cubit.selectRound,
        ),
      ),
    );
    if (!wide || selected == null) return canvas;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 7, child: canvas),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 3,
          child: LuminousCard(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: CloseButton(onPressed: cubit.clearSelection),
                ),
                Expanded(
                  child: RunResultNodeDetails(state: state, nodeId: selected),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDetails(BuildContext context, String nodeId) {
    final cubit = context.read<RunResultCubit>()..selectNode(nodeId);
    return showAdaptiveSheet<void>(
      context: context,
      builder: (_, _) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<RunResultCubit, RunResultState>(
          builder: (context, current) => current is RunResultReady
              ? SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.7,
                  child: RunResultNodeDetails(state: current, nodeId: nodeId),
                )
              : const SizedBox.shrink(),
        ),
      ),
    ).whenComplete(cubit.clearSelection);
  }
}
