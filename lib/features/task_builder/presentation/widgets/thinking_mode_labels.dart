import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/task_builder/domain/entities/prompt_generation_options.dart';

extension ThinkingModeLabel on ThinkingMode {
  String get localizedLabel => switch (this) {
    ThinkingMode.modelDefault =>
      LocaleKeys.task_builder_generation_options_thinking_modes_modelDefault
          .tr(),
    ThinkingMode.off =>
      LocaleKeys.task_builder_generation_options_thinking_modes_off.tr(),
    ThinkingMode.low =>
      LocaleKeys.task_builder_generation_options_thinking_modes_low.tr(),
    ThinkingMode.medium =>
      LocaleKeys.task_builder_generation_options_thinking_modes_medium.tr(),
    ThinkingMode.high =>
      LocaleKeys.task_builder_generation_options_thinking_modes_high.tr(),
  };
}
