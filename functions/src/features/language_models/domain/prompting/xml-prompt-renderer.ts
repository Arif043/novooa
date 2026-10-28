import {type LlmPrompt} from "./llm-prompt.js";
import {type PromptRenderer, type RenderedPrompt} from "./prompt-renderer.js";
import {type PromptSection} from "./prompt-section.js";

/**
 * Rendert Abschnitte als XML-Tags, z. B. `<task>…</task>` oder `<context name="rechnung">…</context>`.
 * Tags grenzen eingebettete Nutzerdaten eindeutig ab: Überschriften oder Markdown im Inhalt bleiben
 * Inhalt. Ein schließender Tag desselben Abschnitts im Inhalt wird entschärft, damit Daten den
 * Abschnitt nicht vorzeitig beenden können.
 */
export class XmlPromptRenderer implements PromptRenderer {
  render(prompt: LlmPrompt): RenderedPrompt {
    const system = prompt.systemSections.map(renderSection).join("\n\n");
    const user = prompt.userSections.map(renderSection).join("\n\n");
    return system === "" ? {user} : {system, user};
  }
}

function renderSection(section: PromptSection): string {
  const tag = section.kind;
  const name = section.name === undefined ? "" : ` name="${escapedAttribute(section.name)}"`;
  return `<${tag}${name}>\n${defusedContent(section.content, tag)}\n</${tag}>`;
}

function escapedAttribute(value: string): string {
  return value.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

/** `</task>` im Inhalt wird zu `<\/task>` — für das Modell lesbar, aber kein Abschnittsende. */
function defusedContent(content: string, tag: string): string {
  return content.replace(new RegExp(`<\\s*/\\s*${tag}\\s*>`, "gi"), `<\\/${tag}>`);
}
