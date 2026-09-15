class RuntimeEndpoint {
  const RuntimeEndpoint._(this.address);

  static const int port = 8090;

  final String address;

  Uri get apiUri => Uri(scheme: 'http', host: address, port: port);

  factory RuntimeEndpoint.fromAddress(String value) {
    final address = value.trim();
    if (!_isPrivateIpv4(address)) {
      throw const RuntimeEndpointValidationFailure();
    }
    return RuntimeEndpoint._(address);
  }

  factory RuntimeEndpoint.fromUri(Uri value) {
    if (value.scheme != 'http') throw const RuntimeEndpointValidationFailure();
    return RuntimeEndpoint.fromAddress(value.host);
  }
}

class RuntimeEndpointValidationFailure implements Exception {
  const RuntimeEndpointValidationFailure();

  @override
  String toString() => 'Ungültige Runtime-Adresse.';
}

bool _isPrivateIpv4(String address) {
  final octets = address.split('.');
  if (octets.length != 4) return false;
  final values = octets.map(int.tryParse).toList(growable: false);
  if (values.any((value) => value == null || value < 0 || value > 255)) {
    return false;
  }
  final first = values[0]!;
  final second = values[1]!;
  return first == 127 ||
      first == 10 ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 168);
}
