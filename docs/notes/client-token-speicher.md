# Sicherer Token-Speicher im Client

> Das Session-Token liegt im plattformeigenen Credential-Speicher (`flutter_secure_storage`); auf macOS braucht das ein Development-Signing pro Rechner.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Nicht in `SharedPreferences`.

## macOS

`keychain-access-groups` ist als Entitlement gesetzt
(`macos/Runner/{Debug,Release}.entitlements`). Ohne scheitert jeder
Schreibzugriff mit `PlatformException(-34018, A required entitlement isn't
present.)` — sichtbar erst bei der Anmeldung.

Das Entitlement verlangt eine Development-Signing-Identität; sonst bricht der
Build mit `"Runner" has entitlements that require signing with a development
certificate` ab. Ad-hoc-Signierung genügt nicht. Einmalig, ein kostenloses
Personal Team reicht:

1. Xcode → Settings → Accounts → Apple-ID hinzufügen.
2. `macos/Runner.xcworkspace` → Target **Runner** → Signing & Capabilities →
   „Automatically manage signing“ und Team wählen (setzt `DEVELOPMENT_TEAM`).

Fehlt das Profil (`No profiles for 'de.novooa.desktop' were found`), einmal
mit Xcode erzeugen, denn Flutter übergibt kein `-allowProvisioningUpdates`:

```bash
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -configuration Debug -derivedDataPath build/macos \
  -destination 'platform=macOS' -allowProvisioningUpdates build
flutter run -d macos
```

Das gilt **pro Entwicklungsrechner**: Nur die `.entitlements` sind
versioniert, das Xcode-Projekt nicht (`.gitignore`: `macos/*`). Entitlements
nicht entfernen, Signierung nicht abschalten.

## Windows

`flutter_secure_storage` braucht die C++-ATL-Bibliotheken der Visual Studio
Build Tools.

## Siehe auch

- [Runtime-Sitzungen](./runtime-sitzungen.md)
- [Push-Benachrichtigungen in Standalone](./push-standalone.md) — Build ohne Apple-Zertifikat
