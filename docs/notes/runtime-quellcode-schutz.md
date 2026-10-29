# Quellcode-Schutz der ausgelieferten Images

> Die Docker-Builds bündeln und verschleiern den eigenen Node-Code und kompilieren die Python-Pakete nativ; das erhöht den Aufwand für Reverse Engineering.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Code auf einem Kundenrechner bleibt analysierbar. Diese Maßnahmen ergänzen
die Lizenzprüfung; sie ersetzen weder Signaturen noch Zugriffskontrollen.

## Node-Runtime

`functions/scripts/harden-node.mjs` bündelt mit esbuild den Runtime-Start,
`local-runtime-keyring-init-cli.js` und `local-runtime-key-rotation-cli.js`.
Die ursprünglichen Pfade unter `lib/shared/local/` bleiben erhalten, damit
Migrationen und der öffentliche Lizenzschlüssel weiterhin gefunden werden.
`node_modules` und `drizzle/` bleiben externe Laufzeit-Abhängigkeiten. Der
öffentliche Lizenzschlüssel ist eine Konstante im Code
(`runtime-license-public-key.ts`) und liegt damit verschleiert im Bündel; eine
Schlüsseldatei, die sich austauschen oder per Mount überdecken ließe, gibt es
nicht. Eine Lizenz ohne Prüfung (früher `NOVOOA_LOCAL_DEVELOPMENT`) gibt es
nicht mehr, auch nicht für Entwicklung oder Tests.
Das entfernte Node-ML-Gateway wird nicht wieder eingeführt.

`javascript-obfuscator` verschleiert die Bündel mit Kontrollflussumbau,
Täuschungscode und RC4-kodierten String-Arrays. Die Optionen stehen in
`functions/scripts/node-protection-options.mjs`. Konsolenausgaben bleiben an;
`selfDefending` und `debugProtection` sind für den Serverbetrieb aus.
RC4 ist hier eine Verschleierung, kein Schutz geheimer Daten.

Nur `dist-protected/` wird in die finale Image-Schicht als `lib/` kopiert.
Entwicklung und Firebase-Builds verwenden weiterhin das unveränderte `lib/`.

## Python-Dienste

`local-runtime/python/harden_python.py` verarbeitet ausschließlich eine Kopie
der Pakete in einer Docker-Build-Stage. Nuitka kompiliert die Module einzeln
zu `.so`-Erweiterungen und entfernt die Quellen und Compiler-Artefakte.
Build- und Laufzeit-Stage verwenden dieselbe Python-Basis.

| Image | Kompilierte Pakete | Start |
| --- | --- | --- |
| ML-Dienst | `novooa_ml`, `novooa_bundles` | `python -m novooa_ml` |
| Script-Dienst | `novooa_script` | `python -m novooa_script` |
| Script-Paketdienst | `novooa_packages` | `python -m novooa_packages` |

Lesbar bleiben Paketmarker und kleine `__main__.py`-Launcher, weil Python
native Erweiterungen nicht direkt mit `-m` ausführen kann. Die Mandanten-CLI
bleibt über `python -m novooa_ml.tenants list` erreichbar; ihre Implementierung
liegt kompiliert in `tenants/cli`. Die automatische Erkennung der
ML-Transformationen verwendet weiterhin die importierbaren Paketmodule.

Der isolierte Script-Unterprozess startet `child.pyc` statt `child.py`.
Bytecode ist leichter rekonstruierbar als die nativen Erweiterungen. Der
Entwicklungsbetrieb nutzt weiterhin die Python-Quellen.

## Bauen und ausliefern

Die Härtung läuft automatisch in den vier Runtime-Dockerfiles. Ein lokaler
Node-Prüflauf ist `npm --prefix functions run build`, gefolgt von
`npm --prefix functions run harden:node`.

Der Runtime-Smoke-Test läuft gegen das finale Image (Platzhalter `IMAGE`):

```bash
docker run --rm --user 0 \
  --mount type=bind,src="$PWD/functions/scripts/protected-runtime.test.mjs",dst=/check.mjs,readonly \
  IMAGE node --test /check.mjs
```

Er erzeugt ausschließlich temporäre Testdaten; der Runtime-Prozess darin
läuft als `node` (UID 1000).

- Images isoliert bauen und vor Freigabe Start, Schlüsselinitialisierung und
  -rotation, Script-Ausgaben sowie ML-Inferenz und Transformationen prüfen.
- Web mit `flutter build web --release --no-source-maps` bauen.
- Flutter-Symboltabellen für die Fehlersuche aufbewahren und nicht ausliefern.
- `.dockerignore` schließt `.novooa/`, Source-Maps, Debug-Symbole und lokale
  Python-Caches aus. Abhängigkeiten können eigene Quellen enthalten.
- Images über eine private Registry oder kontrollierte Archive verteilen.

## Siehe auch

- [Images, Updates und Neustarts](./runtime-images-und-updates.md)
- [Deployment-CLI](./deployment-cli.md)
- [Lizenz-Token und Aktivierung](./lizenz-aktivierung.md)
