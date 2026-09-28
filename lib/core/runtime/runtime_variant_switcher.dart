import 'package:flutter/widgets.dart';

import 'runtime_profile.dart';

/// Wechselt die Betriebsvariante zur Laufzeit — ohne Neustart.
///
/// Lebt bewusst außerhalb der DI (`serviceLocator`): Genau die DI ist es,
/// was beim Wechsel neu aufgebaut wird (siehe `service_locator.dart`s
/// `resetDependencies()`), sie kann sich also nicht selbst bereitstellen.
/// Die konkrete Umsetzung (`main.dart`) speichert die Wahl, setzt die DI
/// zurück und baut die Anwendung für die neue Variante neu auf.
abstract interface class RuntimeVariantSwitcher {
  Future<void> switchTo(RuntimeKind kind);
}

/// Reicht den [RuntimeVariantSwitcher] an jede Stelle unterhalb weiter, an
/// der ein Wechsel angeboten wird (Login-Fußzeile, Einstellungen) — von
/// `main.dart` einmal um jede `runApp`-Wurzel gelegt, damit sie nach einem
/// Wechsel automatisch neu bereitsteht.
class RuntimeVariantSwitcherScope extends InheritedWidget {
  const RuntimeVariantSwitcherScope({
    required this.switcher,
    required super.child,
    super.key,
  });

  final RuntimeVariantSwitcher switcher;

  /// Absichtlich `getInheritedWidgetOfExactType` statt
  /// `dependOnInheritedWidgetOfExactType`: Der Aufruf passiert aus
  /// Tap-Handlern, nicht aus `build()` — eine Rebuild-Abhängigkeit wäre hier
  /// unpassend und der Switcher wechselt ohnehin nie innerhalb eines Baums.
  static RuntimeVariantSwitcher of(BuildContext context) {
    final scope = context
        .getInheritedWidgetOfExactType<RuntimeVariantSwitcherScope>();
    assert(scope != null, 'Kein RuntimeVariantSwitcherScope im Baum gefunden.');
    return scope!.switcher;
  }

  @override
  bool updateShouldNotify(RuntimeVariantSwitcherScope oldWidget) =>
      switcher != oldWidget.switcher;
}
