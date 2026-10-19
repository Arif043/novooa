import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../../domain/entities/node_config.dart';
import '../field_helper_text.dart';
import '../node_language_model_field.dart';

/// Prüfung des Teamergebnisses: an/aus und ein eigenes Modell, damit ein
/// günstiger Orchestrator mit einer starken Prüfung kombiniert werden kann.
class TeamworkReviewSection extends StatelessWidget {
  const TeamworkReviewSection({
    super.key,
    required this.review,
    required this.onChanged,
  });

  final TeamworkReview review;
  final ValueChanged<TeamworkReview> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(LocaleKeys.ui_teamwork_review.tr(), style: SyscatTheme.taskBody),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(LocaleKeys.ui_teamwork_review_enabled.tr()),
          subtitle: Text(LocaleKeys.ui_teamwork_review_hint.tr()),
          value: review.enabled,
          onChanged: (enabled) => onChanged(review.copyWith(enabled: enabled)),
        ),
        if (review.enabled) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            LocaleKeys.ui_teamwork_review_model.tr(),
            style: SyscatTheme.taskBodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          NodeLanguageModelField(
            selectedModelId: review.languageModelId,
            onChanged: (modelId) =>
                onChanged(review.copyWith(languageModelId: modelId)),
          ),
          FieldHelperText(LocaleKeys.ui_teamwork_review_model_hint.tr()),
        ],
      ],
    );
  }
}
