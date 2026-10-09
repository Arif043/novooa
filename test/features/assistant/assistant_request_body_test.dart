import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_message.dart';
import 'package:syscat2/features/assistant/infrastructure/datasources/assistant_datasource.dart';

void main() {
  final history = [AssistantMessage.user('Hallo')];

  test('sendet die Antwortsprache mit', () {
    final body = assistantRequestBody(
      history: history,
      question: 'Hallo',
      languageCode: 'de',
    );

    expect(body['locale'], 'de');
  });

  test('lässt locale weg, wenn keine Sprache bekannt ist', () {
    final body = assistantRequestBody(history: history, question: 'Hallo');

    expect(body.containsKey('locale'), isFalse);
  });
}
