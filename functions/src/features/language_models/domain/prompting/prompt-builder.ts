import {type LlmMessage, type LlmPrompt} from "./llm-prompt.js";
import {
  comparePromptSections, type PromptSection, type PromptSectionKind, promptSectionTarget, repeatableKinds,
} from "./prompt-section.js";
import {type ResponseLanguagePolicy, responseLanguageInstruction} from "./response-language.js";

type BuilderState = {
  readonly sections: readonly PromptSection[];
  readonly rules: readonly string[];
  readonly mediaUrls: readonly string[];
  readonly history: readonly LlmMessage[];
};

/**
 * Baut einen Prompt abschnittsweise auf. Unveränderlich: Jede Methode liefert einen neuen Builder,
 * Zwischenstände lassen sich also gefahrlos teilen. Leere Inhalte fallen beim `build()` weg, damit
 * Aufrufstellen optionale Abschnitte ohne eigene Bedingungen übergeben können.
 */
export class PromptBuilder {
  private constructor(private readonly state: BuilderState) {}

  static create(): PromptBuilder {
    return new PromptBuilder({sections: [], rules: [], mediaUrls: [], history: []});
  }

  /** Wer das Modell ist und wofür es eingesetzt wird. */
  role(content: string): PromptBuilder {
    return this.with("role", content);
  }

  /** Eine allgemeine Regel; mehrere Regeln werden zu einer Liste zusammengefasst. */
  rule(content: string): PromptBuilder {
    return content.trim() === "" ? this : this.copy({rules: [...this.state.rules, content.trim()]});
  }

  /** Rahmenbedingung eines Mitarbeiters — ergänzt die Rolle, statt sie zu ersetzen. */
  employee(name: string | undefined, constraint: string | undefined): PromptBuilder {
    return this.with("employee", constraint ?? "", name);
  }

  /** Welche Dateien, Notizen und Fähigkeiten über Werkzeuge erreichbar sind. */
  attachments(content: string | undefined): PromptBuilder {
    return this.with("attachments", content ?? "");
  }

  /** Benanntes Nachschlagematerial für den Systemteil, z. B. das Team oder der Arbeitsordner; mehrfach möglich. */
  reference(name: string, content: string | undefined): PromptBuilder {
    return this.with("reference", content ?? "", name);
  }

  /** Kurzer Hinweis zur Form der Antwort; das Schema selbst geht über `LlmOutputSpec`. */
  outputFormat(content: string | undefined): PromptBuilder {
    return this.with("output_format", content ?? "");
  }

  responseLanguage(policy: ResponseLanguagePolicy): PromptBuilder {
    return this.with("response_language", responseLanguageInstruction(policy));
  }

  /** Die eigentliche Aufgabe dieses Aufrufs, z. B. die Anweisung eines Bausteins. */
  task(content: string): PromptBuilder {
    return this.with("task", content);
  }

  /** Benannte Daten zur Aufgabe; mehrfach möglich. */
  context(name: string, content: string): PromptBuilder {
    return this.with("context", content, name);
  }

  media(urls: readonly string[]): PromptBuilder {
    return this.copy({mediaUrls: [...this.state.mediaUrls, ...urls]});
  }

  history(messages: readonly LlmMessage[]): PromptBuilder {
    return this.copy({history: [...this.state.history, ...messages]});
  }

  build(): LlmPrompt {
    const sections = [...this.state.sections, ...this.rulesSection()]
      .filter((section) => section.content.trim() !== "")
      .sort(comparePromptSections);
    return {
      systemSections: sections.filter((section) => promptSectionTarget(section.kind) === "system"),
      userSections: sections.filter((section) => promptSectionTarget(section.kind) === "user"),
      mediaUrls: this.state.mediaUrls,
      history: this.state.history,
    };
  }

  private rulesSection(): PromptSection[] {
    const {rules} = this.state;
    return rules.length === 0 ? [] : [{kind: "rules", content: rules.map((rule) => `- ${rule}`).join("\n")}];
  }

  private with(kind: PromptSectionKind, content: string, name?: string): PromptBuilder {
    const kept = repeatableKinds.has(kind)
      ? this.state.sections
      : this.state.sections.filter((section) => section.kind !== kind);
    const section: PromptSection = name?.trim() ? {kind, name: name.trim(), content: content.trim()} : {kind, content: content.trim()};
    return this.copy({sections: [...kept, section]});
  }

  private copy(changes: Partial<BuilderState>): PromptBuilder {
    return new PromptBuilder({...this.state, ...changes});
  }
}
