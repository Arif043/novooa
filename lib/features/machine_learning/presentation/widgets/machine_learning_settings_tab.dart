import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/model_catalog_import.dart';
import '../cubits/model_catalog_cubit.dart';
import '../cubits/model_catalog_state.dart';
import 'model_catalog_list.dart';
import 'model_download_list.dart';
import 'model_import_picker.dart';
import '../../../settings/presentation/widgets/settings_section.dart';

class MachineLearningSettingsTab extends StatefulWidget {
  const MachineLearningSettingsTab({super.key});

  @override
  State<MachineLearningSettingsTab> createState() =>
      _MachineLearningSettingsTabState();
}

class _MachineLearningSettingsTabState
    extends State<MachineLearningSettingsTab> {
  late final ModelCatalogCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<ModelCatalogCubit>()
      ..load()
      ..loadGlobal();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ModelCatalogCubit, ModelCatalogState>(
        listenWhen: (previous, current) =>
            previous.message != current.message && current.message != null,
        listener: (context, state) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.message!))),
        builder: (context, state) => _Content(state: state),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final ModelCatalogState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SettingsSection(
        icon: Icons.memory_outlined,
        title: 'Machine Learning',
        description:
            'Modelle aus dem Katalog, die diese Runtime gecacht hat, und '
            'eigene ONNX-Modelle.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Heading('Gecachte Modelle'),
            ModelDownloadList(state: state),
            ModelCatalogList(
              state: state,
              entries: state.cachedEntries,
              emptyText:
                  'Noch keine Modelle gecacht. Wähle im Aufgabenstudio in einem '
                  'ML-Baustein ein Modell aus dem Katalog, dann lädt die '
                  'Runtime es herunter.',
            ),
            const SizedBox(height: AppSpacing.lg),
            const _Heading('Eigene Modelle'),
            ModelCatalogList(
              state: state,
              entries: state.importedEntries,
              emptyText: 'Noch keine eigenen ONNX-Modelle importiert.',
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: state.isSaving ? null : () => _import(context),
                icon: state.isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined),
                label: Text(
                  state.isSaving
                      ? 'Wird importiert'
                      : 'ONNX-Modell importieren',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final value = await _pickImport(context);
    if (!context.mounted || value == null) return;
    await context.read<ModelCatalogCubit>().importModel(value);
  }

  Future<ModelCatalogImport?> _pickImport(BuildContext context) async {
    try {
      return await ModelImportPicker.pick();
    } on FormatException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return null;
    }
  }
}
