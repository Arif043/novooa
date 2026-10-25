import 'shopware_trigger_params.dart';

/// Name der Shopware-App zu einem Auslöser: nur Buchstaben und Ziffern, damit er
/// als Ordnername in `custom/apps` taugt, und je Auslöser verschieden.
String shopwareAppName(String triggerId) {
  final suffix = triggerId.replaceAll(RegExp('[^A-Za-z0-9]'), '');
  return 'NovooaAusloeser${suffix.length > 8 ? suffix.substring(0, 8) : suffix}';
}

/// Die Adresse, die Shopware aufruft: [address] ist novooa aus Sicht von
/// Shopware (im Docker-Netz z. B. `http://novooa:8090`).
String shopwareWebhookUrl(String address, String triggerId, String token) {
  final base = address.trim().replaceAll(RegExp(r'/+$'), '');
  return '$base/hooks/$triggerId/$token';
}

/// Die `manifest.xml` einer kleinen Shopware-App, die genau das Ereignis des
/// Auslösers an novooa meldet. Sie enthält keine Zugangsdaten außer dem Token
/// in der Adresse, das ohnehin zum Auslöser gehört. [label] und
/// [description] sind die übersetzten Texte, die Shopware zur App anzeigt.
String shopwareAppManifest({
  required String triggerId,
  required String token,
  required String address,
  required ShopwareTriggerParams params,
  required String label,
  required String description,
}) {
  final name = shopwareAppName(triggerId);
  final url = shopwareWebhookUrl(address, triggerId, token);
  final permissions = [
    for (final entity in params.readPermissions) '    <read>$entity</read>',
  ].join('\n');
  return '''<?xml version="1.0" encoding="UTF-8"?>
<manifest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://raw.githubusercontent.com/shopware/shopware/trunk/src/Core/Framework/App/Manifest/Schema/manifest-2.0.xsd">
  <meta>
    <name>$name</name>
    <label>novooa: ${_escape(label)}</label>
    <description>${_escape(description)}</description>
    <author>novooa</author>
    <copyright>novooa</copyright>
    <version>1.0.0</version>
    <license>proprietary</license>
  </meta>
  <permissions>
$permissions
  </permissions>
  <webhooks>
    <webhook name="${name}Webhook" url="${_escape(url)}" event="${params.webhookEvent}"/>
  </webhooks>
</manifest>
''';
}

String _escape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
