import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/shopware_app_manifest.dart';
import '../../domain/shopware_trigger_params.dart';

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
      title: const Text('Shopware-App einrichten'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Shopware meldet „${widget.params.summary}“ über eine kleine '
                'App an novooa. Du richtest sie einmal ein.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('shopware-app-address'),
                controller: _address,
                decoration: InputDecoration(
                  labelText: 'Adresse von novooa aus Sicht von Shopware',
                  helperText:
                      'Laufen beide in Docker, ist das der Containername, z. B. '
                      'http://novooa:8090.',
                  helperMaxLines: 3,
                  errorText: _looksLocal
                      ? 'Aus dem Shopware-Container ist localhost nicht novooa.'
                      : null,
                  errorMaxLines: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('1. Ordner anlegen', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                'Lege in der Shopware-Installation den Ordner '
                'custom/apps/$name an und speichere darin die Datei '
                'manifest.xml mit diesem Inhalt:',
              ),
              const SizedBox(height: AppSpacing.sm),
              _CodeBox(
                text: _manifest,
                fieldKey: const Key('shopware-app-manifest'),
                onCopy: () => _copy(_manifest, 'manifest.xml kopiert.'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('2. App installieren', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              const Text('Führe in Shopware aus:'),
              const SizedBox(height: AppSpacing.sm),
              _CodeBox(
                text: 'bin/console app:install --activate $name',
                fieldKey: const Key('shopware-app-command'),
                onCopy: () => _copy(
                  'bin/console app:install --activate $name',
                  'Befehl kopiert.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Die Verbindung braucht Leserechte auf '
                '${widget.params.readPermissions.join(', ')}, weil novooa die '
                'Daten zum Ereignis darüber nachlädt.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
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
            tooltip: 'Kopieren',
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}
