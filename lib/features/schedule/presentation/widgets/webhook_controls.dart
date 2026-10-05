import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/event_trigger_config.dart';

/// Einstellungen eines Webhook-Auslösers im Dialog. Die Adresse gibt es erst
/// nach dem Erstellen — das Token vergibt die Runtime.
class WebhookControls extends StatefulWidget {
  const WebhookControls({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final WebhookConfig value;
  final ValueChanged<WebhookConfig> onChanged;

  @override
  State<WebhookControls> createState() => _WebhookControlsState();
}

class _WebhookControlsState extends State<WebhookControls> {
  late final TextEditingController _header;
  late final TextEditingController _prefix;
  late final TextEditingController _secret;
  late final TextEditingController _parameter;
  late bool _verify;
  late WebhookSignatureAlgorithm _algorithm;
  late WebhookSignatureEncoding _encoding;

  @override
  void initState() {
    super.initState();
    final verification = widget.value.verification;
    final hmac = verification is HmacWebhookVerification ? verification : null;
    _verify = hmac != null;
    _header = TextEditingController(text: hmac?.header ?? '');
    _prefix = TextEditingController(text: hmac?.prefix ?? '');
    _secret = TextEditingController(text: widget.value.secret);
    _parameter = TextEditingController(text: widget.value.validationParameter);
    _algorithm = hmac?.algorithm ?? WebhookSignatureAlgorithm.sha256;
    _encoding = hmac?.encoding ?? WebhookSignatureEncoding.hex;
  }

  @override
  void dispose() {
    _header.dispose();
    _prefix.dispose();
    _secret.dispose();
    _parameter.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      WebhookConfig(
        verification: _verify
            ? HmacWebhookVerification(
                header: _header.text.trim(),
                algorithm: _algorithm,
                encoding: _encoding,
                prefix: _prefix.text,
              )
            : WebhookVerification.none,
        validationParameter: _parameter.text.trim(),
        secret: _verify ? _secret.text : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ein externes System ruft eine Adresse deiner Runtime auf und '
          'startet damit die Aufgabe. Die Adresse erhältst du nach dem '
          'Erstellen. Die Runtime muss dafür aus dem Internet erreichbar sein.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Signatur prüfen (empfohlen)'),
            subtitle: const Text(
              'Ohne Prüfung genügt die Adresse, um die Aufgabe zu starten.',
            ),
            value: _verify,
            onChanged: (value) {
              setState(() => _verify = value);
              _emit();
            },
          ),
        ),
        if (_verify) ...[
          TextField(
            controller: _header,
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(
              labelText: 'Kopfzeile mit der Signatur',
              hintText: 'X-Hub-Signature-256',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<WebhookSignatureAlgorithm>(
                  key: const Key('webhook-algorithm'),
                  isExpanded: true,
                  initialValue: _algorithm,
                  decoration: const InputDecoration(labelText: 'Verfahren'),
                  items: [
                    for (final item in WebhookSignatureAlgorithm.values)
                      DropdownMenuItem(value: item, child: Text(item.label)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _algorithm = value);
                    _emit();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<WebhookSignatureEncoding>(
                  key: const Key('webhook-encoding'),
                  isExpanded: true,
                  initialValue: _encoding,
                  decoration: const InputDecoration(labelText: 'Darstellung'),
                  items: [
                    for (final item in WebhookSignatureEncoding.values)
                      DropdownMenuItem(value: item, child: Text(item.label)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _encoding = value);
                    _emit();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _prefix,
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(
              labelText: 'Präfix der Signatur (optional)',
              hintText: 'sha256=',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _secret,
            obscureText: true,
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(
              labelText: 'Geheimnis',
              helperText:
                  'Wird verschlüsselt auf der Runtime gespeichert und nie '
                  'wieder angezeigt.',
              helperMaxLines: 3,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _parameter,
          onChanged: (_) => _emit(),
          decoration: const InputDecoration(
            labelText: 'Parameter der Einrichtungsprüfung (optional)',
            hintText: 'validationToken',
            helperText:
                'Manche Systeme (z. B. Microsoft Graph) erwarten beim '
                'Einrichten diesen Wert zurück.',
            helperMaxLines: 3,
          ),
        ),
      ],
    );
  }
}
