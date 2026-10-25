import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/google_accounts/domain/entities/google_account.dart';

/// Auswahl des Google-Kontos. Ein nicht mehr verbundenes Konto bleibt sichtbar,
/// statt den Baustein stillschweigend umzustellen.
class GoogleAccountPickerField extends StatelessWidget {
  const GoogleAccountPickerField({
    super.key,
    required this.selectedId,
    required this.accounts,
    required this.onChanged,
  });

  final String selectedId;
  final List<GoogleAccount> accounts;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final missing =
        selectedId.isNotEmpty && !accounts.any((a) => a.id == selectedId);
    return DropdownButtonFormField<String>(
      key: ValueKey('google-account-$selectedId-${accounts.length}'),
      initialValue: selectedId.isEmpty ? null : selectedId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: LocaleKeys.google_drive_account.tr(),
        helperText: accounts.isEmpty
            ? LocaleKeys.google_drive_no_accounts_hint.tr()
            : null,
        helperMaxLines: 2,
      ),
      items: [
        for (final account in accounts)
          DropdownMenuItem(
            value: account.id,
            child: Text(account.email, overflow: TextOverflow.ellipsis),
          ),
        if (missing)
          DropdownMenuItem(
            value: selectedId,
            child: Text(LocaleKeys.google_drive_account_missing.tr()),
          ),
      ],
      onChanged: (id) {
        if (id != null) onChanged(id);
      },
    );
  }
}
