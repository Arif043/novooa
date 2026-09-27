import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class SpeechTextMappingField extends StatelessWidget {
  const SpeechTextMappingField({
    super.key,
    required this.nodeId,
    required this.value,
    required this.onChanged,
  });

  final String nodeId;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: TextFormField(
        key: ValueKey('$nodeId-speech-text'),
        initialValue: value,
        decoration: const InputDecoration(
          labelText: 'Text',
          hintText: '{{eingabe.value}} oder {{global.eingabe.value}}',
        ),
        onChanged: onChanged,
      ),
    );
  }
}
