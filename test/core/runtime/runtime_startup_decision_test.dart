import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_kind_store.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';
import 'package:syscat2/core/runtime/runtime_startup_decision.dart';

// `kIsWeb` ist in `flutter test` (VM) stets false — die Web-Fälle der
// Herkunftsregel selbst sind bereits in `runtime_profile_test.dart`
// abgedeckt. Hier geht es um die native Verzweigung: gespeicherte Wahl vs.
// Cloud-Fallback.
void main() {
  group('resolveStartupRuntimeKind (nativ)', () {
    test('eine gespeicherte Wahl hat Vorrang', () async {
      final kind = await resolveStartupRuntimeKind(
        store: _MemoryKindStore(RuntimeKind.standalone),
      );

      expect(kind, RuntimeKind.standalone);
    });

    test(
      'ohne gespeicherte Wahl fällt der Start auf Cloud zurück — die '
      'eigene Runtime bleibt über den Wechsel-Hinweis im Login-Formular '
      'erreichbar',
      () async {
        final kind = await resolveStartupRuntimeKind(
          store: _MemoryKindStore(null),
        );

        expect(kind, RuntimeKind.cloud);
      },
    );
  });
}

class _MemoryKindStore implements RuntimeKindStore {
  _MemoryKindStore(this._kind);

  RuntimeKind? _kind;

  @override
  Future<RuntimeKind?> load() async => _kind;

  @override
  Future<void> save(RuntimeKind kind) async => _kind = kind;

  @override
  Future<void> clear() async => _kind = null;
}
