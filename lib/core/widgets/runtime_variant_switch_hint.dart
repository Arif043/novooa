import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syscat2/core/runtime/runtime_kind_preferences.dart';
import 'package:syscat2/core/runtime/runtime_kind_store.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

/// Der Satz, den beide Wechsel-Oberflächen zeigen — bewusst eine Quelle,
/// damit die Formulierung nicht auseinanderläuft.
const runtimeRestartHint =
    'Gespeichert. Starte novooa neu, damit die Variante übernommen wird.';

/// Kompakter Wechsel der Betriebsvariante **vor** der Anmeldung.
///
/// Notwendig, weil die Auswahl in den Einstellungen erst nach dem Login
/// erreichbar ist: Wer zu einer eigenen Runtime wechseln will, *weil* er
/// kein Cloud-Konto hat, käme dort nie an. Zeigt nur die jeweils andere
/// unterstützte Variante an; gibt es keine (heute: Web, das noch kein
/// Standalone kann), blendet sich der Hinweis aus.
class RuntimeVariantSwitchHint extends StatefulWidget {
  const RuntimeVariantSwitchHint({
    super.key,
    required this.currentKind,
    this.isEnabled = true,
    this.store,
  });

  final RuntimeKind currentKind;
  final bool isEnabled;

  /// Nur für Tests überschrieben.
  final RuntimeKindStore? store;

  @override
  State<RuntimeVariantSwitchHint> createState() =>
      _RuntimeVariantSwitchHintState();
}

class _RuntimeVariantSwitchHintState extends State<RuntimeVariantSwitchHint> {
  late final RuntimeKindStore _store =
      widget.store ?? RuntimeKindPreferences(SharedPreferencesAsync());
  bool _didSwitch = false;

  @override
  Widget build(BuildContext context) {
    final target = _targetKind;
    if (target == null) return const SizedBox.shrink();
    if (_didSwitch) return const _RestartNotice();
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      children: [
        Text(
          _questionFor(target),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: widget.isEnabled ? () => _switchTo(target) : null,
          child: Text(_actionFor(target)),
        ),
      ],
    );
  }

  /// Die einzige andere unterstützte Variante — `null`, wenn es keine gibt.
  RuntimeKind? get _targetKind {
    for (final kind in RuntimeProfile.supportedKinds) {
      if (kind != widget.currentKind) return kind;
    }
    return null;
  }

  String _questionFor(RuntimeKind target) => switch (target) {
    RuntimeKind.standalone => 'Du nutzt novooa Standalone?',
    RuntimeKind.cloud => 'Du nutzt die novooa-Cloud?',
  };

  String _actionFor(RuntimeKind target) => switch (target) {
    RuntimeKind.standalone => 'Zur eigenen Runtime wechseln',
    RuntimeKind.cloud => 'Zur Cloud wechseln',
  };

  Future<void> _switchTo(RuntimeKind target) async {
    await _store.save(target);
    if (mounted) setState(() => _didSwitch = true);
  }
}

class _RestartNotice extends StatelessWidget {
  const _RestartNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.restart_alt, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            runtimeRestartHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
