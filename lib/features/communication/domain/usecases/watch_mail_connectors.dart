import '../entities/mail_connector.dart';
import '../repositories/mail_connector_repository.dart';

class WatchMailConnectors {
  const WatchMailConnectors(this._repository);

  final MailConnectorRepository _repository;

  Stream<List<MailConnector>> call() => _repository.watchConnectors();
}
