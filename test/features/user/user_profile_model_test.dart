import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/domain/unique_id.dart';
import 'package:syscat2/features/user/domain/entities/user_email.dart';
import 'package:syscat2/features/user/domain/entities/user_profile.dart';
import 'package:syscat2/features/user/infrastructure/models/user_profile_model.dart';

void main() {
  test('toDocument erzeugt Firestore-Dokument fuer UserProfile', () {
    final model = UserProfileModel.fromDomain(
      UserProfile(
        id: const UniqueId('user.1'),
        email: UserEmail.tryCreate('ada@example.com')!,
        displayName: 'Ada',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );
    final document = model.toDocument();
    expect(document['uid'], 'user.1');
    expect(document['email'], 'ada@example.com');
    expect(document['displayName'], 'Ada');
    expect(document['createdAt'], isA<Timestamp>());
    expect(document['updatedAt'], isA<Timestamp>());
  });

  test('toDocument kann createdAt fuer Updates auslassen', () {
    final model = UserProfileModel(
      id: 'user.1',
      email: 'ada@example.com',
      displayName: 'Ada',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    final document = model.toDocument(includeCreatedAt: false);
    expect(document.containsKey('createdAt'), isFalse);
    expect(document['uid'], 'user.1');
    expect(document['updatedAt'], isA<Timestamp>());
  });
}
