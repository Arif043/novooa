import 'package:flutter/material.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';
import 'package:syscat2/core/runtime/runtime_variant_switcher.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/runtime_variant_switch_hint.dart';

import 'settings_section.dart';

/// Wechselt die Betriebsvariante (Cloud oder eigene lokale Runtime) zur
/// Laufzeit — kein Neustart nötig (siehe `RuntimeVariantSwitcher`).
///
/// Wird in beiden Einstellungs-Oberflächen eingebunden (Cloud: Profil-Tab,
/// Standalone: Allgemein-Tab), damit der Rückweg aus jeder Variante
/// erreichbar ist.
class RuntimeVariantSection extends StatefulWidget {
  const RuntimeVariantSection({
    super.key,
    required this.currentKind,
    this.switcher,
  });

  final RuntimeKind currentKind;

  /// Nur für Tests überschrieben; im Betrieb kommt der Switcher aus
  /// `RuntimeVariantSwitcherScope`.
  final RuntimeVariantSwitcher? switcher;

  @override
  State<RuntimeVariantSection> createState() => _RuntimeVariantSectionState();
}

class _RuntimeVariantSectionState extends State<RuntimeVariantSection> {
  bool _isSwitching = false;

  @override
  Widget build(BuildContext context) {
    final kinds = RuntimeProfile.supportedKinds.toList();
    // Auf Plattformen mit nur einer möglichen Variante (heute: Web, das
    // keine lokale Runtime ansprechen kann) wäre eine Auswahl irreführend.
    if (kinds.length < 2) return const SizedBox.shrink();
    return SettingsSection(
      icon: Icons.swap_horiz,
      title: 'Betriebsvariante',
      description:
          'Legt fest, ob novooa gegen die Cloud oder gegen eine eigene '
          'lokale Runtime arbeitet. Der Wechsel gilt sofort.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioGroup<RuntimeKind>(
            groupValue: widget.currentKind,
            onChanged: (kind) => _select(kind!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final kind in kinds) _RuntimeKindOption(kind: kind),
              ],
            ),
          ),
          if (_isSwitching) ...[
            const SizedBox(height: AppSpacing.md),
            const _SwitchingHint(),
          ],
        ],
      ),
    );
  }

  Future<void> _select(RuntimeKind kind) async {
    if (_isSwitching || kind == widget.currentKind) return;
    setState(() => _isSwitching = true);
    final switcher = widget.switcher ?? RuntimeVariantSwitcherScope.of(context);
    // Kein `if (mounted)`-Schutz nötig für die Zeit danach: `switchTo`
    // ersetzt die gesamte Anwendung per `runApp` — dieses Widget existiert
    // im Erfolgsfall danach gar nicht mehr.
    await switcher.switchTo(kind);
  }
}

class _RuntimeKindOption extends StatelessWidget {
  const _RuntimeKindOption({required this.kind});

  final RuntimeKind kind;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<RuntimeKind>(
      value: kind,
      contentPadding: EdgeInsets.zero,
      title: Text(_titleFor(kind)),
      subtitle: Text(_descriptionFor(kind)),
    );
  }

  String _titleFor(RuntimeKind kind) => switch (kind) {
    RuntimeKind.cloud => 'Cloud',
    RuntimeKind.standalone => 'Eigene Runtime',
  };

  String _descriptionFor(RuntimeKind kind) => switch (kind) {
    RuntimeKind.cloud =>
      'Arbeitsbereich, Aufgaben und Dateien liegen in der novooa-Cloud.',
    RuntimeKind.standalone =>
      'Alles liegt auf einer Runtime, die du selbst betreibst.',
  };
}

class _SwitchingHint extends StatelessWidget {
  const _SwitchingHint();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Text(runtimeVariantSwitchingHint)),
          ],
        ),
      ),
    );
  }
}
