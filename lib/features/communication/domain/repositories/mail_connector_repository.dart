import '../entities/mail_connector.dart';

abstract interface class MailConnectorRepository {
  Stream<List<MailConnector>> watchConnectors();

  Future<String> beginMicrosoftConnection();
}
