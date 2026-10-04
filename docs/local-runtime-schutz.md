# Schutz der Standalone-Images vor Code-Diebstahl

> Gilt für den selbst gehosteten Standalone-Betrieb: Dort laufen die
> Docker-Images auf dem Rechner der Kundschaft. Diese Seite beschreibt, wie der
> eigene Code gegen Extraktion und Reverse-Engineering gehärtet wird — und wo
> die Grenzen liegen.

## Grundannahme (ehrlich)

Code, der auf einem fremden Rechner läuft, ist grundsätzlich analysierbar. Jede
Verschleierung erhöht die **Kosten** des Reverse-Engineering, macht es aber
nicht unmöglich. Ziel ist, den Aufwand über den Nutzen zu heben — nicht
„unknackbar".

Deshalb gilt die Arbeitsteilung:

- **Gegen „ohne Lizenz betreiben"** schützt das **Lizenzsystem** (signierte
  Lizenz + Public-Key-Prüfung + Gateway, siehe `docker-compose.local.yaml`:
  `LOCAL_RUNTIME_LICENSE_*`). Das ist der eigentliche Diebstahlschutz.
- **Gegen „Quellcode extrahieren und nachbauen"** schützt die hier
  beschriebene Härtung. Sie ersetzt das Lizenzsystem nicht, sie ergänzt es.

Bewusst **nicht** eingesetzt (unverhältnismäßig oder wirkungslos für
containerisierte Server-Dienste): Hardware-Dongles, VMProtect, Anti-Debugger-
und Anti-DevTools-Tricks (`selfDefending`, `debugProtection` — zielen auf
Browser-JS und erzeugen serverseitig nur Absturzrisiko).

## Was pro Image passiert

| Image | Inhalt | Härtung |
| --- | --- | --- |
| Runtime (`Dockerfile.local-runtime`) | Node-Backend | esbuild-Bündel je Entrypoint + javascript-obfuscator; nur die Bündel im Image |
| ML-Gateway (`Dockerfile.model-inference`) | Node + Python-Worker | Node wie oben; Python-Pakete als native `.so`; Worker als Launcher |
| ML-Sidecar (`Dockerfile.model-inference-sidecar`) | Python | `novooa_ml` als native `.so`, Launcher für `-m` |
| Script-Runner (`Dockerfile.script-runner`) | Python | `novooa_script` als native `.so`; `child.py` als sourceless `.pyc` |
| Web-Build | Flutter Web | `flutter build web --release --no-source-maps` (dart2js minifiziert, keine `.map`) |

### Node (Runtime + ML-Gateway)

`functions/scripts/harden-node.mjs` bündelt jeden Container-Entrypoint mit
esbuild zu **einer** Datei (eigener Code inline, `node_modules` bleiben extern —
die Abhängigkeiten sind nicht das Schützenswerte) und verschleiert sie danach
mit `javascript-obfuscator`. Nur diese Bündel landen im Laufzeit-Image; der
lesbare `lib/`-Baum bleibt im Build-Stage.

Aktive Optionen:

- `controlFlowFlattening` (Threshold 0.75) — Kontrollfluss zerlegt
- `deadCodeInjection` (Threshold 0.2) — toter Täuschungscode
- `splitStrings` / `splitStringsChunkLength: 8` — Strings zerschnitten
- `stringArray` mit `stringArrayEncoding: ['rc4']` — Strings (inkl.
  eingebettetem Public Key) verschlüsselt im String-Array
- `transformObjectKeys`, `numbersToExpressions`, umbenannte Bezeichner
- `selfDefending` — bricht bei Beautify-Versuchen
- `debugProtection` — erschwert das Anhängen eines Debuggers (ohne
  Dauer-Intervall, damit der Event-Loop nicht belastet wird)

Konsolen-Logging bleibt an (`disableConsoleOutput: false`). Hinweis zu rc4 und
dem Public Key: Ein Public Key ist nicht geheim — die Verschlüsselung
erschwert nur das Mitlesen im Code und ersetzt nicht die Signaturprüfung.
`selfDefending`/`debugProtection` zielen auf manuelle Analyse; auf einem
Server, den die Kundschaft kontrolliert, ist ihr Nutzen begrenzt, der
Laufzeitpfad bleibt aber unberührt (im Build per Lasttest geprüft).

