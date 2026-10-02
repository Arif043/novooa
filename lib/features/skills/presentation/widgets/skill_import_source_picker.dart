import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../cubits/skill_import_cubit.dart';
import 'skill_catalog_panel.dart';

enum _Source { github, archive, folder, catalog }

/// Wahl der Importquelle: GitHub-Adresse, ZIP-Datei, Ordner (Desktop) oder Katalog.
class SkillImportSourcePicker extends StatefulWidget {
  const SkillImportSourcePicker({super.key});

  @override
  State<SkillImportSourcePicker> createState() =>
      _SkillImportSourcePickerState();
}

class _SkillImportSourcePickerState extends State<SkillImportSourcePicker> {
  _Source _source = _Source.github;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SkillImportCubit>();
    final sources = [
      _Source.github,
      _Source.archive,
      if (cubit.canPickFolder) _Source.folder,
      _Source.catalog,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SegmentedButton<_Source>(
            showSelectedIcon: false,
            segments: [for (final source in sources) _segment(source)],
            selected: {_source},
            onSelectionChanged: (selection) =>
                setState(() => _source = selection.first),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(child: _Content(source: _source)),
      ],
    );
  }

  ButtonSegment<_Source> _segment(_Source source) => ButtonSegment(
    value: source,
    label: Text(switch (source) {
      _Source.github => 'GitHub',
      _Source.archive => 'ZIP',
      _Source.folder => 'Ordner',
      _Source.catalog => 'Katalog',
    }),
  );
}

class _Content extends StatelessWidget {
  const _Content({required this.source});

  final _Source source;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SkillImportCubit>();
    return switch (source) {
      _Source.github => const _GitHubForm(),
      _Source.archive => _PickAction(
        text:
            'Wähle eine ZIP-Datei mit einem oder mehreren Skill-Ordnern '
            '(jeweils mit einer SKILL.md).',
        label: 'ZIP-Datei wählen',
        icon: Icons.folder_zip_outlined,
        onPressed: cubit.pickArchive,
      ),
      _Source.folder => _PickAction(
        text:
            'Wähle den Ordner eines Skills oder einen Ordner, der mehrere '
            'Skill-Ordner enthält.',
        label: 'Ordner wählen',
        icon: Icons.folder_open_outlined,
        onPressed: cubit.pickFolder,
      ),
      _Source.catalog => const SkillCatalogPanel(),
    };
  }
}

class _GitHubForm extends StatefulWidget {
  const _GitHubForm();

  @override
  State<_GitHubForm> createState() => _GitHubFormState();
}

class _GitHubFormState extends State<_GitHubForm> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    context.read<SkillImportCubit>().startFromGitHub(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Öffentliches Repository oder ein Unterordner davon. Enthält es '
            'mehrere Skills, wählst du im nächsten Schritt aus.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'GitHub-Adresse',
              hintText: 'https://github.com/besitzer/repository',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _controller.text.trim().isEmpty ? null : _submit,
            child: const Text('Prüfen'),
          ),
        ],
      ),
    );
  }
}

class _PickAction extends StatelessWidget {
  const _PickAction({
    required this.text,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String text;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          ),
        ],
      ),
    );
  }
}
