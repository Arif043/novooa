import '../repositories/mail_connector_repository.dart';

class BeginMicrosoftConnection {
  const BeginMicrosoftConnection(this._repository);

  final MailConnectorRepository _repository;

  Future<String> call() => _repository.beginMicrosoftConnection();
}
