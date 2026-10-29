import 'package:flutter/material.dart';

import '../../../../core/layout/page_insets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/luminous_page_theme.dart';
import '../../../activity/domain/entities/task_run.dart';
import '../widgets/run/run_result_view.dart';

/// Ein Lauf als eigene Seite — auf dem Handy und aus der Historie.
class RunResultPage extends StatelessWidget {
  const RunResultPage({super.key, required this.run});

  final TaskRun run;

  static Route<void> route(TaskRun run) =>
      MaterialPageRoute<void>(builder: (_) => RunResultPage(run: run));

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: LuminousPageTheme.from(Theme.of(context)),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gutter = PageInsets.forWidth(constraints.maxWidth).gutter;
                return RunResultView(
                  run: run,
                  showBack: true,
                  padding: EdgeInsets.fromLTRB(
                    gutter,
                    AppSpacing.lg,
                    gutter,
                    gutter,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
