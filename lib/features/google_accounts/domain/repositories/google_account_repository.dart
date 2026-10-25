import '../entities/google_account.dart';

/// Google-Konten der Runtime. Verbunden wird im Browser; die Runtime erfährt
/// davon über ihr Wake-up und meldet die geänderte Liste.
abstract interface class GoogleAccountRepository {
  Stream<List<GoogleAccount>> watchAccounts();

  /// Adresse der Google-Anmeldung mit Picker. Mit [loginHint] wählt Google das
  /// Konto vor, etwa um weitere Dateien freizugeben.
  Future<String> beginAuthorization({String? loginHint});
}
