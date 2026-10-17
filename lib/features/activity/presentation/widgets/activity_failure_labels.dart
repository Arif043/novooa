import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/activity_failure_code.dart';

extension ActivityFailureCodeLabel on ActivityFailureCode {
  String get localizedExplanation => switch (this) {
    ActivityFailureCode.outputSchemaViolated =>
      LocaleKeys.activity_failures_codes_outputSchemaViolated.tr(),
    ActivityFailureCode.responseTruncated =>
      LocaleKeys.activity_failures_codes_responseTruncated.tr(),
    ActivityFailureCode.emptyResponse =>
      LocaleKeys.activity_failures_codes_emptyResponse.tr(),
    ActivityFailureCode.providerUnavailable =>
      LocaleKeys.activity_failures_codes_providerUnavailable.tr(),
    ActivityFailureCode.requestRejected =>
      LocaleKeys.activity_failures_codes_requestRejected.tr(),
    ActivityFailureCode.timedOut =>
      LocaleKeys.activity_failures_codes_timedOut.tr(),
    ActivityFailureCode.capabilityMissing =>
      LocaleKeys.activity_failures_codes_capabilityMissing.tr(),
  };
}
