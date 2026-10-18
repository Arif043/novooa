import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/console_output_block.dart';
import '../../domain/entities/activity_failure_code.dart';
import 'activity_failure_labels.dart';

/// Der Fehler eines Bausteins. Mit bekanntem Code steht oben die übersetzte
/// Erklärung samt Hinweis, darunter der technische Text der Runtime.
class NodeActivityFailure extends StatelessWidget {
  const NodeActivityFailure({
    super.key,
    required this.message,
    required this.failureCode,
    this.failureDetails = const {},
  });

  final String message;
  final ActivityFailureCode? failureCode;
  final Map<String, String> failureDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final code = failureCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocaleKeys.activity_failures_error.tr(),
            style: textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (code != null) ...[
            SelectableText(
              code.localizedExplanation(failureDetails),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              LocaleKeys.activity_failures_technical_details.tr(),
              style: textTheme.labelSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          ConsoleOutputBlock(text: message.trimRight(), isError: true),
        ],
      ),
    );
  }
}
