import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/run_origin.dart';

/// „Gestartet von Anna“, „Zeitplan“ oder „Auslöser“, dazu „beantwortet von Ben“.
String? runOriginLabel(RunOrigin origin) {
  if (!origin.isKnown) return null;
  final parts = [
    ?_startLabel(origin),
    if (origin.reviewedBy != null)
      LocaleKeys.activity_origin_reviewed_by.tr(args: [origin.reviewedBy!]),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

String? _startLabel(RunOrigin origin) {
  if (origin.startedBy != null) {
    return LocaleKeys.activity_origin_started_by.tr(args: [origin.startedBy!]);
  }
  return switch (origin.triggerType) {
    null => null,
    'schedule' => LocaleKeys.activity_origin_schedule.tr(),
    _ => LocaleKeys.activity_origin_trigger.tr(),
  };
}
