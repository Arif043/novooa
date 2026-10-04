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
mit `javascript-obfuscator` (Control-Flow-Flattening, String-Array mit
Base64-Encoding, Dead-Code, umbenannte Bezeichner). Nur diese Bündel landen im
Laufzeit-Image; der lesbare `lib/`-Baum bleibt im Build-Stage.

Server-sichere Einstellungen: `selfDefending`/`debugProtection` aus,
Konsolen-Logging bleibt erhalten, Base64 statt RC4 (gleicher Schutz gegen
simples Mitlesen, geringere Laufzeitkosten).

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