#### Single Executable Application (SEA) — bewusst nicht eingesetzt

Node.js SEA (ein in die `node`-Binary eingebetteter Blob) passt hier nicht:

- Die Dienste nutzen **native Module** (z. B. `@libsql/client` für lokales
  SQLite). Die lassen sich nicht in den Blob bündeln; `node_modules` müsste
  ohnehin auf der Platte liegen, und die `require`-Auflösung externer Pakete
  unter SEA ist fragil.
- Der Gewinn ist gering: Der Code liegt bereits als **ein obfuskiertes Bündel**
  vor, und zwar **innerhalb eines nicht-öffentlichen Images**. SEA würde daraus
  nur eine Binary im selben Image machen — ohne das Bedrohungsmodell
  (Image-Diebstahl) zu ändern.
- Das Risiko (gebrochene DB-/Genkit-Pfade) überwiegt, und es lässt sich nicht
  ohne vollständigen Integrationstest der Datenbank-/Modell-Pfade absichern.

SEA ist sinnvoll für eine **einzeln verteilte CLI-Binary**, nicht für einen
containerisierten Server-Dienst. Falls künftig ein Node-Tool als eigenständige
`.exe`/Binary an Kundschaft ausgeliefert wird, ist SEA dort der richtige Ort.

### Python (Script-Runner, ML-Sidecar, ML-Gateway-Worker)

`local-runtime/python/harden_python.py` kompiliert jedes Paketmodul mit
**Nuitka** (`--module`) zu einer nativen `.so` und entfernt den Quelltext. Die
Abhängigkeiten (numpy, onnxruntime, …) bleiben normale pip-Pakete.

Übrig bleiben nur IP-freie Launcher, weil `python -m modul` bzw.
`python datei.py` ein Code-Objekt braucht, das eine `.so` nicht liefert
(„No code object available"), ein Import einer `.so` aber problemlos geht:

- `<paket>/__main__.py` — ruft die kompilierte `server.so` /
  `inference_server.so` auf (`python -m novooa_script` bzw. `-m novooa_ml`).
- Pro von Node per Pfad gestartetem Worker ein Launcher, der die kompilierte
  Implementierung unter `_native/` aufruft. Die Launcher setzen `sys.path`
  selbst, weil Node die Worker mit `python -I` (isoliert) startet und `-I`
  weder `PYTHONPATH` noch das Skriptverzeichnis berücksichtigt.
- `child.py` (Script-Sandbox) läuft als eigener, isolierter Prozess per Pfad
  und wird deshalb als sourceless `.pyc` geschützt statt als `.so`.

## Bauen

Die Härtung läuft automatisch im Docker-Build (je eine Härtungs-Stage pro
Image). Lokal zum Prüfen:

```bash
# Node
cd functions && npm run build && npm run harden:node   # -> functions/dist-protected

# Python (Beispiel Script-Runner)
pip install nuitka
python local-runtime/python/harden_python.py <kopie-des-python-baums>
```

Die Härtungs- und Runtime-Stage nutzen bewusst dieselbe Python-Version, damit
die `.so` ABI-kompatibel sind.

## Vor dem Ausliefern prüfen

- **ML-Images einmal real bauen und smoke-testen.** Script-Runner und
  Node-Bündel sind end-to-end verifiziert; die ML-Dienste brauchen zur Laufzeit
  numpy/onnxruntime, daher muss der erste Build von `novooa-ml` und dem Gateway
  einmal in der eigenen CI/Docker-Umgebung durchlaufen (Start + eine echte
  Inferenz).
- **Keine Debug-Hilfen mitliefern.** Source-Maps (`*.map`), Flutter-Symbole
  (`build/symbols`) und `.py`-Quellen gehören nicht ins Image. Die
  `.dockerignore` hält sie aus dem Build-Kontext.
- **Images nicht öffentlich pushen.** Über eine private Registry oder
  `docker save` mit Zugriffskontrolle verteilen.
- **Secrets getrennt halten.** `.novooa/` (Master-Key, Lizenz-Keys) ist in der
  `.dockerignore` und darf nie in ein Image-Layer geraten.
