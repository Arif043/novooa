import 'dart:async';

import 'package:syscat2/features/google_accounts/domain/entities/google_account.dart';
import 'package:syscat2/features/google_accounts/domain/repositories/google_account_repository.dart';
import 'package:syscat2/features/google_accounts/domain/usecases/begin_google_authorization.dart';
import 'package:syscat2/features/google_accounts/domain/usecases/watch_google_accounts.dart';
import 'package:syscat2/features/google_accounts/presentation/cubits/google_accounts_cubit.dart';

/// Google-Konten im Speicher; `emit` und `fail` steuern den Stream im Test.
class FakeGoogleAccountRepository implements GoogleAccountRepository {
  FakeGoogleAccountRepository([this.accountsOnListen]);

  /// Was ein neues Abonnement sofort bekommt; `null` heißt: erst bei `emit`.
  List<GoogleAccount>? accountsOnListen;
  StreamController<List<GoogleAccount>>? _current;
  String? authorizationUrl = 'https://accounts.google.test/auth';
  final loginHints = <String?>[];

  void emit(List<GoogleAccount> accounts) => _current?.add(accounts);
  void fail() => _current?.addError(StateError('Relay nicht erreichbar'));

  /// Jedes Abonnement bekommt einen eigenen Kanal; `emit` und `fail` gehen an
  /// das jüngste, wie bei einem erneuten Laden.
  @override
  Stream<List<GoogleAccount>> watchAccounts() {
    final controller = StreamController<List<GoogleAccount>>();
    final initial = accountsOnListen;
    if (initial != null) controller.onListen = () => controller.add(initial);
    _current = controller;
    return controller.stream;
  }

  @override
  Future<String> beginAuthorization({String? loginHint}) async {
    loginHints.add(loginHint);
    final url = authorizationUrl;
    if (url == null) throw StateError('Relay nicht erreichbar');
    return url;
  }
}

GoogleAccountsCubit googleAccountsCubitFor(GoogleAccountRepository repository) {
  return GoogleAccountsCubit(
    WatchGoogleAccounts(repository),
    BeginGoogleAuthorization(repository),
  );
}
