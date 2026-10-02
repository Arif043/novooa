import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection.dart';

import 'package:syscat2/features/language_models/presentation/widgets/language_model_provider_logo.dart';

/// Ein verbundener Anbieter in der Sprachmodelle-Übersicht. Tap öffnet die
/// Detailseite mit den Modellen dieses Anbieters (siehe
/// `language_model_connection_detail_page.dart`).
class LanguageModelConnectionListTile extends StatelessWidget {
  const LanguageModelConnectionListTile({
    super.key,
    required this.connection,
    required this.modelCount,
    required this.onTap,
  });

  final LanguageModelConnection connection;
  final int modelCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: providerLogo(
        context,
        provider: connection.provider,
        size: AppSpacing.lg,
      ),
      title: Text(connection.name),
      subtitle: Text(_subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String get _subtitle {
    if (modelCount == 0) return 'Keine Modelle gefunden';
    if (modelCount == 1) return '1 Modell';
    return '$modelCount Modelle';
  }
}
