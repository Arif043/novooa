import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/ai_model_settings.dart';
import '../../domain/entities/ai_provider.dart';

class AiModelSettingsModel {
  const AiModelSettingsModel({
    required this.provider,
    required this.hasApiKey,
    required this.maskedApiKey,
    required this.updatedAt,
  });

  final String provider;
  final bool hasApiKey;
  final String maskedApiKey;
  final DateTime updatedAt;

  factory AiModelSettingsModel.fromDocument(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>? ?? {};
    return AiModelSettingsModel(
      provider: data['provider'] as String? ?? AiProvider.googleAi.id,
      hasApiKey: data['hasApiKey'] as bool? ?? false,
      maskedApiKey: data['maskedApiKey'] as String? ?? '',
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  factory AiModelSettingsModel.fromDomain(AiModelSettings settings) {
    return AiModelSettingsModel(
      provider: settings.provider.id,
      hasApiKey: settings.hasApiKey,
      maskedApiKey: settings.maskedApiKey,
      updatedAt: settings.updatedAt,
    );
  }

  Map<String, Object?> toDocument({bool useServerTimestamp = false}) {
    return {
      'provider': provider,
      'hasApiKey': hasApiKey,
      'maskedApiKey': maskedApiKey,
      'updatedAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updatedAt),
    };
  }

  AiModelSettings toDomain() {
    return AiModelSettings(
      provider: AiProvider.fromId(provider),
      hasApiKey: hasApiKey,
      maskedApiKey: maskedApiKey,
      updatedAt: updatedAt,
    );
  }

  static DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
