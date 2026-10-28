import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/adaptive_sheet.dart';
import '../../../domain/entities/team_folder.dart';
import '../team_folder_choice_list.dart';

/// Das gewählte Ziel; `folderId == null` ist die oberste Ebene. Abbruch
/// liefert `null` statt eines Ziels.
typedef MoveTarget = ({String? folderId});

Future<MoveTarget?> showMoveFileSheet(
  BuildContext context, {
  required List<TeamFolder> folders,
  required String? currentFolderId,
}) => showAdaptiveSheet<MoveTarget>(
  context: context,
  builder: (_, _) =>
      _MoveSheet(folders: folders, currentFolderId: currentFolderId),
);

class _MoveSheet extends StatefulWidget {
  const _MoveSheet({required this.folders, required this.currentFolderId});

  final List<TeamFolder> folders;
  final String? currentFolderId;

  @override
  State<_MoveSheet> createState() => _MoveSheetState();
}

class _MoveSheetState extends State<_MoveSheet> {
  late String? _selected = widget.currentFolderId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            LocaleKeys.files_move_title.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TeamFolderChoiceList(
              folders: widget.folders,
              selectedFolderId: _selected,
              onSelected: (folderId) => setState(() => _selected = folderId),
            ),
          ),
        ),
        const Divider(height: 1),
        SheetFooter(
          onCancel: () => Navigator.of(context).pop(),
          cancelLabel: LocaleKeys.ui_abbrechen.tr(),
          confirmLabel: LocaleKeys.files_move_confirm.tr(),
          // Gleicher Ordner: nichts zu tun, das Sheet schließt nur.
          onConfirm: () => Navigator.of(context).pop(
            _selected == widget.currentFolderId ? null : (folderId: _selected),
          ),
        ),
      ],
    );
  }
}
