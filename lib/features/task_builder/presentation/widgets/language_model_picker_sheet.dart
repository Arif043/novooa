import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/adaptive_sheet.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_draft.dart';
import 'package:syscat2/features/language_models/presentation/widgets/language_model_provider_logo.dart';

import 'language_model_provider_groups.dart';

/// Ergebnis der Auswahl: `''` steht für das Standardmodell.
const defaultLanguageModelId = '';

/// Bottom Sheet in zwei Schritten: erst der Anbieter, dann das konkrete
/// Modell. Liefert die Modell-ID, [defaultLanguageModelId] für das
/// Standardmodell oder `null`, wenn das Sheet ohne Auswahl geschlossen wird.
class LanguageModelPickerSheet {
  const LanguageModelPickerSheet._();

  static Future<String?> show(
    BuildContext context, {
    required List<LanguageModel> models,
    required String selectedModelId,
  }) {
    final groups = groupModelsByProvider(models);
    return showAdaptiveSheet<String>(
      context: context,
      builder: (_, style) => _PickerContent(
        style: style,
        groups: groups,
        selectedModelId: selectedModelId,
      ),
    );
  }
}

class _PickerContent extends StatefulWidget {
  const _PickerContent({
    required this.style,
    required this.groups,
    required this.selectedModelId,
  });

  final AdaptiveSheetStyle style;
  final List<LanguageModelProviderGroup> groups;
  final String selectedModelId;

  @override
  State<_PickerContent> createState() => _PickerContentState();
}

class _PickerContentState extends State<_PickerContent> {
  LanguageModelProviderGroup? _group;

  /// Standardhöhe des Fenster-Sheets; bei kleinen Fenstern begrenzt es die Karte.
  static const _windowSheetHeight = 520.0;

  @override
  Widget build(BuildContext context) {
    final group = _group;
    final isWindow = widget.style.isWindow;
    return SizedBox(
      height: isWindow
          ? _windowSheetHeight
          : MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        children: [
          _Header(
            title: group?.label ?? 'Anbieter',
            leading: isWindow ? null : _mobileLeading(group),
          ),
          const Divider(height: 1),
          Expanded(child: _pages(group)),
          if (isWindow) ...[
            const Divider(height: 1),
            SheetFooter(
              onCancel: () => Navigator.of(context).pop(),
              onBack: group == null
                  ? null
                  : () => setState(() => _group = null),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mobileLeading(LanguageModelProviderGroup? group) {
    if (group == null) {
      return TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Abbrechen'),
      );
    }
    return TextButton.icon(
      onPressed: () => setState(() => _group = null),
      icon: const Icon(Icons.chevron_left),
      label: const Text('Anbieter'),
    );
  }

  Widget _pages(LanguageModelProviderGroup? group) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: group == null
          ? _ProviderList(
              key: const ValueKey('providers'),
              groups: widget.groups,
              selectedModelId: widget.selectedModelId,
              onProvider: (selected) => setState(() => _group = selected),
            )
          : _ModelList(
              key: ValueKey(group.label),
              group: group,
              selectedModelId: widget.selectedModelId,
            ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, this.leading});

  final String title;

  /// Nur im Bottom Sheet; das Fenster-Sheet führt seine Schaltflächen in der
  /// Fußzeile.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: SizedBox(
        height: kToolbarHeight,
        child: NavigationToolbar(
          leading: leading,
          middle: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _ProviderList extends StatelessWidget {
  const _ProviderList({
    super.key,
    required this.groups,
    required this.selectedModelId,
    required this.onProvider,
  });

  final List<LanguageModelProviderGroup> groups;
  final String selectedModelId;
  final ValueChanged<LanguageModelProviderGroup> onProvider;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.auto_awesome_outlined),
          title: const Text('Standardmodell verwenden'),
          trailing: selectedModelId == defaultLanguageModelId
              ? const _SelectedMark()
              : null,
          onTap: () => Navigator.of(context).pop(defaultLanguageModelId),
        ),
        const Divider(height: 1),
        if (groups.isEmpty) const _EmptyHint(),
        for (final group in groups)
          ListTile(
            leading: _ProviderIcon(provider: group.provider),
            title: Text(group.label),
            subtitle: Text(_countLabel(group.models.length)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (group.contains(selectedModelId)) const _SelectedMark(),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => onProvider(group),
          ),
      ],
    );
  }

  String _countLabel(int count) => count == 1 ? '1 Modell' : '$count Modelle';
}

/// Markenlogo des Anbieters; Modelle ohne bekannten Anbieter bekommen ein
/// neutrales Symbol.
class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon({required this.provider});

  final LanguageModelProvider? provider;

  @override
  Widget build(BuildContext context) {
    final provider = this.provider;
    return SizedBox.square(
      dimension: AppSpacing.lg,
      child: provider == null
          ? Icon(
              Icons.layers_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : providerLogo(context, provider: provider, size: AppSpacing.lg),
    );
  }
}

class _ModelList extends StatelessWidget {
  const _ModelList({
    super.key,
    required this.group,
    required this.selectedModelId,
  });

  final LanguageModelProviderGroup group;
  final String selectedModelId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final model in group.models)
          ListTile(
            title: Text(
              model.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              model.modelId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: model.id == selectedModelId
                ? const _SelectedMark()
                : null,
            onTap: () => Navigator.of(context).pop(model.id),
          ),
      ],
    );
  }
}

class _SelectedMark extends StatelessWidget {
  const _SelectedMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ausgewählt',
      child: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Text(
        'Noch kein Sprachmodell verbunden. Unter Einstellungen kannst du '
        'Anbieter hinzufügen.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
