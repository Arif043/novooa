/// Adresse einer novooa-Runtime.
///
/// Das Schema leitet sich aus der Art der Adresse ab, weil beide Betriebsarten
/// unterschiedliche Infrastruktur voraussetzen:
///
/// * **IP-Adresse** — direkter Zugriff auf die Runtime im vertrauenswürdigen
///   Netz, unverschlüsselt über HTTP auf [defaultInsecurePort]. novooa
///   terminiert selbst kein TLS.
/// * **Domain** — der Betreiber hat einen eigenen Reverse Proxy mit
///   Zertifikat davorgeschaltet; dann gilt HTTPS auf [defaultSecurePort].
///
/// Beides lässt sich überschreiben, indem das Schema ausdrücklich angegeben
/// wird (`http://novooa.fritz.box` für einen internen Hostnamen ohne
/// Zertifikat). Das geschieht nur auf ausdrückliche Eingabe hin — eine
/// Domain fällt niemals von selbst auf HTTP zurück, sonst wäre die
/// Verschlüsselung stillschweigend abschaltbar.
///
/// Ein abweichender Port lässt sich ebenfalls anhängen
/// (`192.168.1.42:9000`, `novooa.example.de:8443`).
class RuntimeEndpoint {
  const RuntimeEndpoint._(this.address, this.port, this.isSecure);

  /// Port der Runtime bei unverschlüsseltem Zugriff.
  static const int defaultInsecurePort = 8090;

  /// Port eines vorgeschalteten Reverse Proxy bei verschlüsseltem Zugriff.
  static const int defaultSecurePort = 443;

  final String address;
  final int port;

  /// Ob die Verbindung über TLS läuft.
  final bool isSecure;

  Uri get apiUri =>
      Uri(scheme: isSecure ? 'https' : 'http', host: address, port: port);

  /// Wie der Endpunkt gespeichert und angezeigt wird. Schema und Port
  /// erscheinen nur, wenn sie von der Vorgabe für diese Adressart abweichen —
  /// die Ausgabe lässt sich dadurch unverändert wieder einlesen.
  String get displayAddress {
    final prefix = isSecure == _defaultSecureFor(address)
        ? ''
        : '${isSecure ? 'https' : 'http'}://';
    final suffix = port == _defaultPortFor(isSecure) ? '' : ':$port';
    return '$prefix$address$suffix';
  }

  factory RuntimeEndpoint.fromAddress(String value) {
    final (explicitScheme, remainder) = _splitScheme(value.trim());
    final (host, port) = _splitHostAndPort(remainder);
    if (!_isIpv4(host) && !_isHostname(host)) {
      throw const RuntimeEndpointValidationFailure();
    }
    final isSecure = explicitScheme ?? _defaultSecureFor(host);
    return RuntimeEndpoint._(host, port ?? _defaultPortFor(isSecure), isSecure);
  }

  factory RuntimeEndpoint.fromUri(Uri value) {
    final port = value.hasPort ? ':${value.port}' : '';
    return RuntimeEndpoint.fromAddress('${value.scheme}://${value.host}$port');
  }
}

/// Ohne ausdrückliches Schema entscheidet die Adressart: IP-Adressen sprechen
/// die Runtime direkt und unverschlüsselt an, Domains laufen über einen
/// Reverse Proxy mit Zertifikat.
bool _defaultSecureFor(String host) => !_isIpv4(host);

int _defaultPortFor(bool isSecure) => isSecure
    ? RuntimeEndpoint.defaultSecurePort
    : RuntimeEndpoint.defaultInsecurePort;

class RuntimeEndpointValidationFailure implements Exception {
  const RuntimeEndpointValidationFailure();

  @override
  String toString() => 'Ungültige Runtime-Adresse.';
}

/// Liefert `true` für `https://`, `false` für `http://` und `null`, wenn kein
/// Schema angegeben wurde.
(bool?, String) _splitScheme(String value) {
  for (final (prefix, isSecure) in const [
    ('https://', true),
    ('http://', false),
  ]) {
    if (value.toLowerCase().startsWith(prefix)) {
      return (isSecure, value.substring(prefix.length));
    }
  }
  return (null, value);
}

(String, int?) _splitHostAndPort(String value) {
  final withoutPath = value.split('/').first;
  final separator = withoutPath.lastIndexOf(':');
  if (separator < 0) return (withoutPath, null);
  final port = int.tryParse(withoutPath.substring(separator + 1));
  if (port == null || port < 1 || port > 65535) return (withoutPath, null);
  return (withoutPath.substring(0, separator), port);
}

bool _isIpv4(String value) {
  final octets = value.split('.');
  if (octets.length != 4) return false;
  return octets.every((octet) {
    final number = int.tryParse(octet);
    return number != null && number >= 0 && number <= 255;
  });
}

/// Erlaubt einzelne Labels wie `localhost` ebenso wie `novooa.example.de`.
/// Rein numerische, punktgetrennte Werte sind bewusst ausgeschlossen: Sie
/// sehen wie eine fehlerhaft getippte IP-Adresse aus und wären als Domain
/// fast sicher ein Versehen.
bool _isHostname(String value) {
  if (value.isEmpty || value.length > 253) return false;
  if (!_hostnamePattern.hasMatch(value)) return false;
  return !value.split('.').every((label) => int.tryParse(label) != null);
}

final _hostnamePattern = RegExp(
  r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?'
  r'(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$',
);
