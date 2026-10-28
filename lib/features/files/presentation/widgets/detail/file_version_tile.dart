import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/file_version.dart';
import '../../../../../core/widgets/ios_context_menu.dart';
import '../../localization/file_display_texts.dart';

/// Eine Version im Verlauf: Zeitpunkt, Größe samt Änderung zur Vorversion,
/// „Aktuell“ und die Aktionen dieser Version.
class FileVersionTile extends StatelessWidget {
  const FileVersionTile({
    super.key,
    required this.version,
    required this.isCurrent,
    required this.isSelected,
    required this.sizeDelta,
    required this.onShow,
    required this.onDownload,
    required this.onRestore,
  });

  final FileVersion version;
  final bool isCurrent;
  final bool isSelected;

  /// `null` bei der ersten Version.
  final int? sizeDelta;
  final VoidCallback onShow;
  final VoidCallback onDownload;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final texts = FileDisplayTexts.of(context);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      selected: isSelected,
      label: LocaleKeys.files_version_named.tr(
        namedArgs: {'date': texts.dateTime(version.createdAt)},
      ),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: colors.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        leading: Icon(isCurrent ? Icons.radio_button_checked : Icons.history),
        title: _Title(
          text: texts.relative(version.createdAt),
          isCurrent: isCurrent,
        ),
        subtitle: Text(
          [texts.dateTime(version.createdAt), _sizeLabel(texts)].join(' · '),
        ),
        trailing: _VersionMenu(
          isCurrent: isCurrent,
          onDownload: onDownload,
          onRestore: onRestore,
        ),
        onTap: onShow,
      ),
    );
  }

  String _sizeLabel(FileDisplayTexts texts) {
    final delta = sizeDelta;
    final change = switch (delta) {
      null => LocaleKeys.files_version_first.tr(),
      0 => LocaleKeys.files_version_same_size.tr(),
      _ => texts.sizeDelta(delta)!,
    };
    return '${texts.size(version.sizeBytes)} ($change)';
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.text, required this.isCurrent});

  final String text;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (!isCurrent) return Text(text);
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text),
        DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.primaryContainer,
            shape: const StadiumBorder(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs / 2,
            ),
            child: Text(
              LocaleKeys.files_version_current.tr(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _VersionAction { download, restore }

class _VersionMenu extends StatelessWidget {
  const _VersionMenu({
    required this.isCurrent,
    required this.onDownload,
    required this.onRestore,
  });

  final bool isCurrent;
  final VoidCallback onDownload;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return IosContextMenuButton<_VersionAction>(
      tooltip: LocaleKeys.files_more_actions.tr(),
      entries: [
        IosContextMenuItem(
          value: _VersionAction.download,
          icon: Icons.download_outlined,
          label: LocaleKeys.files_version_download.tr(),
        ),
        if (!isCurrent)
          IosContextMenuItem(
            value: _VersionAction.restore,
            icon: Icons.restore,
            label: LocaleKeys.files_version_restore.tr(),
          ),
      ],
      onSelected: (action) => switch (action) {
        _VersionAction.download => onDownload(),
        _VersionAction.restore => onRestore(),
      },
    );
  }
}
