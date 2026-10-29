import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/layout/page_insets.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/luminous_page_theme.dart';
import '../../../../core/widgets/luminous_status_placeholder.dart';
import '../cubits/run_results_cubit.dart';
import '../cubits/run_results_state.dart';
import '../widgets/list/results_empty_state.dart';
import '../widgets/list/results_list_panel.dart';
import '../widgets/run/run_result_view.dart';
import 'run_result_page.dart';

/// „Ergebnisse“: links die Läufe, rechts der gewählte Lauf; auf dem Handy
/// öffnet ein Lauf seine eigene Seite.
class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<RunResultsCubit>()..load(),
      child: Theme(
        data: LuminousPageTheme.from(Theme.of(context)),
        child: Builder(
          builder: (context) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: SafeArea(
              child: BlocBuilder<RunResultsCubit, RunResultsState>(
                builder: (context, state) => switch (state) {
                  RunResultsReady(:final runs) when runs.isEmpty =>
                    ResultsEmptyState(
                      onOpenTasks: () => context.go(AppRouter.home),
                    ),
                  final RunResultsReady ready => _MasterDetail(state: ready),
                  _ => LuminousStatusPlaceholder(
                    loading: state is RunResultsLoading,
                    message: null,
                    fallbackMessage: LocaleKeys.results_load_failed.tr(),
                    onRetry: context.read<RunResultsCubit>().load,
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

class _MasterDetail extends StatelessWidget {
  const _MasterDetail({required this.state});

  static const _splitMinWidth = 900.0;

  final RunResultsReady state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = PageInsets.forWidth(constraints.maxWidth).gutter;
        final padding = EdgeInsets.fromLTRB(
          gutter,
          AppSpacing.lg,
          gutter,
          gutter,
        );
        final cubit = context.read<RunResultsCubit>();
        if (constraints.maxWidth < _splitMinWidth) {
          return ResultsListPanel(
            state: state,
            selectedRunId: null,
            padding: padding,
            onOpen: (run) =>
                Navigator.of(context).push(RunResultPage.route(run)),
          );
        }
        final selected = state.selectedRun;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: ResultsListPanel(
                state: state,
                selectedRunId: selected?.id.value,
                padding: padding,
                onOpen: cubit.select,
              ),
            ),
            VerticalDivider(
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(
              flex: 9,
              child: selected == null
                  ? Center(child: Text(LocaleKeys.results_select_run.tr()))
                  : RunResultView(run: selected, padding: padding),
            ),
          ],
        );
      },
    );
  }
}
