import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

import '../../../../core/theme/app_spacing.dart';
import 'script_code_editor.dart';

/// Öffnet den Python-Editor im Vollbild. Nutzt dieselbe [CodeController]-
/// Instanz wie die kompakte Vorschau im Konfigurations-Panel — kein
/// zusätzlicher Zustand, keine Gefahr, dass Panel und Dialog auseinander-
/// laufen. Die kompakte Vorschau (fix wenige Zeilen, ~480px schmales Panel)
/// reicht nicht, um ernsthaft Python zu schreiben.
Future<void> showScriptFullscreenEditor(
  BuildContext context, {
  required CodeController controller,
  required ValueChanged<String> onChanged,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog.fullscreen(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _FullscreenEditorContent(
            controller: controller,
            onChanged: onChanged,
          ),
        ),
      ),
    ),
  );
}

class _FullscreenEditorContent extends StatelessWidget {
  const _FullscreenEditorContent({
    required this.controller,
    required this.onChanged,
  });

  final CodeController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FullscreenEditorHeader(),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ScriptCodeEditor(
            controller: controller,
            onChanged: onChanged,
            expands: true,
          ),
        ),
      ],
    );
  }
}

class _FullscreenEditorHeader extends StatelessWidget {
  const _FullscreenEditorHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            LocaleKeys.ui_script_bearbeiten.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          tooltip: LocaleKeys.ui_schliessen.tr(),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
