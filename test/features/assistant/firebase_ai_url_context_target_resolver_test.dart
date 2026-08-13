import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/assistant/infrastructure/models/firebase_ai_url_context_target_resolver.dart';

void main() {
  const detector = FirebaseAiUrlContextTargetResolver();

  test('normalisiert nackte Domains zu sicheren URLs', () {
    final urls = detector.urlsIn('Extrahiere Informationen aus laraevent.de.');

    expect(urls, [Uri.parse('https://laraevent.de')]);
  });

  test('erhält vollständige URLs einschließlich Pfad und Parameter', () {
    final urls = detector.urlsIn(
      'Fasse https://novooa.de/preise?source=agent zusammen.',
    );

    expect(urls, [Uri.parse('https://novooa.de/preise?source=agent')]);
  });

  test('erkennt keine E-Mail-Adresse als Webseite', () {
    final urls = detector.urlsIn('Schreibe an team@novooa.de.');

    expect(urls, isEmpty);
  });
}
