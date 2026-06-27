import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';

import '../../domain/entities/ai_model_settings.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/api_key.dart';
import '../../domain/entities/settings_failure.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/ai_model_settings_model.dart';

class FirestoreSettingsRepository implements SettingsRepository {
  const FirestoreSettingsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Result<AiModelSettings, SettingsFailure>> getAiModelSettings(
    UniqueId userId,
  ) async {
    try {
      final snapshot = await _settingsReference(userId).get();
      if (!snapshot.exists) return Success(AiModelSettings.defaults());
      return Success(AiModelSettingsModel.fromDocument(snapshot).toDomain());
    } catch (_) {
      return const Error(SettingsFailure(SettingsFailureKind.loadFailed));
    }
  }

  @override
  Future<Result<AiModelSettings, SettingsFailure>> saveAiProviderSettings({
    required UniqueId userId,
    required AiProvider provider,
    required ApiKey apiKey,
  }) async {
    try {
      final settings = _settingsFor(provider, apiKey);
      final batch = _firestore.batch();
      batch.set(
        _settingsReference(userId),
        AiModelSettingsModel.fromDomain(
          settings,
        ).toDocument(useServerTimestamp: true),
      );
      batch.set(_secretReference(userId), _secretDocument(provider, apiKey));
      await batch.commit();
      return Success(settings);
    } catch (_) {
      return const Error(SettingsFailure(SettingsFailureKind.saveFailed));
    }
  }

  DocumentReference<Map<String, dynamic>> _settingsReference(UniqueId userId) {
    return _firestore
        .collection('users')
        .doc(userId.value)
        .collection('settings')
        .doc('aiModel');
  }

  DocumentReference<Map<String, dynamic>> _secretReference(UniqueId userId) {
    return _firestore
        .collection('users')
        .doc(userId.value)
        .collection('secrets')
        .doc('aiProvider');
  }

  Map<String, Object?> _secretDocument(AiProvider provider, ApiKey apiKey) {
    return {
      'provider': provider.id,
      'apiKey': apiKey.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AiModelSettings _settingsFor(AiProvider provider, ApiKey apiKey) {
    return AiModelSettings(
      provider: provider,
      hasApiKey: true,
      maskedApiKey: _mask(apiKey.value),
      updatedAt: DateTime.now(),
    );
  }

  String _mask(String value) {
    final visible = value.length < 4
        ? value
        : value.substring(value.length - 4);
    return '**** $visible';
  }
}
