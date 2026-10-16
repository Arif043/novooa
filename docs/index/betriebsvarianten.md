# Betriebsvarianten

> Native Apps und Web-App sollen jeweils Cloud und Standalone bedienen; nativ wählt man die Variante zur Laufzeit, im Web entscheidet die Herkunft, und die Oberfläche fragt nach Fähigkeiten statt nach der Variante.

- [Betriebsvarianten-Matrix](../notes/betriebsvarianten-matrix.md)
- [Variantenwahl zur Laufzeit](../notes/variantenwahl-zur-laufzeit.md)
- [Web-Herkunftsregel](../notes/web-herkunftsregel.md)
- [Die Runtime liefert die Web-App aus](../notes/runtime-liefert-web-app.md)
- [Mixed Content im LAN](../notes/mixed-content-im-lan.md)
- [Fähigkeiten je Variante (`WorkspaceCapabilities`)](../notes/workspace-capabilities.md)
- [Push unter Windows und Linux](../notes/push-windows-linux.md)
- [Zwei Identitätsmodelle](../notes/identitaetsmodelle.md)
- [`dart:io` im Web-Build ist kein Blocker](../notes/web-build-dart-io.md)

## Offene Punkte

- Tab- und Routenstruktur von `bool isStandalone` auf Fähigkeiten umstellen.
- Paritätslücken schließen (Profile/Teams in Standalone; Daten, Skills,
  Mitarbeiter, Verbindungen, Webhooks in der Cloud).
- Token-Ablage im Browser entscheiden und dokumentieren.
- Widget-Test: Standalone-Startflow im Web lädt ohne Adresseingabe.
- `Origin`-Prüfung beim WebSocket-Upgrade für Web-Clients.
- Web-App aus dem Runtime-Image oder aus einem gemounteten Volume ausliefern?
- PWA-Politur für Windows/Linux.

## Verwandt

- [Lokale Runtime](./lokale-runtime.md)
- [Architektur](./architektur.md)
