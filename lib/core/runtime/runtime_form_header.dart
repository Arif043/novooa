import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Kopf der Runtime-Einrichtungsschritte im Stil der Cloud-Anmeldung: Titel
/// und erklärender Text, linksbündig unter dem Logo der Karte.
class RuntimeFormHeader extends StatelessWidget {
  const RuntimeFormHeader({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: textTheme.titleLarge),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(description, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Primäre Aktion eines Einrichtungsschritts — wie der Button der Cloud-
/// Anmeldung 48 px hoch, mit Ladeanzeige statt Beschriftung, solange
/// [isBusy] gilt.
class RuntimeFormButton extends StatelessWidget {
  const RuntimeFormButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isBusy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: isBusy ? null : onPressed,
        child: isBusy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

/// Feldgestaltung wie `AuthTextField` der Cloud-Anmeldung, aber mit
/// sichtbarem Label statt nur Platzhalter.
InputDecoration runtimeFieldDecoration(
  BuildContext context, {
  required String label,
  String? hint,
  String? helperText,
  String? errorText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helperText,
    helperMaxLines: 3,
    errorText: errorText,
    errorMaxLines: 4,
    fillColor: Theme.of(context).colorScheme.secondaryContainer,
    suffixIcon: suffixIcon,
  );
}
