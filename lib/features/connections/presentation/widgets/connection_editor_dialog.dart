import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/connection.dart';
import '../../domain/entities/connection_draft.dart';
import '../../domain/entities/connection_test_result.dart';
import '../cubits/connections_cubit.dart';

enum _AuthKind { apiKey, bearer, oauth }

/// Editor für eine Verbindung. Das gespeicherte Geheimnis wird nie angezeigt;
/// beim Ändern lässt ein leeres Feld es unverändert.
class ConnectionEditorDialog extends StatefulWidget {
  const ConnectionEditorDialog({super.key, required this.cubit, this.existing});

  final ConnectionsCubit cubit;
  final Connection? existing;

  static Future<void> show(
    BuildContext context, {
    required ConnectionsCubit cubit,
    Connection? existing,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ConnectionEditorDialog(cubit: cubit, existing: existing),
    );
  }

  @override
  State<ConnectionEditorDialog> createState() => _ConnectionEditorDialogState();
}

class _ConnectionEditorDialogState extends State<ConnectionEditorDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _baseUrl = TextEditingController(
    text: widget.existing?.baseUrl ?? '',
  );
  late final TextEditingController _headerName = TextEditingController(
    text: switch (widget.existing?.auth) {
      ApiKeyAuth(:final headerName) => headerName,
      _ => 'X-API-Key',
    },
  );
  late final TextEditingController _tokenUrl = TextEditingController(
    text: switch (widget.existing?.auth) {
      OAuthClientCredentialsAuth(:final tokenUrl) => tokenUrl,
      _ => '',
    },
  );
  late final TextEditingController _clientId = TextEditingController(
    text: switch (widget.existing?.auth) {
      OAuthClientCredentialsAuth(:final clientId) => clientId,
      _ => '',
    },
  );
  late final TextEditingController _scope = TextEditingController(
    text: switch (widget.existing?.auth) {
      OAuthClientCredentialsAuth(:final scope) => scope,
      _ => '',
    },
  );
  final TextEditingController _secret = TextEditingController();
  final TextEditingController _testPath = TextEditingController();

  late _AuthKind _kind = switch (widget.existing?.auth) {
    BearerAuth() => _AuthKind.bearer,
    OAuthClientCredentialsAuth() => _AuthKind.oauth,
    _ => _AuthKind.apiKey,
  };
  late bool _tokenJson = switch (widget.existing?.auth) {
    OAuthClientCredentialsAuth(:final sendsJson) => sendsJson,
    _ => false,
  };

  /// Zuletzt aus der Basis-URL abgeleitete Token-URL der Vorlage; nur eine
  /// unveränderte Ableitung wird bei weiteren Eingaben nachgezogen.
  String? _derivedTokenUrl;
  bool _shopware = false;
  String? _error;
  bool _saving = false;
  bool _testing = false;
  ConnectionTestResult? _testResult;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _baseUrl,
      _headerName,
      _tokenUrl,
      _clientId,
      _scope,
      _secret,
      _testPath,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  ConnectionAuth get _auth => switch (_kind) {
    _AuthKind.apiKey => ApiKeyAuth(headerName: _headerName.text.trim()),
    _AuthKind.bearer => const BearerAuth(),
    _AuthKind.oauth => OAuthClientCredentialsAuth(
      tokenUrl: _tokenUrl.text.trim(),
      clientId: _clientId.text.trim(),
      scope: _scope.text.trim(),
      sendsJson: _tokenJson,
    ),
  };

  String get _secretLabel => switch (_kind) {
    _AuthKind.apiKey => 'API-Key',
    _AuthKind.bearer => 'Token',
    _AuthKind.oauth =>
      _shopware ? 'Geheimer Zugriffsschlüssel' : 'Client-Secret',
  };

  /// Vorlage für Shopware 6: OAuth mit dem Zugriffsschlüssel einer Integration;
  /// die Token-Anfrage geht als JSON, die Token-URL folgt der Shop-Adresse.
  void _applyShopware() {
    setState(() {
      _shopware = true;
      _kind = _AuthKind.oauth;
      _tokenJson = true;
      if (_name.text.trim().isEmpty) _name.text = 'Shopware';
      _deriveTokenUrl();
      _testPath.text = '/api/_info/version';
    });
  }

  void _deriveTokenUrl() {
    if (!_shopware) return;
    final current = _tokenUrl.text.trim();
    if (current.isNotEmpty && current != _derivedTokenUrl) return;
    final base = _baseUrl.text.trim().replaceFirst(RegExp(r'/+$'), '');
    _derivedTokenUrl = base.isEmpty ? '' : '$base/api/oauth/token';
    _tokenUrl.text = _derivedTokenUrl!;
  }

  String get _kindLabel => switch (_kind) {
    _AuthKind.apiKey => 'API-Key im Header',
    _AuthKind.bearer => 'Bearer-Token',
    _AuthKind.oauth => 'OAuth (Client Credentials)',
  };

  /// Die erste fehlende oder ungültige Eingabe, auf Deutsch; `null` wenn alles passt.
  String? _validate() {
    if (_name.text.trim().isEmpty) return 'Bitte gib einen Namen an.';
    if (!_isHttpUrl(_baseUrl.text)) {
      return 'Die Basis-URL muss mit https:// (oder http://) beginnen.';
    }
    if (_kind == _AuthKind.apiKey && _headerName.text.trim().isEmpty) {
      return 'Bitte gib den Namen des Headers an, z. B. X-API-Key.';
    }
    if (_kind == _AuthKind.oauth) {
      if (!_isHttpUrl(_tokenUrl.text)) {
        return 'Die Token-URL muss mit https:// (oder http://) beginnen.';
      }
      if (_clientId.text.trim().isEmpty) return 'Bitte gib die Client-ID an.';
    }
    final kindChanged =
        !_isNew && _auth.runtimeType != widget.existing!.auth.runtimeType;
    if ((_isNew || kindChanged) && _secret.text.trim().isEmpty) {
      return 'Bitte gib das $_secretLabel an.';
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.cubit.save(
      ConnectionDraft(
        name: _name.text,
        baseUrl: _baseUrl.text,
        auth: _auth,
        secret: _secret.text,
      ),
      id: widget.existing?.id,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final result = await widget.cubit.test(
      widget.existing!.id,
      path: _testPath.text,
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(_isNew ? 'Verbindung hinzufügen' : 'Verbindung bearbeiten'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isNew && !_shopware) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    key: const ValueKey('connection-template-shopware'),
                    avatar: const Icon(Icons.storefront_outlined, size: 18),
                    label: const Text('Vorlage: Shopware'),
                    onPressed: _applyShopware,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'z. B. Shopware',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _baseUrl,
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(_deriveTokenUrl),
                decoration: InputDecoration(
                  labelText: 'Basis-URL',
                  hintText: _shopware
                      ? 'https://shop.example.com'
                      : 'https://shop.example.com/api',
                ),
              ),
              if (_baseUrl.text.trim().toLowerCase().startsWith('http://'))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    'Mit http:// gehen Zugangsdaten unverschlüsselt über das Netz.',
                    style: TextStyle(color: colors.error),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<_AuthKind>(
                key: const ValueKey('connection-auth-kind'),
                initialValue: _kind,
                decoration: const InputDecoration(labelText: 'Anmeldung'),
                items: [
                  for (final kind in _AuthKind.values)
                    DropdownMenuItem(
                      value: kind,
                      child: Text(switch (kind) {
                        _AuthKind.apiKey => 'API-Key im Header',
                        _AuthKind.bearer => 'Bearer-Token',
                        _AuthKind.oauth => 'OAuth (Client Credentials)',
                      }),
                    ),
                ],
                onChanged: (kind) {
                  if (kind != null) setState(() => _kind = kind);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (_kind == _AuthKind.apiKey) ...[
                TextField(
                  controller: _headerName,
                  decoration: const InputDecoration(labelText: 'Header-Name'),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_kind == _AuthKind.oauth) ...[
                TextField(
                  controller: _tokenUrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Token-URL',
                    hintText: 'https://shop.example.com/api/oauth/token',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _clientId,
                  decoration: InputDecoration(
                    labelText: _shopware ? 'Zugriffsschlüssel-ID' : 'Client-ID',
                    helperText: _shopware
                        ? 'In Shopware: Einstellungen → System → Integrationen.'
                        : null,
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _scope,
                  decoration: const InputDecoration(
                    labelText: 'Scope (optional)',
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    key: const ValueKey('connection-token-json'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Token-Anfrage als JSON senden'),
                    subtitle: const Text(
                      'Manche Systeme (z. B. Shopware) erwarten JSON statt eines Formulars.',
                    ),
                    value: _tokenJson,
                    onChanged: (value) => setState(() => _tokenJson = value),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              TextField(
                controller: _secret,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: _secretLabel,
                  helperText: _isNew
                      ? null
                      : 'Gespeichert – leer lassen, um es zu behalten.',
                ),
              ),
              if (!_isNew) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Verbindung testen ($_kindLabel)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _testPath,
                  decoration: const InputDecoration(
                    labelText: 'Test-Pfad (optional)',
                    hintText: '/ping',
                    helperText: 'Getestet wird der gespeicherte Stand.',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: _testing ? null : _test,
                    child: Text(_testing ? 'Testet …' : 'Testen'),
                  ),
                ),
                if (_testResult case final result?)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          result.ok ? Icons.check_circle : Icons.error_outline,
                          size: 18,
                          color: result.ok ? Colors.green : colors.error,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(result.message)),
                      ],
                    ),
                  ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(_error!, style: TextStyle(color: colors.error)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Speichert …' : 'Speichern'),
        ),
      ],
    );
  }
}

bool _isHttpUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}
