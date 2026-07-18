import 'package:bloc/bloc.dart';

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
    } catch (_) {
      emit(
        state.copyWith(
          status: AssistantStatus.failure,
          errorMessage: 'Der KI-Agent konnte gerade nicht antworten.',
        ),
      );
    }
  }
}
