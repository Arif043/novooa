import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../activity/domain/entities/run_effect.dart';
import '../../../activity/domain/entities/task_run.dart';
import '../../../files/presentation/localization/file_display_texts.dart';
import '../../domain/entities/run_result.dart';

/// Texte, Farben und Symbole rund um Läufe in der App-Sprache.
abstract final class RunResultTexts {
  static String status(TaskRunStatus status) => switch (status) {
    TaskRunStatus.queued => LocaleKeys.results_status_queued,
    TaskRunStatus.running => LocaleKeys.results_status_running,
    TaskRunStatus.waitingForApproval => LocaleKeys.results_status_waiting,
    TaskRunStatus.rejected => LocaleKeys.results_status_rejected,
    TaskRunStatus.succeeded => LocaleKeys.results_status_succeeded,
    TaskRunStatus.failed => LocaleKeys.results_status_failed,
  }.tr();

  static IconData statusIcon(TaskRunStatus status) => switch (status) {
    TaskRunStatus.queued => CupertinoIcons.clock,
    TaskRunStatus.running => CupertinoIcons.arrow_2_circlepath,
    TaskRunStatus.waitingForApproval => CupertinoIcons.hand_raised,
    TaskRunStatus.rejected => CupertinoIcons.xmark_circle,
    TaskRunStatus.succeeded => CupertinoIcons.check_mark_circled,
    TaskRunStatus.failed => CupertinoIcons.exclamationmark_triangle,
  };

  static Color statusColor(ColorScheme colors, TaskRunStatus status) =>
      switch (status) {
        TaskRunStatus.succeeded => colors.primary,
        TaskRunStatus.failed => colors.error,
        TaskRunStatus.waitingForApproval => colors.tertiary,
        TaskRunStatus.rejected => colors.outline,
        TaskRunStatus.queued || TaskRunStatus.running => colors.secondary,
      };

  static String nodeState(RunNodeState state) => switch (state) {
    RunNodeState.succeeded => LocaleKeys.results_node_succeeded,
    RunNodeState.failed => LocaleKeys.results_node_failed,
    RunNodeState.skipped => LocaleKeys.results_node_skipped,
    RunNodeState.waiting => LocaleKeys.results_node_waiting,
    RunNodeState.notRun => LocaleKeys.results_node_not_run,
  }.tr();

  static String duration(Duration value) {
    final seconds = value.inSeconds;
    if (seconds < 60) {
      return LocaleKeys.results_duration_seconds.tr(
        namedArgs: {'seconds': '$seconds'},
      );
    }
    return LocaleKeys.results_duration_minutes.tr(
      namedArgs: {'minutes': '${seconds ~/ 60}', 'seconds': '${seconds % 60}'},
    );
  }

  static String effects(List<RunEffect> effects) => switch (effects.length) {
    0 => LocaleKeys.results_no_effects.tr(),
    1 => LocaleKeys.results_effects_one.tr(),
    final count => LocaleKeys.results_effects_many.tr(
      namedArgs: {'count': '$count'},
    ),
  };

  /// Das Ergebnis eines Laufs in einer Zeile: Fehler, Endausgabe oder Status.
  static String outcomeLine(TaskRun run) {
    if (run.status == TaskRunStatus.failed && (run.message ?? '').isNotEmpty) {
      return run.message!;
    }
    final output = run.finalOutput?.trim() ?? '';
    final text = output.isNotEmpty ? output : status(run.status);
    final duration = run.duration;
    final line = text.replaceAll('\n', ' ');
    return duration == null
        ? line
        : '$line · ${RunResultTexts.duration(duration)}';
  }

  /// „vor 5 Min. · 4 s · von Arif“.
  static String meta(BuildContext context, TaskRun run) {
    final duration = run.duration;
    final origin = run.startedByName != null
        ? LocaleKeys.results_started_by.tr(
            namedArgs: {'name': run.startedByName!},
          )
        : run.triggerType != null
        ? LocaleKeys.results_by_trigger.tr()
        : null;
    return [
      FileDisplayTexts.of(context).relative(run.startedAt ?? run.updatedAt),
      if (duration != null) RunResultTexts.duration(duration),
      ?origin,
    ].join(' · ');
  }
}
