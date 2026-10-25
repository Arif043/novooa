import 'package:equatable/equatable.dart';

import '../../domain/entities/google_account.dart';

sealed class GoogleAccountsState extends Equatable {
  const GoogleAccountsState();

  @override
  List<Object?> get props => [];
}

final class GoogleAccountsLoading extends GoogleAccountsState {
  const GoogleAccountsLoading();
}

final class GoogleAccountsFailure extends GoogleAccountsState {
  const GoogleAccountsFailure();
}

/// Geladen; eine leere Liste ist der Leerzustand mit „Google-Konto verbinden“.
final class GoogleAccountsLoaded extends GoogleAccountsState {
  const GoogleAccountsLoaded(this.accounts);

  final List<GoogleAccount> accounts;

  @override
  List<Object?> get props => [accounts];
}
