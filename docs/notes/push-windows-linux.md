# Push unter Windows und Linux

> Weil FCM keine Windows/Linux-SDKs hat, ist dort die installierte PWA mit Web Push der vorgesehene Weg, nicht eine native App mit eigenem WNS-Backend.

Gehört zu: [Betriebsvarianten](../index/betriebsvarianten.md)

- Push im Hintergrund, auch bei geschlossenem Client, ist für Freigaben
  zentral.
- Web-Push ist angebunden (`web/firebase-messaging-sw.js`,
  `web/manifest.json`) und läuft über denselben `localRuntimePushRelay` wie
  natives Push.
- Offen: PWA-Politur — `orientation: portrait-primary` im Manifest ist ein
  Mobile-Rest und sollte für Desktop entfallen; ein sichtbarer
  Install-Hinweis fehlt.
- Android, iOS und macOS bleiben bei nativem FCM/APNs. Native
  Windows/Linux-Clients sind ohne Push nutzbar, aber nicht die Zielplattform.

## Siehe auch

- [Fähigkeiten je Variante](./workspace-capabilities.md)
- [Push-Benachrichtigungen in Standalone](./push-standalone.md)
