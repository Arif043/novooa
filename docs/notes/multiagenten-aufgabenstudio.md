# Multiagenten-Architektur des Aufgabenstudios

> Der Aufgabenstudio-Agent ist ein Orchestrator, der Facharbeit an drei Subagenten als Tools delegiert und als Einziger `answer` und `commands` liefert.

Gehört zu: [KI-Agent](../index/ki-agent.md)

| Subagent (Tool) | Aufgabe | Tools | Ausgabe |
| --- | --- | --- | --- |
| `requirements_analysis` | Zerlegt einen Wunsch in Bausteine (Produktwissen `novooa-product-knowledge.ts`) | keine | `goal`, `trigger`, `steps` (mit `addable`), `openQuestions`, `needsModel`, `needsScript` |
| `model_catalog_search` | Findet ONNX-Modelle für `modelInference` | `searchModels` (lesend, `SearchModelCatalog`) | bis zu drei `suggestions` mit `modelId`, `reason`, `inputs` und `outputs` |
| `python_development` | Schreibt Code für den Script-Baustein | keine | `script`, `workflowOutputs`, `notes` |

- **Ablauf:** zuerst Anforderungsanalyse, je nach Profil Modellsuche und
  Python-Entwicklung (unabhängige Aufrufe parallel). Offene Fragen stellt er in
  `answer`, statt zu raten.
- **Nur Vorschläge:** Subagenten haben keine verändernden Tools; Änderungen
  bleiben `commands` bis **Ausführen**.
- **Kein Code-Ausführen:** `scriptDraftProblems` (Domain) prüft den Entwurf
  statisch; Funde stehen als `Prüfung: …` in `notes`.
- **Grenzen:** höchstens fünf Delegationen je Anfrage (`DelegationBudget`);
  Subagenten 1–4 Tool-Runden, Orchestrator 8; Callable und Relay höchstens
  120 s.
- **Fehler:** Ein gescheiterter Subagent liefert `{ok: false, grund}`; der
  Orchestrator arbeitet weiter und sagt, was fehlt.
- **Team:** Der Callable löst das aktive Team auf (System- und Teammodelle).
- **Umsetzung:** `defineSubagentTool`
  (`assistant/infrastructure/genkit/subagents`) erzeugt je Anfrage ein
  `ai.dynamicTool`, damit Modell und Budget nur für diese Anfrage gelten. Der
  Aufruf läuft über das [LLM-Framework](./llm-aufruf-framework.md): Die Spec
  liefert Anweisungen als `PromptBuilder`, die Eingabe des Orchestrators kommt
  als `<context name="input">` (Daten, keine Anweisung), freie Texte in der
  Sprache der Anfrage. Specs:
  `machine_learning/infrastructure/genkit/model-catalog-subagent.ts`,
  `task_execution/infrastructure/genkit/assistant/subagents/`. Delegationen
  erscheinen als verschachtelte Spans im Genkit-Trace.

## Siehe auch

- [Commands und Agent-Cursor](./agent-commands-und-cursor.md)
- [Modellsuche](./modellsuche.md)
- [Script: Workflow-Ausgabewerte](./script-workflow-output.md)
