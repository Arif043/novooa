import 'package:easy_localization/easy_localization.dart';

import '../../../../core/localization/locale_keys.g.dart';
import '../../domain/entities/plugin_failure.dart';

extension PluginFailureText on PluginFailure {
  String get text => switch (kind) {
    PluginFailureKind.runtimeUnavailable =>
      LocaleKeys.plugins_failure_runtime_unavailable.tr(),
    PluginFailureKind.adminRequired =>
      LocaleKeys.plugins_failure_admin_required.tr(),
    PluginFailureKind.notFound => LocaleKeys.plugins_failure_not_found.tr(),
    PluginFailureKind.unexpected => LocaleKeys.plugins_failure_unexpected.tr(),
  };
}
