import '../../domain/entities/assistant_context.dart';

class InternalAssistantKnowledge {
  const InternalAssistantKnowledge();

  String forContext(AssistantContext context) {
    return switch (context.area) {
      AssistantArea.taskBuilder => _taskBuilderKnowledge,
      AssistantArea.knowledgeBase => _knowledgeBaseKnowledge,
      AssistantArea.general => _generalKnowledge,
    };
  }
}

const _generalKnowledge = '''
novooa ist ein AI-Automation-System. Nutzer:innen bauen Aufgaben aus Bausteinen.
Die App spricht deutsch. Aufgabe bedeutet Workflow, Baustein bedeutet Node,
Zeitplan bedeutet Trigger, Aktivitäten bedeutet Runs, Logs und Freigaben.
''';

const _taskBuilderKnowledge = '''
Aufgaben bestehen aus Bausteinen und Kanten. Bausteine behalten ihre ID.
Ausgaben eines Bausteins liegen unter outputs. Nachfolgende Bausteine können
direkt auf die Ausgaben des vorherigen Bausteins zugreifen. Für explizite
Referenzen kann der Referenzname eines Bausteins genutzt werden, zum Beispiel
{{kundenmail.absender}}. Globale Variablen haben keinen Prefix.
Prompt-Bausteine erzeugen Text oder strukturierte Ausgaben. Script-Bausteine
führen Python isoliert aus und können Variablen für spätere Bausteine setzen.
''';

const _knowledgeBaseKnowledge = '''
Die Wissensbasis ist ein Markdown-Zettelkasten. Atomare Notizen beschreiben eine
Information. MOC-Notizen verlinken zusammenhängende Notizen. Wird eine atomare
Notiz angehängt, wird nur diese Notiz genutzt. Wird eine MOC-Notiz angehängt,
werden die MOC und alle direkt oder indirekt verlinkten Notizen genutzt. Die
Wissensbasis ist nicht wie Dateien versioniert.
''';
