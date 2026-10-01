import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:syscat2/core/runtime/runtime_kind_preferences.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';

// Deckt die Persistenz der Betriebsvariante ab — inklusive der beiden
// Verwerfen-Pfade, die verhindern, dass ein unbrauchbarer gespeicherter Wert
// den App-Start blockiert.
void main() {
  const key = 'novooa.runtime.kind';
  late InMemorySharedPreferencesAsync backend;
  late RuntimeKindPreferences preferences;

  setUp(() {
    backend = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = backend;
    preferences = RuntimeKindPreferences(SharedPreferencesAsync());
  });

  Future<String?> storedValue() {
    return backend.getString(key, const SharedPreferencesOptions());
  }

  Future<void> store(String value) {
    return backend.setString(key, value, const SharedPreferencesOptions());
  }

  test('ohne gespeicherte Wahl liefert load null', () async {
    expect(await preferences.load(), isNull);
  });

  test('speichert und liest jede Variante', () async {
    for (final kind in RuntimeKind.values) {
      await preferences.save(kind);

      expect(await preferences.load(), kind);
    }
  });

  test('persistiert den Enum-Namen, nicht den Index', () async {
    await preferences.save(RuntimeKind.standalone);

    expect(await storedValue(), 'standalone');
  });

  test(
    'verwirft einen unbekannten gespeicherten Wert und räumt ihn weg',
    () async {
      await store('irgendwas-altes');

      expect(await preferences.load(), isNull);
      expect(await storedValue(), isNull);
    },
  );

  test('überschreibt eine frühere Wahl', () async {
    await preferences.save(RuntimeKind.standalone);
    await preferences.save(RuntimeKind.cloud);

    expect(await preferences.load(), RuntimeKind.cloud);
  });

  test('clear verwirft eine gespeicherte Wahl', () async {
    await preferences.save(RuntimeKind.standalone);

    await preferences.clear();

    expect(await preferences.load(), isNull);
    expect(await storedValue(), isNull);
  });

  test('clear ohne gespeicherte Wahl bleibt wirkungslos', () async {
    await preferences.clear();

    expect(await preferences.load(), isNull);
  });
}
