import 'package:equatable/equatable.dart';

import '../../domain/entities/assistant_context.dart';
import '../../domain/entities/assistant_message.dart';

enum AssistantStatus { ready, loading, failure }

class AssistantState extends Equatable {
  const AssistantState({
    required this.context,
    this.status = AssistantStatus.ready,
    this.messages = const [],
    this.errorMessage,
  });

  final AssistantContext context;
  final AssistantStatus status;
  final List<AssistantMessage> messages;
  final String? errorMessage;

  bool get isLoading => status == AssistantStatus.loading;

  AssistantState copyWith({
    AssistantContext? context,
    AssistantStatus? status,
    List<AssistantMessage>? messages,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AssistantState(
      context: context ?? this.context,
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [context, status, messages, errorMessage];
}
