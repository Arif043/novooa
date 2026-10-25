import '../repositories/google_account_repository.dart';

class BeginGoogleAuthorization {
  const BeginGoogleAuthorization(this._repository);

  final GoogleAccountRepository _repository;

  Future<String> call({String? loginHint}) =>
      _repository.beginAuthorization(loginHint: loginHint);
}
