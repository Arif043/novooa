import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/luminous_card.dart';
import '../../../../../core/widgets/luminous_status_placeholder.dart';
import '../../../../activity/domain/entities/task_run.dart';
import '../../cubits/run_result_cubit.dart';
import '../../cubits/run_result_state.dart';
import 'run_result_flow.dart';
import 'run_result_header.dart';
import 'run_result_summary.dart';

/// Ein Lauf: Kopf, Ergebnis und Folgen, darunter der Ablauf. Dient als
/// Detailspalte (breit) und als eigene Seite (Handy).
class RunResultView extends StatelessWidget {
  const RunResultView({
    super.key,
    required this.run,
    required this.padding,
    this.showBack = false,
  });

  final TaskRun run;
  final EdgeInsets padding;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(run.id.value),
      create: (_) => serviceLocator<RunResultCubit>()..load(run),
      child: BlocBuilder<RunResultCubit, RunResultState>(
        builder: (context, state) => switch (state) {
          final RunResultReady ready => _Content(
            state: ready,
            padding: padding,
            showBack: showBack,
          ),
          _ => LuminousStatusPlaceholder(
            loading: state is RunResultLoading,
            message: null,
            fallbackMessage: LocaleKeys.results_run_load_failed.tr(),
            onRetry: context.read<RunResultCubit>().retry,
          ),
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.padding,
    required this.showBack,
  });

  static const _wideMinWidth = 720.0;

  final RunResultReady state;
  final EdgeInsets padding;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final result = state.result;
    return LayoutBuilder(
      builder: (context, constraints) {
        final flow = RunResultFlow(
          state: state,
          wide: constraints.maxWidth >= _wideMinWidth,
        );
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RunResultHeader(run: result.run, showBack: showBack),
              const SizedBox(height: AppSpacing.lg),
              LuminousCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: RunResultSummary(result: result),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                LocaleKeys.results_flow_title.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (result.graph == null)
                flow
              else
                SizedBox(height: constraints.maxHeight * 0.7, child: flow),
            ],
          ),
        );
      },
    );
  }
}
