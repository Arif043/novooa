import 'package:equatable/equatable.dart';

import 'google_drive_item.dart';

enum GoogleAccountStatus { active, reauthorizationRequired }

/// Ein Google-Konto, das mit dieser Runtime verbunden ist.
class GoogleAccount extends Equatable {
  const GoogleAccount({
    required this.id,
    required this.email,
    required this.status,
    this.sharedItems = const [],
  });

  final String id;
  final String email;
  final GoogleAccountStatus status;
  final List<GoogleDriveItem> sharedItems;

  bool get needsReauthorization =>
      status == GoogleAccountStatus.reauthorizationRequired;

  List<GoogleDriveItem> get sharedFolders =>
      sharedItems.where((item) => item.isFolder).toList();

  List<GoogleDriveItem> get sharedFiles =>
      sharedItems.where((item) => !item.isFolder).toList();

  GoogleAccount copyWith({
    String? email,
    GoogleAccountStatus? status,
    List<GoogleDriveItem>? sharedItems,
  }) {
    return GoogleAccount(
      id: id,
      email: email ?? this.email,
      status: status ?? this.status,
      sharedItems: sharedItems ?? this.sharedItems,
    );
  }

  @override
  List<Object?> get props => [id, email, status, sharedItems];
}
