import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dashboard_theme.dart';
import '../../../../l10n/dashboard_keys.dart';
import '../../domain/entities/task_run.dart';
import '../cubits/run_review_cubit.dart';
import 'form_value_input.dart';

/// Formular eines wartenden Laufs; „Freigeben“ sendet die Werte mit.
class FormRequestFields extends StatefulWidget {
  const FormRequestFields({super.key, required this.run, required this.fields});

  final TaskRun run;
  final List<FormFieldSpec> fields;

  @override
  State<FormRequestFields> createState() => _FormRequestFieldsState();
}

class _FormRequestFieldsState extends State<FormRequestFields> {
  final Map<String, Object> _values = {};

  bool get _isComplete =>
      widget.fields.every((field) => _values.containsKey(field.name));

  void _set(String name, Object? value) => setState(() {
    value == null ? _values.remove(name) : _values[name] = value;
  });

  @override
  Widget build(BuildContext context) {
    final review = context.watch<RunReviewCubit>();
    final sending = review.state is RunReviewSending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final field in widget.fields) ...[
          FormValueInput(field: field, onChanged: (v) => _set(field.name, v)),
          const SizedBox(height: Spacing.sm),
        ],
        const SizedBox(height: Spacing.sm),
        FilledButton(
          onPressed: sending || !_isComplete
              ? null
              : () => review.review(
                  widget.run,
                  RunReviewDecision.approve,
                  formValues: Map.of(_values),
                ),
          child: Text(DashboardKeys.runsApprove.tr()),
        ),
        TextButton(
          onPressed: sending
              ? null
              : () => review.review(widget.run, RunReviewDecision.reject),
          child: Text(DashboardKeys.runsReject.tr()),
        ),
      ],
    );
  }
}
