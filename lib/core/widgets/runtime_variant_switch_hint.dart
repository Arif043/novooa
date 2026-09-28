import 'package:flutter/material.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';
import 'package:syscat2/core/runtime/runtime_variant_switcher.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

/// Der Satz, den beide Wechsel-Oberflächen während des Wechsels zeigen —
/// bewusst eine Quelle, damit die Formulierung nicht auseinanderläuft.
const runtimeVariantSwitchingHint = 'Variante wird gewechselt …';

/// Kompakter Wechsel der Betriebsvariante **vor** der Anmeldung.
///
/// Notwendig, weil die Auswahl in den Einstellungen erst nach dem Login
/// erreichbar ist: Wer zu einer eigenen Runtime wechseln will, *weil* er
/// kein Cloud-Konto hat, käme dort nie an. Zeigt nur die jeweils andere
/// unterstützte Variante an; gibt es keine (heute: Web, das noch kein
/// Standalone kann), blendet sich der Hinweis aus. Der Wechsel selbst
/// passiert zur Laufzeit — kein Neustart nötig (siehe
/// `RuntimeVariantSwitcher`).
class RuntimeVariantSwitchHint extends StatefulWidget {
  const RuntimeVariantSwitchHint({
    super.key,
    required this.currentKind,
    this.isEnabled = true,
    this.switcher,
  });

  final RuntimeKind currentKind;
  final bool isEnabled;

  /// Nur für Tests überschrieben; im Betrieb kommt der Switcher aus
  /// `RuntimeVariantSwitcherScope`.
  final RuntimeVariantSwitcher? switcher;

  @override
  State<RuntimeVariantSwitchHint> createState() =>
      _RuntimeVariantSwitchHintState();
}

class _RuntimeVariantSwitchHintState extends State<RuntimeVariantSwitchHint> {
  bool _isSwitching = false;

  @override
  Widget build(BuildContext context) {
    final target = _targetKind;
    if (target == null) return const SizedBox.shrink();
    if (_isSwitching) return const _SwitchingNotice();
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
    setState(() => _isSwitching = true);
    final switcher = widget.switcher ?? RuntimeVariantSwitcherScope.of(context);
    // Kein `if (mounted)`-Schutz nötig für die Zeit danach: `switchTo`
    // ersetzt die gesamte Anwendung per `runApp` — dieses Widget existiert
    // im Erfolgsfall danach gar nicht mehr.
    await switcher.switchTo(target);
  }
}

class _SwitchingNotice extends StatelessWidget {
  const _SwitchingNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          runtimeVariantSwitchingHint,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
