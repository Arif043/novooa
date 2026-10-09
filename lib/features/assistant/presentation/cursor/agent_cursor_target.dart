import 'package:equatable/equatable.dart';

/// Stabile Kennung eines Bedienelements, das der Agent-Cursor ansteuern kann.
class AgentCursorTarget extends Equatable {
  const AgentCursorTarget(this.key);

  final String key;

  @override
  List<Object?> get props => [key];
}
