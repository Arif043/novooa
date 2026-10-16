import {taskBuilderAssistantPrimitives} from "../../../../domain/entities/task-builder-assistant-response.js";

/**
 * Produktwissen für die Anforderungsanalyse. Quelle: docs/notes/bausteinkatalog.md
 * § Primitives — bei neuen oder geänderten Bausteinen hier mitpflegen.
 */
const buildingBlocks: ReadonlyArray<readonly [primitive: string, description: string]> = [
  ["stringInput", "Texteingabe: gibt festen Text weiter."],
  ["prompt", "Prompt: LLM-Aufruf mit Vorlage und Variablen; Ausgabe Text, Entscheidung, strukturierte Felder oder Bild."],
  ["script", "Script: führt Python isoliert aus (5 s, 10 KB Ausgabe); Eingabe über inputTemplate."],
  ["conditionalFlow", "Bedingter Ablauf: verzweigt anhand einer Entscheidung oder boolescher Bedingungen."],
  ["iterativeRefinement", "Iterative Verfeinerung: bewertet und verbessert einen Entwurf."],
  ["writeFile", "Datei schreiben: speichert einen Wert als Datei (Tabellen als .xlsx)."],
  ["readFile", "Datei lesen: liest eine konkrete Datei-Version."],
  ["readEmail", "E-Mail lesen: Absender, Betreff, Inhalt eines E-Mail-Ereignisses."],
  ["readChannelEvent", "Nachricht lesen: E-Mail-, WhatsApp- oder SMS-Ereignis lesen."],
  ["sendChannelMessage", "Nachricht senden: E-Mail, WhatsApp oder SMS senden."],
  ["notificationSend", "Push-Benachrichtigung an alle Team-Mitglieder senden."],
  ["humanApproval", "Freigabe: hält den Lauf bis zur menschlichen Entscheidung an."],
  ["dialogInput", "Formulareingabe: fragt typisierte Eingaben per Formular ab."],
  ["mediaInput", "Bild anfordern: fordert ein Bild oder einen Dokumentenscan an."],
  ["modelInference", "Modell ausführen: ONNX-Modell aus dem Modellkatalog (z. B. Bild-/Textklassifikation, OCR)."],
  ["textToSpeech", "Text vorlesen über ein verbundenes Sprachmodell."],
  ["speechToText", "Audio transkribieren über ein verbundenes Sprachmodell."],
  ["forEach", "Für jedes Element: führt einen eingebetteten Plan für jedes Element eines JSON-Arrays aus."],
  ["documentLookup", "Datensatz suchen (nur lokale Runtime)."],
  ["saveDocument", "Datensatz speichern oder aktualisieren (nur lokale Runtime)."],
  ["tableFromCollection", "Sammlung als Tabelle lesen (nur lokale Runtime)."],
  ["readWebhook", "Webhook-Ereignis lesen, das die Aufgabe gestartet hat (nur lokale Runtime)."],
  ["shopware", "Shopware-Aktion: Bestellungen, Produkte, Kunden (nur lokale Runtime, Verbindung nötig)."],
  ["httpRequest", "HTTP-Anfrage an eine externe API, optional über eine gespeicherte Verbindung (nur lokale Runtime)."],
];

function buildingBlockLines(): string {
  const addable = new Set<string>(taskBuilderAssistantPrimitives);
  return buildingBlocks
    .map(([primitive, description]) => `- ${primitive}${addable.has(primitive) ? " [anlegbar]" : ""}: ${description}`)
    .join("\n");
}

export const novooaProductKnowledge = `Produktwissen novooa:
- Eine Aufgabe ist ein Workflow aus Bausteinen und Kanten. Sie startet manuell,
  über einen Zeitplan (zeitbasiert), über ein Ereignis (E-Mail, WhatsApp, SMS,
  Shopware) oder über einen Webhook.
- Bausteine liefern typisierte Workflow-Ausgabewerte; Script-Bausteine können
  zusätzlich Variablen setzen. Referenzen per Template, z. B. {{rechnung.summe}}.
- Mitarbeiter sind Subagents (System-Prompt + Fähigkeiten) für Prompt-Bausteine.
- Wissensbasis, Dateien und Daten (Sammlungen) stehen Bausteinen zur Verfügung.

Bausteine ([anlegbar] = der Agent kann ihn heute direkt vorschlagen):
${buildingBlockLines()}`;
