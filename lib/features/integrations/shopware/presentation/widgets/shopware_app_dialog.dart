import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/shopware_app_manifest.dart';
import '../../domain/shopware_trigger_params.dart';
import '../shopware_trigger_texts.dart';

/// Zeigt die Shopware-App, die ein Auslöser braucht: `manifest.xml` zum
/// Kopieren und die Schritte zum Installieren. Die App enthält keine
/// Geheimnisse außer dem Token in der Adresse und lässt sich jederzeit neu
/// erzeugen.
class ShopwareAppDialog extends StatefulWidget {
  const ShopwareAppDialog({
    super.key,
    required this.triggerId,
    required this.token,
    required this.params,
    required this.initialAddress,
  });

  static Future<void> show(
    BuildContext context, {
    required String triggerId,
    required String token,
    required ShopwareTriggerParams params,
    required String initialAddress,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ShopwareAppDialog(
        triggerId: triggerId,
        token: token,
        params: params,
        initialAddress: initialAddress,
      ),
    );
  }

  final String triggerId;
  final String token;
  final ShopwareTriggerParams params;

  /// novooa, wie der Client es erreicht; im Docker-Netz weicht das meist vom
  /// Namen ab, unter dem Shopware novooa erreicht.
  final String initialAddress;

  @override
  State<ShopwareAppDialog> createState() => _ShopwareAppDialogState();
}

class _ShopwareAppDialogState extends State<ShopwareAppDialog> {
  late final TextEditingController _address = TextEditingController(
    text: widget.initialAddress,
  )..addListener(() => setState(() {}));

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  String get _manifest => shopwareAppManifest(
    triggerId: widget.triggerId,
    token: widget.token,
    address: _address.text,
    params: widget.params,
    label: widget.params.summary,
    description: LocaleKeys.shopware_ui_app_manifest_description.tr(
      namedArgs: {'summary': widget.params.summary},
    ),
  );

  bool get _looksLocal {
    final host = Uri.tryParse(_address.text.trim())?.host ?? '';
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = shopwareAppName(widget.triggerId);
    return AlertDialog(
      title: Text(LocaleKeys.shopware_ui_app_title.tr()),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocaleKeys.shopware_ui_app_intro.tr(
                  namedArgs: {'summary': widget.params.summary},
                ),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('shopware-app-address'),
                controller: _address,
                decoration: InputDecoration(
                  labelText: LocaleKeys.shopware_ui_app_address.tr(),
                  helperText: LocaleKeys.shopware_ui_app_address_helper.tr(),
                  helperMaxLines: 3,
                  errorText: _looksLocal
                      ? LocaleKeys.shopware_ui_app_address_localhost.tr()
                      : null,
                  errorMaxLines: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                LocaleKeys.shopware_ui_app_step_folder.tr(),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                LocaleKeys.shopware_ui_app_step_folder_text.tr(
                  namedArgs: {'name': name},
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _CodeBox(
                text: _manifest,
                fieldKey: const Key('shopware-app-manifest'),
                onCopy: () => _copy(
                  _manifest,
                  LocaleKeys.shopware_ui_app_manifest_copied.tr(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                LocaleKeys.shopware_ui_app_step_install.tr(),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(LocaleKeys.shopware_ui_app_step_install_text.tr()),
              const SizedBox(height: AppSpacing.sm),
              _CodeBox(
                text: 'bin/console app:install --activate $name',
                fieldKey: const Key('shopware-app-command'),
                onCopy: () => _copy(
                  'bin/console app:install --activate $name',
                  LocaleKeys.shopware_ui_app_command_copied.tr(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                LocaleKeys.shopware_ui_app_permissions.tr(
                  namedArgs: {
                    'entities': widget.params.readPermissions.join(', '),
                  },
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(LocaleKeys.shopware_ui_app_close.tr()),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.text,
    required this.fieldKey,
    required this.onCopy,
  });

  final String text;
  final Key fieldKey;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                text,
                key: fieldKey,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: LocaleKeys.shopware_ui_app_copy.tr(),
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}
