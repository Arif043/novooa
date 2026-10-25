import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

// Deckt die Persistenz der Runtime-Adresse ab, insbesondere `clear()` — Teil
// des vollständigen Resets beim Abmelden (siehe
// `RuntimeConnectionCubit.signOut`).
void main() {
  const key = 'novooa.runtime.address';
  late InMemorySharedPreferencesAsync backend;
  late RuntimeEndpointPreferences preferences;

  setUp(() {
    backend = InMemorySharedPreferencesAsync.empty();
    SharedPreferencesAsyncPlatform.instance = backend;
    preferences = RuntimeEndpointPreferences(SharedPreferencesAsync());
  });

  Future<String?> storedValue() {
    return backend.getString(key, const SharedPreferencesOptions());
  }

  test('ohne gespeicherte Adresse liefert load null', () async {
    expect(await preferences.load(), isNull);
  });

  test('speichert und liest eine Adresse', () async {
    final endpoint = RuntimeEndpoint.fromAddress('192.168.1.42');

    await preferences.save(endpoint);

    expect((await preferences.load())?.address, '192.168.1.42');
  });

  test('clear verwirft eine gespeicherte Adresse', () async {
    await preferences.save(RuntimeEndpoint.fromAddress('192.168.1.42'));

    await preferences.clear();

    expect(await preferences.load(), isNull);
    expect(await storedValue(), isNull);
  });

  test('clear ohne gespeicherte Adresse bleibt wirkungslos', () async {
    await preferences.clear();

    expect(await preferences.load(), isNull);
  });
}
