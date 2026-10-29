import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../activity/domain/entities/task_run.dart';

typedef RunDayGroup = ({String label, List<TaskRun> runs});

/// Läufe nach Tag: „Heute“, „Gestern“, sonst das Datum; neueste zuerst.
List<RunDayGroup> runDayGroups(
  List<TaskRun> runs, {
  required String locale,
  DateTime? now,
}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final groups = <DateTime, List<TaskRun>>{};
  for (final run in runs) {
    final day = DateUtils.dateOnly(runTime(run));
    groups.putIfAbsent(day, () => []).add(run);
  }
  return [
    for (final entry in groups.entries)
      (label: _labelFor(entry.key, today, locale), runs: entry.value),
  ];
}

/// Wann der Lauf begann; ohne Start der letzte Stand.
DateTime runTime(TaskRun run) => (run.startedAt ?? run.updatedAt).toLocal();

String _labelFor(DateTime day, DateTime today, String locale) {
  final difference = today.difference(day).inDays;
  if (difference == 0) return LocaleKeys.results_today.tr();
  if (difference == 1) return LocaleKeys.results_yesterday.tr();
  return DateFormat.yMMMMEEEEd(locale).format(day);
}
