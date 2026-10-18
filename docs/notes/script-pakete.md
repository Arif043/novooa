# Script: Python-Pakete

> Ein Script-Baustein trägt seine PyPI-Pakete selbst; ein Klick auf „Pakete installieren“ baut die passende Umgebung, gleiche Listen teilen sich eine.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- **Nur lokale Runtime** (Fähigkeit `scriptPackages`). Der eingebettete
  Python-Pfad der Cloud kennt keine Imports; ein Baustein mit Paketen scheitert
  dort mit `scriptPackagesUnavailable` (`unsupported`).
- **Liste am Baustein:** `ScriptNodeConfig.packages`, gespeichert wie
  eingegeben (`pandas`, `pandas==2.2.3`, `requests[socks]>=2.31,<3`). Erlaubt
  sind nur Name, Extras und Versionsangabe (`PythonPackage`), keine URLs,
  Pfade oder Optionen. Die Liste reist bei Export und Import mit.
- **Erkennen:** `PythonImportScanner` liest die Imports, lässt die
  Standardbibliothek (`pythonStandardLibraryModules`, Python 3.12) weg und
  schlägt über `ImportPackageNames` den Paketnamen vor (`cv2` →
  `opencv-python-headless`, `PIL` → `Pillow`, `sklearn` → `scikit-learn`).
  Der Vorschlag wird erst mit „Übernehmen“ eingetragen.
- **Wiederverwenden:** Ist noch nichts eingetragen und deckt eine fertige
  Umgebung alle Imports ab, bietet das Panel sie an; übernommen wird ihre Liste.
- **Umgebungs-ID:** SHA-256 der normalisierten Liste (Namen nach PEP 503,
  Extras sortiert, Versionen ohne Leerzeichen, sortiert, ohne Doppelte).
  Dieselbe Regel gilt im Builder (`PythonPackage.normalizedList`) und in der
  Runtime (`normalizedScriptPackages`); gleiche Liste, gleiche Umgebung.
  Ohne Versionsangabe gilt, was beim Installieren aktuell war (`lock.txt`).
- **Installieren nur per Klick:** `POST /v1/script-packages` startet die
  Installation im [Paketdienst](./script-paketdienst.md); der Stand
  (`installing`, `ready` mit Größe, `failed` mit `notFound`, `noWheel`,
  `tooLarge` oder `failed`) kommt über `GET /v1/script-packages` und das
  Realtime-Thema `script-packages`. Ändert sich die Liste, gilt sie wieder als
  „nicht installiert“.
- **Lauf:** Der Executor schickt die ID als `environment` mit; der
  Script-Container setzt `envs/<id>/site` an den Anfang des Suchpfads. Fehlt
  die Umgebung, scheitert der Baustein mit `scriptPackagesUnavailable`
  (`notInstalled`) — installiert wird im Lauf nie.
- **Aufräumen:** Nach jeder Installation und täglich entfernt die Runtime
  Umgebungen, die kein Script-Baustein irgendeiner Aufgabe mehr verwendet
  (auch in Zweigen und Schleifen). Der Paket-Cache bleibt, eine erneute
  Installation geht schnell.

## Siehe auch

- [Script-Paketdienst](./script-paketdienst.md)
- [Script-Executor](./script-executor.md)
- [Script-Dienst: Abschottung](./script-dienst-abschottung.md)
