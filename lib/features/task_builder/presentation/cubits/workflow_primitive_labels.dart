import '../../domain/entities/workflow_node.dart';

extension WorkflowPrimitiveLabels on WorkflowPrimitive {
  String get label {
    return switch (this) {
      WorkflowPrimitive.stringInput => 'Texteingabe',
      WorkflowPrimitive.script => 'Script',
      WorkflowPrimitive.prompt => 'Prompt',
      WorkflowPrimitive.conditional => 'Bedingter Ablauf',
      WorkflowPrimitive.iterativeRefinement => 'Iterative Verfeinerung',
      WorkflowPrimitive.writeFile => 'Datei schreiben',
      WorkflowPrimitive.readFile => 'Datei lesen',
      WorkflowPrimitive.readEmail => 'E-Mail lesen',
      WorkflowPrimitive.readChannelEvent => 'Nachricht lesen',
      WorkflowPrimitive.sendChannelMessage => 'Nachricht senden',
      WorkflowPrimitive.notificationSend => 'Push-Benachrichtigung senden',
      WorkflowPrimitive.toolCall => 'Werkzeug-Aufruf',
      WorkflowPrimitive.humanApproval => 'Freigabe',
      WorkflowPrimitive.dialogInput => 'Formulareingabe',
      WorkflowPrimitive.mediaInput => 'Bild anfordern',
      WorkflowPrimitive.modelInference => 'Modell ausführen',
      WorkflowPrimitive.textToSpeech => 'Text vorlesen',
      WorkflowPrimitive.speechToText => 'Audio transkribieren',
      WorkflowPrimitive.forEach => 'Für jedes Element',
      WorkflowPrimitive.documentLookup => 'Datensatz suchen',
      WorkflowPrimitive.saveDocument => 'Datensatz speichern',
      WorkflowPrimitive.tableFromCollection => 'Sammlung als Tabelle',
      WorkflowPrimitive.validation => 'Validierung',
      WorkflowPrimitive.plugin => 'Plugin-Baustein',
    };
  }

  String get description {
    return switch (this) {
      WorkflowPrimitive.stringInput =>
        'Gibt einen festen Text als Ausgabe weiter.',
      WorkflowPrimitive.script =>
        'Führt Python-Code mit der vorherigen Ausgabe als input aus.',
      WorkflowPrimitive.prompt => 'Formt Eingaben in einen Modellauftrag.',
      WorkflowPrimitive.conditional =>
        'Verzweigt den Ablauf anhand von Regeln.',
      WorkflowPrimitive.iterativeRefinement =>
        'Verbessert ein Ergebnis über mehrere Runden.',
      WorkflowPrimitive.writeFile =>
        'Schreibt die vorherige Ausgabe als Datei.',
      WorkflowPrimitive.readFile => 'Liest eine Datei als Text.',
      WorkflowPrimitive.readEmail =>
        'Liest Absender, Betreff, Nachricht und Ankunftszeit aus einem E-Mail-Trigger.',
      WorkflowPrimitive.readChannelEvent =>
        'Liest ein eingehendes E-Mail-, WhatsApp- oder SMS-Event.',
      WorkflowPrimitive.sendChannelMessage =>
        'Sendet eine Nachricht über einen verbundenen Kanal.',
      WorkflowPrimitive.notificationSend =>
        'Sendet einen Text als Push-Benachrichtigung an alle Team-Mitglieder.',
      WorkflowPrimitive.toolCall =>
        'Bindet externe Aktionen oder Datenquellen ein.',
      WorkflowPrimitive.humanApproval => 'Wartet auf menschliche Freigabe.',
      WorkflowPrimitive.dialogInput =>
        'Pausiert die Aufgabe, bis ein Formular ausgefüllt wurde.',
      WorkflowPrimitive.mediaInput =>
        'Pausiert die Aufgabe, bis ein Bild aufgenommen oder ausgewählt wurde.',
      WorkflowPrimitive.modelInference =>
        'Bereitet ein Bild nach Modellvertrag vor und führt ein Modell aus.',
      WorkflowPrimitive.textToSpeech => 'Wandelt Text in eine Audiodatei um.',
      WorkflowPrimitive.speechToText => 'Wandelt eine Audiodatei in Text um.',
      WorkflowPrimitive.forEach =>
        'Führt einen Unterplan für jedes Element eines JSON-Arrays aus.',
      WorkflowPrimitive.documentLookup =>
        'Findet einen Datensatz über sichtbare Felder und Bedingungen.',
      WorkflowPrimitive.saveDocument =>
        'Legt einen Datensatz an oder aktualisiert seine Felder.',
      WorkflowPrimitive.tableFromCollection =>
        'Liest eine Datensammlung vollständig ein und gibt sie als Tabellen-Wert weiter.',
      WorkflowPrimitive.validation =>
        'Prüft Ergebnis, Schema oder Qualitätskriterien.',
      WorkflowPrimitive.plugin => 'Führt einen Baustein eines Plugins aus.',
    };
  }
}
