import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/adaptive_sheet.dart';

/// Ein wählbarer Eintrag (Datei, Notiz, …) im [AttachmentPickerSheet].
class AttachmentPickerItem {
  const AttachmentPickerItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

/// Auswahl eines Anhangs: Bottom Sheet auf dem Handy, macOS-Sheet am Desktop
/// (siehe [showAdaptiveSheet]). Ein Tipp hängt den Eintrag an und schließt das
/// Sheet; bereits angehängte Einträge sind markiert und nicht wählbar.
class AttachmentPickerSheet extends StatelessWidget {
  const AttachmentPickerSheet({
    super.key,
    required this.style,
    required this.title,
    required this.items,
    required this.selectedIds,
    required this.emptyMessage,
  });

  final AdaptiveSheetStyle style;
  final String title;
  final List<AttachmentPickerItem> items;
  final Set<String> selectedIds;
  final String emptyMessage;

  /// Liefert die ID des gewählten Eintrags oder `null` bei Abbruch.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<AttachmentPickerItem> items,
    required Set<String> selectedIds,
    required String emptyMessage,
  }) {
    return showAdaptiveSheet<String>(
      context: context,
      builder: (_, style) => AttachmentPickerSheet(
        style: style,
        title: title,
        items: items,
        selectedIds: selectedIds,
        emptyMessage: emptyMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWindow = style.isWindow;
    final maxHeight = isWindow
        ? 520.0
        : MediaQuery.sizeOf(context).height * 0.7;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Flexible(child: _list(context)),
          if (isWindow) ...[
            const Divider(height: 1),
            SheetFooter(onCancel: () => Navigator.of(context).pop()),
          ],
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(emptyMessage, textAlign: TextAlign.center),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) => _tile(context, items[index]),
    );
  }

  Widget _tile(BuildContext context, AttachmentPickerItem item) {
    final selected = selectedIds.contains(item.id);
    return ListTile(
      enabled: !selected,
      leading: Icon(selected ? Icons.check_circle : item.icon),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: selected ? null : () => Navigator.of(context).pop(item.id),
    );
  }
}
