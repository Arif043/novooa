# Sicherheit der HTTP-Anfrage

> Zugangsdaten gehen nur an die Origin der Verbindung; interne Ziele sind bewusst nicht gesperrt, deshalb ist das Bearbeiten von Aufgaben so sensibel wie ein Netzzugang.

Gehört zu: [Verbindungen](../index/verbindungen.md)

- **Nur zur eigenen Origin:** Eine fremde Adresse im Pfad-Feld wird abgelehnt,
  eine Weiterleitung zu einem anderen Host nicht verfolgt. Die Anmeldung der
  Verbindung überschreibt gleichnamige Header des Bausteins.
- **Aktivitätslog** (`redactedConfig` in `structured-log-format-utils.ts`):
  Header-Werte und Body nie (`•••`); Query- und URL-Parameter nur, wenn ihr
  Name nicht nach Zugangsdaten klingt (`key`, `token`, `secret`, `passw…`,
  `auth…`, `signature`). Geheimnisse aus Verbindungen stehen nie in der
  Config, nur die `connectionId`.
- **`http://` erlaubt** (interne Systeme); der Editor warnt vor
  unverschlüsselten Zugangsdaten.
- **Keine Sperre interner Ziele (bewusst):** `localhost`, Container im
  Docker-Netz und Metadaten-Endpunkte sind erreichbar, damit Systeme im selben
  Netz gehen. Eine Sperr- oder Freigabeliste wäre eine einzige Prüfung in
  `ConnectionHttpClient`.
- Selbst eingetippte Header (Token im Baustein) stehen im Klartext in der
  Aufgabe; für Zugangsdaten gehört eine Verbindung her.

## Siehe auch

- [Baustein „HTTP-Anfrage“](./http-anfrage-baustein.md)
- [Verbindung](./verbindung.md)
