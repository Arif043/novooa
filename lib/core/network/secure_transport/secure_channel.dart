import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

/// Kryptografie des verschlüsselten Transports (Version 1) — das Gegenstück zu
/// `functions/src/shared/local/secure-transport-crypto.ts`. Ein gemeinsamer
/// Testvektor stellt sicher, dass beide Seiten dieselben Schlüssel ableiten.
///
/// Absichtlich die reinen Dart-Implementierungen (`Dart*`): Im Browser fehlt
/// `crypto.subtle`, sobald die Seite über HTTP im LAN geladen wird.
const transportInfo = 'novooa-transport-v1';
const nonceLength = 16;
const _keyLength = 32;
const _ivLength = 12;
const _tagLength = 16;

/// Richtung einer Nachricht; Teil der Zusatzdaten, damit eine Antwort nie als
/// Anfrage (oder umgekehrt) akzeptiert wird.
enum TransportDirection { request, response }

class SessionKeys {
  const SessionKeys({
    required this.clientToServer,
    required this.serverToClient,
  });

  final SecretKey clientToServer;
  final SecretKey serverToClient;
}

/// Die vom Client erzeugten Teile eines Handshakes.
class ClientHandshake {
  const ClientHandshake({
    required this.keyPair,
    required this.publicKey,
    required this.nonce,
  });

  final SimpleKeyPair keyPair;
  final Uint8List publicKey;
  final Uint8List nonce;

  static Future<ClientHandshake> create({Random? random}) async {
    final keyPair = await DartX25519().newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    return ClientHandshake(
      keyPair: keyPair,
      publicKey: Uint8List.fromList(publicKey.bytes),
      nonce: _randomBytes(nonceLength, random ?? Random.secure()),
    );
  }
}

Uint8List _randomBytes(int length, Random random) {
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}

/// Leitet aus dem X25519-Austausch die beiden Richtungsschlüssel ab:
/// HKDF-SHA256, Salt = Client-Nonce ‖ Server-Nonce, 64 Byte = 32 ‖ 32.
Future<SessionKeys> deriveSessionKeys({
  required SimpleKeyPair keyPair,
  required List<int> serverPublicKey,
  required List<int> clientNonce,
  required List<int> serverNonce,
}) async {
  final shared = await DartX25519().sharedSecretKey(
    keyPair: keyPair,
    remotePublicKey: SimplePublicKey(serverPublicKey, type: KeyPairType.x25519),
  );
  final material =
      await DartHkdf(
        hmac: DartHmac.sha256(),
        outputLength: _keyLength * 2,
      ).deriveKey(
        secretKey: shared,
        nonce: [...clientNonce, ...serverNonce],
        info: utf8.encode(transportInfo),
      );
  final bytes = await material.extractBytes();
  return SessionKeys(
    clientToServer: SecretKey(bytes.sublist(0, _keyLength)),
    serverToClient: SecretKey(bytes.sublist(_keyLength)),
  );
}

List<int> additionalData(
  String channelId,
  TransportDirection direction,
  int counter,
) {
  final name = direction == TransportDirection.request ? 'req' : 'res';
  return utf8.encode('novooa/1|$channelId|$name|$counter');
}

/// AES-256-GCM; Umschlag = Base64(IV ‖ Chiffretext ‖ Tag).
Future<String> seal(
  SecretKey key,
  List<int> plaintext,
  List<int> aad, {
  Random? random,
}) async {
  final box = await DartAesGcm.with256bits().encrypt(
    plaintext,
    secretKey: key,
    nonce: _randomBytes(_ivLength, random ?? Random.secure()),
    aad: aad,
  );
  return base64.encode([...box.nonce, ...box.cipherText, ...box.mac.bytes]);
}

/// Wirft eine [SecretBoxAuthenticationError] oder [FormatException], wenn
/// Schlüssel, Zusatzdaten oder Inhalt nicht passen.
Future<List<int>> open(SecretKey key, String envelope, List<int> aad) async {
  final raw = base64.decode(envelope);
  if (raw.length < _ivLength + _tagLength) {
    throw const FormatException('Umschlag zu kurz.');
  }
  final box = SecretBox(
    raw.sublist(_ivLength, raw.length - _tagLength),
    nonce: raw.sublist(0, _ivLength),
    mac: Mac(raw.sublist(raw.length - _tagLength)),
  );
  return DartAesGcm.with256bits().decrypt(box, secretKey: key, aad: aad);
}
