import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/file_version.dart';
import '../../localization/file_display_texts.dart';

/// Über dem Inhalt, solange eine ältere Version angezeigt wird.
class OldVersionBanner extends StatelessWidget {
  const OldVersionBanner({
    super.key,
    required this.version,
    required this.onRestore,
    required this.onShowCurrent,
  });

  final FileVersion version;
  final VoidCallback onRestore;
  final VoidCallback onShowCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = FileDisplayTexts.of(context).dateTime(version.createdAt);
    return Semantics(
      liveRegion: true,
      child: Material(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, color: colors.onTertiaryContainer),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      LocaleKeys.files_old_version_banner.tr(
                        namedArgs: {'date': date},
                      ),
                      style: TextStyle(color: colors.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  TextButton(
                    onPressed: onShowCurrent,
                    child: Text(LocaleKeys.files_show_current.tr()),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore),
                    label: Text(LocaleKeys.files_version_restore.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
