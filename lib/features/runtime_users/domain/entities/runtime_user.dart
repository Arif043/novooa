import 'package:equatable/equatable.dart';

/// Admins verwalten Benutzer, Lizenz und Anbindungen; Mitglieder arbeiten mit
/// Aufgaben und Inhalten.
enum RuntimeRole {
  admin,
  member;

  bool get isAdmin => this == RuntimeRole.admin;
}

/// Ein Konto der Standalone-Runtime.
class RuntimeUser extends Equatable {
  const RuntimeUser({
    required this.uid,
    required this.loginName,
    required this.displayName,
    required this.role,
    required this.hasPassword,
  });

  final String uid;
  final String loginName;
  final String displayName;
  final RuntimeRole role;

  /// `false`, solange die Einladung nicht eingelöst ist.
  final bool hasPassword;

  @override
  List<Object?> get props => [uid, loginName, displayName, role, hasPassword];
}

/// Alle Konten und wie viele die Lizenz erlaubt (`null` = unbegrenzt).
class RuntimeUserOverview extends Equatable {
  const RuntimeUserOverview({required this.users, required this.maxUsers});

  final List<RuntimeUser> users;
  final int? maxUsers;

  bool get isFull => maxUsers != null && users.length >= maxUsers!;

  @override
  List<Object?> get props => [users, maxUsers];
}

/// Ein Einmalcode, mit dem eine Person ihr Passwort selbst setzt.
class UserInvitation extends Equatable {
  const UserInvitation({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [code, expiresAt];
}

/// Daten für ein neues Konto.
class NewRuntimeUser extends Equatable {
  const NewRuntimeUser({
    required this.displayName,
    required this.loginName,
    required this.role,
  });

  final String displayName;
  final String loginName;
  final RuntimeRole role;

  @override
  List<Object?> get props => [displayName, loginName, role];
}

/// Ein neues Konto mit seinem Einladungscode.
class CreatedRuntimeUser extends Equatable {
  const CreatedRuntimeUser({required this.user, required this.invitation});

  final RuntimeUser user;
  final UserInvitation invitation;

  @override
  List<Object?> get props => [user, invitation];
}
