import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class NewPasswordField extends StatelessWidget {
  const NewPasswordField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.showPassword,
    required this.onToggleVisibility,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool showPassword;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    obscureText: !showPassword,
    autocorrect: false,
    enableSuggestions: false,
    keyboardType: TextInputType.visiblePassword,
    textInputAction: TextInputAction.done,
    autofillHints: const [AutofillHints.newPassword],
    decoration: _decoration(),
    onChanged: onChanged,
    onSubmitted: onSubmitted,
  );

  InputDecoration _decoration() => InputDecoration(
    labelText: 'Neues Passwort',
    helperText: 'Mindestens 6 Zeichen',
    suffixIconConstraints: const BoxConstraints(
      minWidth: AppSpacing.xxl,
      minHeight: AppSpacing.xxl,
    ),
    suffixIcon: IconButton(
      tooltip: showPassword ? 'Passwort verbergen' : 'Passwort anzeigen',
      onPressed: enabled ? onToggleVisibility : null,
      icon: Icon(
        showPassword
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
      ),
    ),
  );
}
