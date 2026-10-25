# Plattformen

Dieselbe Codebasis läuft im Web, auf dem Desktop und auf dem Handy. Was je
Plattform einzustellen ist, steht hier. Grundsatz für alle: `http` nur im
vertrauenswürdigen LAN; außerhalb davon `https` über einen Reverse Proxy der
Runtime (Domain mit Zertifikat).

## Inhalt

- [Web](#web)
- [macOS](#macos)
- [Windows und Linux](#windows-und-linux)
- [Android](#android)
- [iOS](#ios)

## Web

Die Runtime liefert nur die offizielle Web-App aus. Ein Dashboard läuft auf
einer eigenen Herkunft (Schema + Host + Port) und braucht deshalb:

1. **Feste Adresse der Runtime** beim Build, denn im Web gibt es kein
   Adressfeld:

   ```bash
   flutter build web --dart-define=WORKSPACE_API_URL=https://novooa.kunde.de
   ```

2. **CORS-Freigabe in der Runtime** für genau diese Herkunft, kommagetrennt,
   nie `*`:

   Die Compose-Datei der Runtime reicht die Variable durch; sie steht in der
   `.env` neben `docker-compose.local.yaml`:

   ```bash
   LOCAL_RUNTIME_ALLOWED_ORIGINS=https://dashboard.kunde.de
   ```

   Ohne Freigabe antwortet die Runtime mit `403 {error: "Herkunft nicht erlaubt."}`.
   Nach der Änderung den Runtime-Container neu starten.

3. **Kein Mixed Content:** Eine über `https` geladene Seite darf keine
   `http`-Runtime ansprechen. Entweder beide `https` oder beide `http` (nur LAN).

4. **Token nur im Tab:** Über `http` (kein sicherer Kontext) speichert das
   Paket das Token in `sessionStorage`; nach dem Schließen des Tabs ist eine
   neue Anmeldung nötig. Über `https` bleibt es gespeichert.

Entwicklung:

```bash
# Runtime: LOCAL_RUNTIME_ALLOWED_ORIGINS=http://localhost:5060
flutter run -d chrome --web-port=5060 --dart-define=WORKSPACE_API_URL=http://127.0.0.1:8090
```

Ausliefern: Der Ordner `build/web` ist statisch und läuft hinter jedem
Webserver. Liegt das Dashboard hinter demselben Reverse Proxy wie die Runtime
unter einer eigenen Subdomain, bleibt es eine fremde Herkunft (CORS nötig).

## macOS

In `macos/Runner/DebugProfile.entitlements` und `Release.entitlements`:

```xml
<key>com.apple.security.app-sandbox</key><true/>
<key>com.apple.security.network.client</key><true/>
<key>keychain-access-groups</key><array/>
```

- `network.client`: ausgehende Verbindungen zur Runtime.
- `keychain-access-groups`: Token im Schlüsselbund. Ohne scheitert das
  Speichern nach der Anmeldung mit `-34018`. Verlangt eine
  Development-Signing-Identität (Xcode → Signing & Capabilities → Team);
  Ad-hoc-Signierung reicht nicht.

## Windows und Linux

- Windows: `flutter_secure_storage` braucht die C++-ATL-Bibliotheken der
  Visual Studio Build Tools.
- Linux: `libsecret-1-dev` zum Bauen und ein laufender Secret Service
  (z. B. GNOME Keyring) auf dem Zielsystem.

## Android

- `android/app/src/main/AndroidManifest.xml`:
  `<uses-permission android:name="android.permission.INTERNET"/>` im
  `manifest`-Element (fehlt im Release-Manifest sonst).
- `http` im LAN: Android blockiert Klartext ab API 28. Nur wenn die Runtime
  wirklich über `http` erreicht wird, im `application`-Element
  `android:usesCleartextTraffic="true"` setzen; mit `https` weglassen.
- `flutter_secure_storage` braucht `minSdkVersion` 23 oder höher.

## iOS

In `ios/Runner/Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Verbindet sich mit novooa in deinem Netzwerk.</string>
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsLocalNetworking</key><true/>
</dict>
```

- Ohne `NSLocalNetworkUsageDescription` kann die App ab iOS 14 keine Geräte
  im LAN erreichen.
- `NSAllowsLocalNetworking` erlaubt `http` zu lokalen Adressen; eine
  öffentliche Runtime nur über `https`.
- Den Text an die Sprache des Kunden anpassen (`InfoPlist.strings` für
  weitere Sprachen).
