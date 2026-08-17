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
      WorkflowPrimitive.toolCall => 'Werkzeug-Aufruf',
      WorkflowPrimitive.humanApproval => 'Freigabe',
      WorkflowPrimitive.dialogInput => 'Formulareingabe',
      WorkflowPrimitive.mediaInput => 'Bild anfordern',
      WorkflowPrimitive.validation => 'Validierung',
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
      WorkflowPrimitive.toolCall =>
        'Bindet externe Aktionen oder Datenquellen ein.',
      WorkflowPrimitive.humanApproval => 'Wartet auf menschliche Freigabe.',
      WorkflowPrimitive.dialogInput =>
        'Pausiert die Aufgabe, bis ein Formular ausgefüllt wurde.',
      WorkflowPrimitive.mediaInput =>
        'Pausiert die Aufgabe, bis ein Bild aufgenommen oder ausgewählt wurde.',
      WorkflowPrimitive.validation =>
        'Prüft Ergebnis, Schema oder Qualitätskriterien.',
    };
  }
}
