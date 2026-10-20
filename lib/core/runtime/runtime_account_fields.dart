import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../localization/locale_keys.g.dart';
import 'runtime_form_header.dart';

/// Anmeldename eines Kontos; Autofill erkennt ihn als Benutzernamen.
class RuntimeLoginNameField extends StatelessWidget {
  const RuntimeLoginNameField({
    super.key,
    required this.controller,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.username],
      textInputAction: TextInputAction.next,
      decoration: runtimeFieldDecoration(
        context,
        label: LocaleKeys.runtime_access_login_name.tr(),
      ),
    );
  }
}

/// Passwortfeld mit Umschalter für Klartext.
class RuntimePasswordField extends StatefulWidget {
  const RuntimePasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.isNewPassword = false,
    this.showsRule = false,
    this.errorText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool isNewPassword;

  /// Zeigt die Mindestlänge unter dem ersten Feld eines neuen Passworts.
  final bool showsRule;
  final String? errorText;
  final VoidCallback? onSubmitted;

  @override
  State<RuntimePasswordField> createState() => _RuntimePasswordFieldState();
}

class _RuntimePasswordFieldState extends State<RuntimePasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      autocorrect: false,
      autofillHints: [
        widget.isNewPassword
            ? AutofillHints.newPassword
            : AutofillHints.password,
      ],
      textInputAction: widget.onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      decoration: runtimeFieldDecoration(
        context,
        label: widget.label,
        helperText: widget.showsRule
            ? LocaleKeys.runtime_access_password_hint.tr()
            : null,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip: _obscure
              ? LocaleKeys.runtime_access_show_password.tr()
              : LocaleKeys.runtime_access_hide_password.tr(),
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      onSubmitted: (_) => widget.onSubmitted?.call(),
    );
  }
}

/// Zweitrangige Aktion unter einem Formular (Wechsel des Anmeldewegs).
class RuntimeSignInLink extends StatelessWidget {
  const RuntimeSignInLink({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
