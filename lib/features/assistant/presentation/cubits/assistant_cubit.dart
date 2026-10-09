import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/assistant_context.dart';
import '../../domain/entities/assistant_message.dart';
import '../../domain/usecases/ask_assistant.dart';
import '../mock/mock_assistant_replies.dart';
import 'assistant_state.dart';

class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit({
    required this._askAssistant,
    required AssistantContext context,
    this.mockReplies = const MockAssistantReplies(),
  }) : super(AssistantState(context: context));

  final AskAssistant _askAssistant;
  final MockAssistantReplies mockReplies;

  void setContext(AssistantContext context) {
    if (state.context.route == context.route) return;
    emit(state.copyWith(context: context, clearError: true));
  }

  Future<void> ask(String question) async {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty || state.isLoading) return;
    final userMessage = AssistantMessage.user(trimmedQuestion);
    final updatedMessages = [...state.messages, userMessage];
    emit(
      state.copyWith(
        status: AssistantStatus.loading,
        messages: updatedMessages,
        clearError: true,
      ),
    );
    try {
      final answer = await _answerTo(trimmedQuestion, updatedMessages);
      emit(
        state.copyWith(
          status: AssistantStatus.ready,
          messages: [...updatedMessages, answer],
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AssistantStatus.failure,
          errorMessage: _errorMessageFor(error),
        ),
      );
    }
  }

  Future<AssistantMessage> _answerTo(
    String question,
    List<AssistantMessage> history,
  ) async {
    if (kDebugMode && mockReplies.matches(question)) {
      return mockReplies.replyTo(question);
    }
    return _askAssistant(
      context: state.context,
      history: history,
      question: question,
    );
  }

  String _errorMessageFor(Object error) {
    if (kReleaseMode) return 'Der KI-Agent konnte gerade nicht antworten.';
    final details = error.toString();
    if (details.toLowerCase().contains('quota')) {
      return 'Das Gemini-Kontingent ist ausgeschöpft.';
    }
    if (details.toLowerCase().contains('deadline')) {
      return 'Die Anfrage an den KI-Agenten hat zu lange gedauert.';
    }
    if (details.toLowerCase().contains('unauthenticated')) {
      return 'Bitte melde dich erneut an.';
    }
    return 'Der KI-Agent konnte nicht antworten: $details';
  }
}
