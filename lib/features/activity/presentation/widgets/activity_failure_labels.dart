import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/activity_failure_code.dart';
import 'activity_failure_explanations.dart';

extension ActivityFailureCodeLabel on ActivityFailureCode {
  /// Die übersetzte Erklärung; [details] liefert die Werte für die
  /// Platzhalter. Scheiterte eine Runde einer Schleife, steht sie dahinter.
  String localizedExplanation(Map<String, String> details) {
    final explanation = activityFailureExplanations[this]!;
    final text = explanation.key.tr(
      namedArgs: explanation.argumentsFor(details),
    );
    return text + _iterationSuffix(details['iteration']);
  }
}

String _iterationSuffix(String? iteration) {
  final index = int.tryParse(iteration ?? '');
  if (index == null) return '';
  return LocaleKeys.activity_failures_iteration_suffix.tr(
    namedArgs: {'number': '${index + 1}'},
  );
}
