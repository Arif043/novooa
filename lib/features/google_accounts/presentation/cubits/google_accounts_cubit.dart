import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';

import '../../domain/entities/google_account.dart';
import '../../domain/usecases/begin_google_authorization.dart';
import '../../domain/usecases/watch_google_accounts.dart';
import 'google_accounts_state.dart';

/// Zeigt die verbundenen Google-Konten und startet die Anmeldung im Browser.
/// Das Ergebnis der Anmeldung kommt nicht hierher zurück, sondern als neue
/// Liste über den Realtime-Kanal der Runtime.
class GoogleAccountsCubit extends Cubit<GoogleAccountsState> {
  GoogleAccountsCubit(this._watchAccounts, this._beginAuthorization)
    : super(const GoogleAccountsLoading());

  final WatchGoogleAccounts _watchAccounts;
  final BeginGoogleAuthorization _beginAuthorization;
  StreamSubscription<List<GoogleAccount>>? _subscription;

  Future<void> load() async {
    emit(const GoogleAccountsLoading());
    await _subscription?.cancel();
    _subscription = _watchAccounts().listen(
      (accounts) => emit(GoogleAccountsLoaded(accounts)),
      onError: (Object error, StackTrace stackTrace) {
        logException(
          message: 'Google-Konten konnten nicht geladen werden.',
          error: error,
          stackTrace: stackTrace,
          name: 'google_accounts',
        );
        emit(const GoogleAccountsFailure());
      },
    );
  }

  /// Adresse der Google-Anmeldung oder `null`, wenn die Runtime sie nicht
  /// liefern konnte (dann meldet die Oberfläche den Fehler).
  Future<String?> beginAuthorization({String? loginHint}) async {
    try {
      return await _beginAuthorization(loginHint: loginHint);
    } catch (error, stackTrace) {
      logException(
        message: 'Google-Anmeldung konnte nicht gestartet werden.',
        error: error,
        stackTrace: stackTrace,
        name: 'google_accounts',
      );
      return null;
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
