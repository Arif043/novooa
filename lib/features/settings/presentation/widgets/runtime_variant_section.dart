import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syscat2/core/runtime/runtime_kind_preferences.dart';
import 'package:syscat2/core/runtime/runtime_kind_store.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/runtime_variant_switch_hint.dart';

import 'settings_section.dart';

/// Wechselt die Betriebsvariante (Cloud oder eigene lokale Runtime). Die
/// Wahl wird persistiert und überschreibt ab dem nächsten Start den
/// Build-Vorgabewert `NOVOOA_RUNTIME`. Ein Wechsel im laufenden Prozess ist
/// bewusst nicht vorgesehen: Firebase-Initialisierung, DI-Graph und
/// Anmeldung hängen an der Variante — ein Neustart ist der ehrlichere Weg
/// als ein halb umgebauter Zustand.
///
/// Wird in beiden Einstellungs-Oberflächen eingebunden (Cloud: Profil-Tab,
/// Standalone: Allgemein-Tab), damit der Rückweg aus jeder Variante
/// erreichbar ist.
class RuntimeVariantSection extends StatefulWidget {
  const RuntimeVariantSection({
    super.key,
    required this.currentKind,
    this.store,
  });

  final RuntimeKind currentKind;

  /// Nur für Tests überschrieben; im Betrieb greift der
  /// `SharedPreferences`-Speicher.
  final RuntimeKindStore? store;

  @override
  State<RuntimeVariantSection> createState() => _RuntimeVariantSectionState();
}

class _RuntimeVariantSectionState extends State<RuntimeVariantSection> {
  late final RuntimeKindStore _store =
      widget.store ?? RuntimeKindPreferences(SharedPreferencesAsync());
  RuntimeKind? _savedKind;
  bool _isSaving = false;

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
          'lokale Runtime arbeitet.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioGroup<RuntimeKind>(
            groupValue: _savedKind ?? widget.currentKind,
            // Kein Deaktivieren während des Speicherns: `RadioGroup`
            // verlangt einen Handler. Den Doppelklick-Schutz übernimmt
            // `_select` selbst.
            onChanged: (kind) => _select(kind!),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final kind in kinds) _RuntimeKindOption(kind: kind),
              ],
            ),
          ),
          if (_pendingRestart) ...[
            const SizedBox(height: AppSpacing.md),
            const _RestartHint(),
          ],
        ],
      ),
    );
  }

  bool get _pendingRestart =>
      _savedKind != null && _savedKind != widget.currentKind;

  Future<void> _select(RuntimeKind kind) async {
    if (_isSaving || kind == (_savedKind ?? widget.currentKind)) return;
    setState(() => _isSaving = true);
    try {
      await _store.save(kind);
      if (mounted) setState(() => _savedKind = kind);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

class _RestartHint extends StatelessWidget {
  const _RestartHint();

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
            Icon(Icons.restart_alt, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(child: Text(runtimeRestartHint)),
          ],
        ),
      ),
    );
  }
}
