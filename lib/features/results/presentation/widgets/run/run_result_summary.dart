import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../activity/domain/entities/run_effect.dart';
import '../../../../activity/domain/entities/task_activity.dart';
import '../../../../activity/presentation/widgets/run_effects/open_effect_file.dart';
import '../../../../activity/presentation/widgets/run_effects/run_effect_texts.dart';
import '../../../domain/entities/run_result.dart';

/// Ergebnis und Folgen als zwei beschriftete Zeilen: was herauskam und was
/// sich dadurch geändert hat.
class RunResultSummary extends StatelessWidget {
  const RunResultSummary({super.key, required this.result});

  final RunResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Line(
          label: LocaleKeys.results_result_title.tr(),
          child: _Outcome(result: result),
        ),
        const SizedBox(height: AppSpacing.md),
        _Line(
          label: LocaleKeys.run_effects_title.tr(),
          child: _Effects(effects: result.effects),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.result});

  final RunResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = result.topLevel
        .where((node) => node.status == TaskActivityStatus.failed)
        .lastOrNull;
    if (failed != null) {
      return SelectableText(
        failed.message ?? result.run.message ?? '',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }
    final output = result.run.finalOutput?.trim() ?? '';
    return SelectableText(
      output.isEmpty ? LocaleKeys.results_no_output.tr() : output,
      style: theme.textTheme.bodyLarge,
    );
  }
}

class _Effects extends StatelessWidget {
  const _Effects({required this.effects});

  final List<RunEffect> effects;

  @override
  Widget build(BuildContext context) {
    if (effects.isEmpty) {
      return Text(
        LocaleKeys.results_none.tr(),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [for (final effect in effects) _EffectChip(effect: effect)],
    );
  }
}

class _EffectChip extends StatelessWidget {
  const _EffectChip({required this.effect});

  final RunEffect effect;

  @override
  Widget build(BuildContext context) {
    final (:icon, :text) = runEffectPresentation(effect);
    final file = effect;
    return ActionChip(
      avatar: Icon(icon, size: AppSpacing.md + AppSpacing.xs),
      label: Text(text, overflow: TextOverflow.ellipsis),
      onPressed: file is FileWrittenEffect
          ? () => openEffectFile(context, file)
          : null,
    );
  }
}
