import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/runtime/runtime_profile.dart';

// Deckt ab, dass die Betriebsvariante keine Compile-Zeit-Festlegung mehr ist:
// `NOVOOA_RUNTIME` liefert nur noch den Vorgabewert, `forKind` erlaubt jede
// unterstützte Variante zur Laufzeit (siehe
// `docs/notes/web-herkunftsregel.md`).
void main() {
  test('runtimeKindOrNull erkennt die persistierbaren Namen', () {
    expect(runtimeKindOrNull('cloud'), RuntimeKind.cloud);
    expect(runtimeKindOrNull('standalone'), RuntimeKind.standalone);
  });

  test('runtimeKindOrNull liefert null statt zu werfen', () {
    expect(runtimeKindOrNull('irgendwas'), isNull);
    expect(runtimeKindOrNull(''), isNull);
    expect(runtimeKindOrNull(null), isNull);
  });

  test('die Namen der Enum-Werte sind die persistierten Werte', () {
    for (final kind in RuntimeKind.values) {
      expect(runtimeKindOrNull(kind.name), kind);
    }
  });

  test('forKind übernimmt die angeforderte Variante', () {
    expect(RuntimeProfile.forKind(RuntimeKind.cloud).isCloud, isTrue);
    expect(RuntimeProfile.forKind(RuntimeKind.cloud).isStandalone, isFalse);
  });

  test('ohne dart-define ist cloud der Vorgabewert', () {
    expect(RuntimeProfile.defaultKind, RuntimeKind.cloud);
    expect(RuntimeProfile.fromEnvironment().kind, RuntimeKind.cloud);
  });

  test('forKind übernimmt die konfigurierte Workspace-Adresse', () {
    expect(
      RuntimeProfile.forKind(RuntimeKind.cloud).workspaceApiUri,
      Uri.parse('http://127.0.0.1:8090'),
    );
  });

  test('withWorkspaceApiUri behält die Variante bei', () {
    final profile = RuntimeProfile.forKind(RuntimeKind.cloud);

    final moved = profile.withWorkspaceApiUri(Uri.parse('http://host:9000'));

    expect(moved.kind, RuntimeKind.cloud);
    expect(moved.workspaceApiUri, Uri.parse('http://host:9000'));
  });

  test(
    'nativ sind beide Varianten wählbar — die Herkunftsregel gilt nur im Web',
    () {
      expect(kIsWeb, isFalse, reason: 'Dieser Test läuft in der Dart-VM.');
      expect(RuntimeProfile.supports(RuntimeKind.cloud), isTrue);
      expect(RuntimeProfile.supports(RuntimeKind.standalone), isTrue);
      expect(RuntimeProfile.supportedKinds, RuntimeKind.values);
    },
  );

  group('Herkunft bestimmt die Web-Variante', () {
    test('die Produktiv-Domain gilt als Cloud', () {
      expect(isCloudWebHost('app.novooa.de'), isTrue);
    });

    test('Firebase-Hosting zählt zur Cloud — Live-Channel und PR-Vorschau', () {
      expect(isCloudWebHost('syscat-90bff.web.app'), isTrue);
      expect(isCloudWebHost('syscat-90bff--pr-12-a1b2c3.web.app'), isTrue);
      expect(isCloudWebHost('syscat-90bff.firebaseapp.com'), isTrue);
    });

    test(
      'die Adressen, unter denen Nutzer:innen ihre eigene Runtime erreichen, '
      'sind keine Cloud-Herkunft',
      () {
        expect(isCloudWebHost('192.168.1.42'), isFalse);
        expect(isCloudWebHost('novooa.example.de'), isFalse);
        expect(isCloudWebHost('raspberrypi.local'), isFalse);
        expect(isCloudWebHost('127.0.0.1'), isFalse);
        expect(isCloudWebHost('localhost'), isFalse);
      },
    );

    test('eine fremde Domain mit ähnlichem Namen bleibt Standalone', () {
      expect(isCloudWebHost('novooa.de'), isFalse);
      expect(isCloudWebHost('app.novooa.de.example.com'), isFalse);
    });

    test('webRuntimeKindForOrigin bildet die Herkunft auf die Variante ab', () {
      expect(
        webRuntimeKindForOrigin(Uri.parse('https://app.novooa.de/')),
        RuntimeKind.cloud,
      );
      expect(
        webRuntimeKindForOrigin(Uri.parse('http://192.168.1.42:8090/')),
        RuntimeKind.standalone,
      );
      expect(
        webRuntimeKindForOrigin(Uri.parse('https://novooa.example.de/')),
        RuntimeKind.standalone,
      );
    });
  });
}
