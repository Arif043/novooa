/**
 * Öffentlicher Ed25519-Schlüssel, mit dem jede Runtime Lizenzen offline prüft. Er steht im Code statt
 * als Datei im Image, damit er im verschleierten Bündel liegt und sich nicht austauschen oder per
 * Mount überdecken lässt. Kein Geheimnis; der private Schlüssel lebt nur im Lizenz-Gateway.
 */
export const runtimeLicensePublicKeyPem = `-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAGCbckt24w98gCgyjS5gik2l/w4a49V0Gwx46pxvDA+I=
-----END PUBLIC KEY-----`;
