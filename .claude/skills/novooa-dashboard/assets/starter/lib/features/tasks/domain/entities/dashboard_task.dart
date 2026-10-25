import 'package:equatable/equatable.dart';

import '../../../../shared/domain/ids.dart';

export '../../../../shared/domain/ids.dart';

/// Eine Aufgabe, die das Dashboard starten darf.
class DashboardTask extends Equatable {
  const DashboardTask({
    required this.id,
    required this.title,
    this.objective = '',
  });

  final TaskId id;
  final String title;

  /// Ziel der Aufgabe, wie im Aufgabenstudio beschrieben.
  final String objective;

  @override
  List<Object?> get props => [id, title, objective];
}

enum TaskStartFailure { rejected, unreachable }
