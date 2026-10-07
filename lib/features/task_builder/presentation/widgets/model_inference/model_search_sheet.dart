import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_cubit.dart';
import '../../../../machine_learning/presentation/cubits/model_catalog_state.dart';
import 'model_search_filter.dart';
import 'model_search_results.dart';

/// Durchsucht globalen Katalog und eigene Modelle; liefert das gewählte Modell zurück.
Future<ModelCatalogEntry?> showModelSearchSheet(
  BuildContext context, {
  SpeechModelDirection? speechDirection,
}) {
  final cubit = context.read<ModelCatalogCubit>();
  return showModalBottomSheet<ModelCatalogEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _ModelSearchSheet(speechDirection: speechDirection),
    ),
  );
}

class _ModelSearchSheet extends StatefulWidget {
  const _ModelSearchSheet({required this.speechDirection});

  final SpeechModelDirection? speechDirection;

  @override
  State<_ModelSearchSheet> createState() => _ModelSearchSheetState();
}

class _ModelSearchSheetState extends State<_ModelSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filter = ModelSearchFilter(
      languageTag: Localizations.localeOf(context).toLanguageTag(),
      speechDirection: widget.speechDirection,
    );
    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Modell auswählen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Nach Name, Beschreibung oder Schlagwort suchen',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: BlocBuilder<ModelCatalogCubit, ModelCatalogState>(
                builder: (context, state) => ModelSearchResults(
                  state: state,
                  models: filter.apply(state.selectableEntries, _query),
                  hasQuery: _query.trim().isNotEmpty,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
