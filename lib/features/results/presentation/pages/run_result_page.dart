import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/layout/page_insets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/luminous_page_theme.dart';
import '../../../../core/widgets/luminous_status_placeholder.dart';
import '../../../activity/domain/entities/task_run.dart';
import '../cubits/run_result_cubit.dart';
import '../cubits/run_result_state.dart';
import '../localization/run_result_texts.dart';
import '../widgets/run/run_result_effects_card.dart';
import '../widgets/run/run_result_flow.dart';
import '../widgets/run/run_result_header.dart';
import '../widgets/run/run_result_outcome_card.dart';

/// Ein Lauf: Ergebnis, Folgen und der Ablauf als Graph mit echten Werten.
class RunResultPage extends StatelessWidget {
  const RunResultPage({super.key, required this.run});

  final TaskRun run;

  static Route<void> route(TaskRun run) =>
      MaterialPageRoute<void>(builder: (_) => RunResultPage(run: run));

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<RunResultCubit>()..load(run),
      child: Theme(
        data: LuminousPageTheme.from(Theme.of(context)),
        child: Builder(
          builder: (context) => Scaffold(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerLowest,
            body: SafeArea(
              child: BlocBuilder<RunResultCubit, RunResultState>(
                builder: (context, state) => switch (state) {
                  final RunResultReady ready => _RunResultBody(state: ready),
                  _ => LuminousStatusPlaceholder(
                    loading: state is RunResultLoading,
                    message: null,
                    fallbackMessage: LocaleKeys.results_run_load_failed.tr(),
                    onRetry: context.read<RunResultCubit>().retry,
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RunResultBody extends StatelessWidget {
  const _RunResultBody({required this.state});

  static const _wideMinWidth = 840.0;

  final RunResultReady state;

  @override
  Widget build(BuildContext context) {
    final result = state.result;
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = PageInsets.forWidth(constraints.maxWidth).gutter;
        final wide = constraints.maxWidth >= _wideMinWidth;
        final outcome = RunResultOutcomeCard(result: result);
        final effects = RunResultEffectsCard(effects: result.effects);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(gutter, AppSpacing.lg, gutter, gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RunResultHeader(
                run: result.run,
                effectsLabel: RunResultTexts.effects(result.effects),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: outcome),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: effects),
                    ],
                  ),
                )
              else ...[
                outcome,
                const SizedBox(height: AppSpacing.md),
                effects,
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                LocaleKeys.results_flow_title.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              _FlowArea(
                state: state,
                wide: wide,
                viewportHeight: constraints.maxHeight,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Der Graph braucht eine feste Höhe; sie richtet sich nach dem sichtbaren
/// Bereich. Ohne Graph wächst die Liste mit ihrem Inhalt.
class _FlowArea extends StatelessWidget {
  const _FlowArea({
    required this.state,
    required this.wide,
    required this.viewportHeight,
  });

  final RunResultReady state;
  final bool wide;
  final double viewportHeight;

  @override
  Widget build(BuildContext context) {
    final flow = RunResultFlow(state: state, wide: wide);
    if (state.result.graph == null) return flow;
    return SizedBox(height: viewportHeight * 0.75, child: flow);
  }
}
