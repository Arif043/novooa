# Script: Paketprobe nach der Installation

> Installiert heißt nur entpackt: Erst ein Import im Script-Container unter den Grenzen eines Laufs zeigt, ob die Pakete dort laufen; nicht ladbare Umgebungen werden wieder entfernt.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- **Warum:** Der [Paketdienst](./script-paketdienst.md) entpackt nur Wheels und
  führt keinen Code aus. Manche Pakete brauchen aber Bibliotheken oder
  Programme des Betriebssystems, die das schlanke Script-Image nicht hat
  (`weasyprint` → pango/cairo, `opencv-python` → libGL, `python-magic` →
  libmagic, `pytesseract` → `tesseract`). Andere laden so lange, dass ein Lauf
  am Zeitlimit oder am Speicher des Containers scheitert.
- **Ablauf:** Nach erfolgreicher Installation ruft `ScriptPackageJobs` den Port
  `ScriptPackageProbe` (`HttpScriptPackageProbe`, `POST /probe` am
  [Script-Dienst](./script-dienst-schnittstelle.md)). Bis die Probe antwortet,
  bleibt der Stand `installing`.
- **Was geladen wird:** die obersten Module der **eingetragenen** Pakete, aus
  dem `RECORD` ihrer `.dist-info` (`package_probe.modules_of`); Abhängigkeiten
  laden sie selbst. Private Module (`_yaml`), `.libs`-Ordner und Skripte unter
  `bin/` zählen nicht.
- **Grenzen:** Die Probe ist ein gewöhnlicher Lauf (`execute`) mit derselben
  Umgebung, demselben Zeitlimit, Speicher und denselben Plätzen wie ein Script.
- **Ergebnis:** `{loadable: true}` oder `{loadable: false, module, error}`. Die
  Runtime löscht die Umgebung dann wieder und meldet `failed` mit Grund
  `notLoadable` und Detail `modul: Fehler` bzw. „Der Import dauerte länger als
  10 Sekunden.“ Antwortet der Script-Dienst nicht, gilt die Umgebung als nicht
  geprüft und wird ebenso entfernt (`failed`).
- **Nicht abgedeckt:** Fehler, die erst beim Aufruf einer Funktion auftreten
  (externe Programme, Netzzugriffe — der Script-Container hat kein Netz), und
  Speicher, den erst die Daten eines Scripts brauchen.

## Siehe auch

- [Script: Python-Pakete](./script-pakete.md)
- [Script-Dienst: Ausführung und Grenzen](./script-dienst-ausfuehrung.md)
