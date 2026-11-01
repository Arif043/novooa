# Fähigkeiten von Sprachmodellen zur Laufzeit

> novooa prüft nicht vorab, ob ein Sprachmodell Werkzeuge, Bilder oder strukturierte Ausgabe kann, sondern versucht es und meldet eine Ablehnung des Anbieters als `capabilityMissing`.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Ein Katalog der Modellfähigkeiten müsste für jeden Anbieter gepflegt werden und
liegt oft falsch (Googles Modellliste etwa nennt keine Werkzeuge). Deshalb gilt:

- **Annehmen statt prüfen:** Prompt-Baustein, Teamarbeit und Agenten rufen das
  gewählte Modell ohne Vorab-Prüfung auf. Gespeicherte Fähigkeiten
  (`capabilities_json`) sind nur noch Information aus der Erkennung beim
  Einrichten.
- **Ablehnung übersetzen:** `missingCapabilityIn` erkennt typische Meldungen
  der Anbieter („does not support tools“, „Function calling is not enabled“,
  „image_url is not supported“, „response_format … not supported“, „does not
  support thinking“ …), auch in den Ursachen schon übersetzter Fehler.
  `translateGenkitError` macht daraus `ModelCapabilityMissingError` mit
  „Das gewählte Sprachmodell unterstützt Werkzeugaufrufe nicht. Wähle ein
  anderes Modell.“ (Code `capabilityMissing`).
- **Nicht wiederholen:** Eine fehlende Fähigkeit bleibt beim nächsten Versuch
  dieselbe; `isRetryableModelError` nimmt sie von den Wiederholungen aus.
- **Stilles Ignorieren erkennen:** Manche Modelle lehnen Werkzeuge nicht ab,
  sondern antworten selbst. Beauftragt der Orchestrator der Teamarbeit trotz
  Mitarbeitern niemanden, endet der Baustein mit `capabilityMissing`
  („Der Orchestrator hat keinen Mitarbeiter beauftragt …“).
- Ein verfehltes Ausgabeformat bleibt `outputSchemaViolated`
  ([Fehlerschichtung](./fehlerschichtung-modellaufruf.md)).

Ein ungeeignetes Modell fällt so erst beim ersten Lauf auf, nicht beim
Einrichten des Bausteins.

## Siehe auch

- [Sprachmodell-Anbieter](./sprachmodell-anbieter.md) — woher die gespeicherten Fähigkeiten kommen
- [Ausführung der Teamarbeit](./teamwork-ausfuehrung.md)
- [Fehlerschichtung beim Modellaufruf](./fehlerschichtung-modellaufruf.md)
