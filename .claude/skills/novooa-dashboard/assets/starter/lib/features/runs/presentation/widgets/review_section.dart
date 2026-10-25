import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dashboard_theme.dart';
import '../../../../l10n/dashboard_keys.dart';
import '../../domain/entities/task_run.dart';
import '../cubits/run_review_cubit.dart';
import 'form_request_fields.dart';

/// Antwort auf einen wartenden Lauf: Freigabe oder Formular.
class ReviewSection extends StatelessWidget {
  const ReviewSection({
    super.key,
    required this.run,
    required this.interaction,
  });

  final TaskRun run;
  final RunInteraction interaction;

  @override
  Widget build(BuildContext context) {
    final review = context.watch<RunReviewCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (interaction.instruction.isNotEmpty) Text(interaction.instruction),
        const SizedBox(height: Spacing.md),
        switch (interaction) {
          ApprovalRequest() => _Decision(run: run),
          FormRequest(:final fields) => FormRequestFields(
            run: run,
            fields: fields,
          ),
          UnsupportedRequest() => Text(
            DashboardKeys.runsOpenInOfficialApp.tr(),
          ),
        },
        if (review is RunReviewFailed) ...[
          const SizedBox(height: Spacing.sm),
          Text(
            DashboardKeys.runsReviewFailed.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _Decision extends StatelessWidget {
  const _Decision({required this.run});

  final TaskRun run;

  @override
  Widget build(BuildContext context) {
    final review = context.watch<RunReviewCubit>();
    final sending = review.state is RunReviewSending;
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        FilledButton(
          onPressed: sending
              ? null
              : () => review.review(run, RunReviewDecision.approve),
          child: Text(DashboardKeys.runsApprove.tr()),
        ),
        OutlinedButton(
          onPressed: sending
              ? null
              : () => review.review(run, RunReviewDecision.reject),
          child: Text(DashboardKeys.runsReject.tr()),
        ),
      ],
    );
  }
}
