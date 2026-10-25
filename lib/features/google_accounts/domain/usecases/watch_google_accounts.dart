import '../entities/google_account.dart';
import '../repositories/google_account_repository.dart';

class WatchGoogleAccounts {
  const WatchGoogleAccounts(this._repository);

  final GoogleAccountRepository _repository;

  Stream<List<GoogleAccount>> call() => _repository.watchAccounts();
}
