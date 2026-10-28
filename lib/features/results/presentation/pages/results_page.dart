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
import '../../../../core/widgets/luminous_page_header.dart';
import '../../../../core/widgets/luminous_status_placeholder.dart';
import '../cubits/run_results_cubit.dart';
import '../cubits/run_results_state.dart';
import '../widgets/list/results_empty_state.dart';
import '../widgets/list/results_run_list.dart';

/// „Ergebnisse“: alle jüngsten Läufe; ein Lauf öffnet seine Ergebnisansicht.
class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<RunResultsCubit>()..load(),
      child: Theme(
        data: LuminousPageTheme.from(Theme.of(context)),
        child: const _ResultsView(),
      ),
    );
  }
}

class _ResultsView extends StatelessWidget {
  const _ResultsView();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: SafeArea(
        child: BlocBuilder<RunResultsCubit, RunResultsState>(
          builder: (context, state) => switch (state) {
            RunResultsReady(:final runs) when runs.isEmpty => ResultsEmptyState(
              onOpenTasks: () => context.go(AppRouter.home),
            ),
            _ => _ResultsScroll(state: state),
          },
        ),
      ),
    );
  }
}

class _ResultsScroll extends StatelessWidget {
  const _ResultsScroll({required this.state});

  final RunResultsState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = PageInsets.forWidth(constraints.maxWidth);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                insets.inset,
                AppSpacing.xl,
                insets.inset,
                AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: LuminousPageHeader(
                  title: LocaleKeys.results_title.tr(),
                  subtitle: LocaleKeys.results_subtitle.tr(),
                  action: const SizedBox.shrink(),
                ),
              ),
            ),
            switch (state) {
              final RunResultsReady ready => ResultsRunList(
                state: ready,
                inset: insets.inset,
              ),
              _ => SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.all(insets.gutter),
                  child: LuminousStatusPlaceholder(
                    loading: state is RunResultsLoading,
                    message: null,
                    fallbackMessage: LocaleKeys.results_load_failed.tr(),
                    onRetry: context.read<RunResultsCubit>().load,
                  ),
                ),
              ),
            },
          ],
        );
      },
    );
  }
}
