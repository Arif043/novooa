import '../../domain/entities/google_account.dart';
import '../../domain/entities/google_drive_item.dart';

/// Liest ein Google-Konto aus der Antwort der Runtime.
class GoogleAccountModel {
  const GoogleAccountModel._();

  static GoogleAccount fromJson(Map<Object?, Object?> json) {
    final items = json['sharedItems'];
    return GoogleAccount(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] == 'active'
          ? GoogleAccountStatus.active
          : GoogleAccountStatus.reauthorizationRequired,
      sharedItems: [
        if (items is List)
          for (final item in items.whereType<Map>()) _itemFrom(item),
      ],
    );
  }

  static GoogleDriveItem _itemFrom(Map<Object?, Object?> json) {
    return GoogleDriveItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? '',
    );
  }
}
