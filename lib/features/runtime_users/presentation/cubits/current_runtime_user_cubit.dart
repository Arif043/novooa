import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/runtime_user.dart';
import '../../domain/usecases/runtime_user_use_cases.dart';

sealed class CurrentRuntimeUserState extends Equatable {
  const CurrentRuntimeUserState();

  /// Nur ein geladenes Admin-Konto sieht Admin-Bereiche; im Zweifel nicht.
  bool get isAdmin => false;

  @override
  List<Object?> get props => [];
}

final class CurrentRuntimeUserLoading extends CurrentRuntimeUserState {
  const CurrentRuntimeUserLoading();
}

final class CurrentRuntimeUserLoaded extends CurrentRuntimeUserState {
  const CurrentRuntimeUserLoaded(this.user);

  final RuntimeUser user;

  @override
  bool get isAdmin => user.role.isAdmin;

  @override
  List<Object?> get props => [user];
}

final class CurrentRuntimeUserUnavailable extends CurrentRuntimeUserState {
  const CurrentRuntimeUserUnavailable();
}

/// Wer in der Standalone-App angemeldet ist und welche Rolle das Konto hat.
class CurrentRuntimeUserCubit extends Cubit<CurrentRuntimeUserState> {
  CurrentRuntimeUserCubit(this._loadCurrentUser)
    : super(const CurrentRuntimeUserLoading());

  final LoadCurrentRuntimeUser _loadCurrentUser;

  Future<void> load() async {
    emit(const CurrentRuntimeUserLoading());
    final userOrFailure = await _loadCurrentUser();
    if (isClosed) return;
    emit(
      userOrFailure.when(
        CurrentRuntimeUserLoaded.new,
        (_) => const CurrentRuntimeUserUnavailable(),
      ),
    );
  }
}
