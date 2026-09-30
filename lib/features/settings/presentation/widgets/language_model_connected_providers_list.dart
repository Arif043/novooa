import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_connections_cubit.dart';

import 'language_model_connection_detail_page.dart';
import 'language_model_connection_list_tile.dart';

/// Liste der verbundenen Anbieter (Standalone). Ersetzt die vormals flache
/// Modell-Liste — ein Anbieter kann mehrere Modelle besitzen, siehe
/// `LanguageModel.connectionId`.
class LanguageModelConnectedProvidersList extends StatelessWidget {
  const LanguageModelConnectedProvidersList({
    super.key,
    required this.connections,
    required this.models,
    required this.connectionsCubit,
    required this.isEmpty,
  });

  final List<LanguageModelConnection> connections;
  final List<LanguageModel> models;
  final LanguageModelConnectionsCubit connectionsCubit;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Text(
        'Noch kein Anbieter verbunden.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      children: connections
          .map((connection) => _tileFor(context, connection))
          .toList(growable: false),
    );
  }

  Widget _tileFor(BuildContext context, LanguageModelConnection connection) {
    final connectionModels = models
        .where((model) => model.connectionId == connection.id)
        .toList(growable: false);
    return LanguageModelConnectionListTile(
      connection: connection,
      modelCount: connectionModels.length,
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (_) => LanguageModelConnectionDetailPage(
            connection: connection,
            models: connectionModels,
            connectionsCubit: connectionsCubit,
          ),
        ),
      ),
    );
  }
}
