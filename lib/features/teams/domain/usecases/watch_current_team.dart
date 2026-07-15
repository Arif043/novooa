import '../entities/team_workspace.dart';
import '../repositories/team_repository.dart';

class WatchCurrentTeam {
  const WatchCurrentTeam(this._repository);

  final TeamRepository _repository;

  Stream<TeamWorkspace> call() {
    return _repository.watchCurrentTeam();
  }
}
