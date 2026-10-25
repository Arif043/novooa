import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dashboard_theme.dart';
import '../../../../l10n/dashboard_keys.dart';
import '../../domain/entities/task_run.dart';
import '../../domain/usecases/review_run.dart';
import '../cubits/run_review_cubit.dart';
import 'review_section.dart';

/// Ergebnis eines Laufs und, solange er wartet, die Antwort darauf.
Future<void> showRunDetailSheet(BuildContext context, TaskRun run) {
  final reviewRun = context.read<ReviewRun>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider(
      create: (_) => RunReviewCubit(reviewRun),
      child: RunDetailSheet(run: run),
    ),
  );
}

class RunDetailSheet extends StatelessWidget {
  const RunDetailSheet({super.key, required this.run});

  final TaskRun run;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<RunReviewCubit, RunReviewState>(
      listener: (context, state) {
        if (state is RunReviewSent) Navigator.of(context).pop();
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(run.taskTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: Spacing.md),
              Text(
                DashboardKeys.runsResult.tr(),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: Spacing.xs),
              SelectableText(
                run.finalOutput.isEmpty
                    ? DashboardKeys.runsNoResult.tr()
                    : run.finalOutput,
              ),
              if (run.needsReview && run.interaction != null) ...[
                const SizedBox(height: Spacing.lg),
                ReviewSection(run: run, interaction: run.interaction!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
