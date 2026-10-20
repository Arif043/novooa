import 'package:equatable/equatable.dart';

import '../../domain/entities/runtime_user.dart';
import '../../domain/entities/runtime_user_failure.dart';

enum RuntimeUsersStatus { loading, ready, failure }

/// Was nach einer Aktion einmalig gemeldet wird.
enum RuntimeUsersConfirmation { roleChanged, deleted }

/// Ein frisch ausgegebener Einladungscode, der einmalig angezeigt wird.
class IssuedInvitation extends Equatable {
  const IssuedInvitation({required this.displayName, required this.invitation});

  final String displayName;
  final UserInvitation invitation;

  @override
  List<Object?> get props => [displayName, invitation];
}

class RuntimeUsersState extends Equatable {
  const RuntimeUsersState({
    this.status = RuntimeUsersStatus.loading,
    this.overview = const RuntimeUserOverview(users: [], maxUsers: null),
    this.failure,
    this.confirmation,
    this.issuedInvitation,
  });

  final RuntimeUsersStatus status;
  final RuntimeUserOverview overview;
  final RuntimeUserFailure? failure;
  final RuntimeUsersConfirmation? confirmation;
  final IssuedInvitation? issuedInvitation;

  RuntimeUsersState copyWith({
    RuntimeUsersStatus? status,
    RuntimeUserOverview? overview,
    RuntimeUserFailure? failure,
    RuntimeUsersConfirmation? confirmation,
    IssuedInvitation? issuedInvitation,
  }) => RuntimeUsersState(
    status: status ?? this.status,
    overview: overview ?? this.overview,
    failure: failure,
    confirmation: confirmation,
    issuedInvitation: issuedInvitation,
  );

  @override
  List<Object?> get props => [
    status,
    overview,
    failure,
    confirmation,
    issuedInvitation,
  ];
}
