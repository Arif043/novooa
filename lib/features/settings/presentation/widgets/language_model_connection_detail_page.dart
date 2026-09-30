import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection.dart';
import 'package:syscat2/features/language_models/presentation/cubits/language_model_connections_cubit.dart';

/// Vollseite (Slide-in via `CupertinoPageRoute`) mit den Modellen eines
/// verbundenen Anbieters, inkl. Möglichkeit die Verbindung zu entfernen.
/// Nutzt ein normales Material-`Scaffold` statt `CupertinoPageScaffold`, um
/// visuell konsistent mit dem restlichen Studio zu bleiben — „Cupertino-like“
/// bezieht sich hier auf die Slide-Transition und die Bestätigung per
/// [showIosActionSheet], nicht auf den kompletten Seitenaufbau.
class LanguageModelConnectionDetailPage extends StatelessWidget {
  const LanguageModelConnectionDetailPage({
    super.key,
    required this.connection,
    required this.models,
    required this.connectionsCubit,
  });

  final LanguageModelConnection connection;
  final List<LanguageModel> models;
  final LanguageModelConnectionsCubit connectionsCubit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(connection.name),
        actions: [
          IconButton(
            tooltip: 'Verbindung entfernen',
            onPressed: () => _confirmRemoval(context),
            icon: const Icon(Icons.link_off),
          ),
        ],
      ),
      body: models.isEmpty ? _emptyState(context) : _modelList(),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Für diesen Anbieter wurden keine Modelle gefunden.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _modelList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: models.length,
      itemBuilder: (context, index) {
        final model = models[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.memory_outlined),
          title: Text(model.name),
          subtitle: Text(model.modelId),
        );
      },
    );
  }

  Future<void> _confirmRemoval(BuildContext context) async {
    final confirmed = await showIosActionSheet<bool>(
      context: context,
      title: connection.name,
      message: 'Verbindung wirklich entfernen? Verbundene Modelle stehen '
          'danach nicht mehr zur Verfügung.',
      actions: const [
        IosAction(
          label: 'Verbindung entfernen',
          value: true,
          isDestructive: true,
        ),
      ],
    );
    if (confirmed != true) return;
    await connectionsCubit.removeConnection(connection.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}
