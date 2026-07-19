import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/assistant_context.dart';
import '../../domain/entities/assistant_message.dart';
import '../../domain/usecases/ask_assistant.dart';
import 'assistant_state.dart';

class AssistantCubit extends Cubit<AssistantState> {
  AssistantCubit({
    required this._askAssistant,
    required AssistantContext context,
  }) : super(AssistantState(context: context));

  final AskAssistant _askAssistant;

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
      final answer = await _askAssistant(
        context: state.context,
        history: updatedMessages,
        question: trimmedQuestion,
      );
      emit(
        state.copyWith(
          status: AssistantStatus.ready,
          messages: [...updatedMessages, answer],
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Assistant request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      emit(
        state.copyWith(
          status: AssistantStatus.failure,
          errorMessage: _errorMessageFor(error),
        ),
      );
    }
  }

  String _errorMessageFor(Object error) {
    if (kReleaseMode) return 'Der KI-Agent konnte gerade nicht antworten.';
    final details = error.toString();
    if (details.contains('firebasevertexai.googleapis.com')) {
      return 'Firebase AI Logic ist für dieses Projekt noch nicht aktiviert.';
    }
    if (details.toLowerCase().contains('api key')) {
      return 'Der Firebase Web API-Key wurde von Firebase AI Logic abgelehnt.';
    }
    if (details.toLowerCase().contains('quota')) {
      return 'Das Firebase-AI-Kontingent ist ausgeschöpft.';
    }
    if (details.toLowerCase().contains('location')) {
      return 'Firebase AI Logic ist an diesem Standort nicht verfügbar.';
    }
    return 'Der KI-Agent konnte nicht antworten: $details';
  }
}
