import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/assistant/presentation/mock/mock_assistant_replies.dart';

void main() {
  test('/mock liefert einen Plan mit Commands ohne LLM', () {
    const replies = MockAssistantReplies();

    expect(replies.matches(' /mock'), isTrue);
    expect(replies.matches('Hallo'), isFalse);
    final types = replies
        .replyTo('/mock')
        .actionSuggestions
        .map((suggestion) => suggestion.type);
    expect(types, contains('configureNode'));
  });
}
