import '../../domain/entities/workflow_node.dart';

extension WorkflowPrimitiveLabels on WorkflowPrimitive {
  String get label {
    return switch (this) {
      WorkflowPrimitive.stringInput => 'Texteingabe',
      WorkflowPrimitive.script => 'Script',
      WorkflowPrimitive.prompt => 'Prompt',
      WorkflowPrimitive.conditional => 'Bedingter Ablauf',
      WorkflowPrimitive.iterativeRefinement => 'Iterative Verfeinerung',
      WorkflowPrimitive.toolCall => 'Werkzeug-Aufruf',
      WorkflowPrimitive.humanApproval => 'Freigabe',
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
      WorkflowPrimitive.toolCall =>
        'Bindet externe Aktionen oder Datenquellen ein.',
      WorkflowPrimitive.humanApproval => 'Wartet auf menschliche Freigabe.',
      WorkflowPrimitive.validation =>
        'Prüft Ergebnis, Schema oder Qualitätskriterien.',
    };
  }
}
