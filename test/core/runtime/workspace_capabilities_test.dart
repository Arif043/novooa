import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';
import 'package:syscat2/core/runtime/workspace_capabilities.dart';

// Deckt ab, dass `WorkspaceCapabilities` die einzige Quelle für „ist ein
// Feature in dieser Betriebsvariante verfügbar?“ ist (siehe
// `docs/architecture/betriebsvarianten.md`, Blocker 6) — insbesondere für
// `push`, das zuvor als `RuntimeProfile.pushNotificationsEnabled` an einer
// zweiten Stelle dieselbe Frage beantwortet hat und in `main.dart` zusätzlich
// vom Erfolg des `Firebase.initializeApp()`-Aufrufs zur Laufzeit abhing. Die
// Plattformgrenze (kein FCM auf Windows/Linux) ist jetzt Teil von `forKind`
// selbst, nicht mehr ein zur Laufzeit entdeckter Sonderfall.
void main() {
  test('die Cloud bekommt alle bekannten Fähigkeiten außer Standalone-only', () {
    final capabilities = WorkspaceCapabilities.forKind(RuntimeKind.cloud);

    expect(capabilities.assistant, isTrue);
    expect(capabilities.dataCollections, isFalse);
    expect(capabilities.modelCatalog, isFalse);
    expect(capabilities.push, isTrue);
  });

  test(
    'Standalone-Push bleibt ohne NOVOOA_PUSH_ENABLED aus, damit eine lokale '
    'Runtime keine Firebase-Initialisierung erzwingt',
    () {
      final capabilities = WorkspaceCapabilities.forKind(
        RuntimeKind.standalone,
      );

      expect(capabilities.assistant, isTrue);
      expect(capabilities.dataCollections, isTrue);
      expect(capabilities.modelCatalog, isTrue);
      expect(capabilities.push, isFalse);
    },
  );
}
