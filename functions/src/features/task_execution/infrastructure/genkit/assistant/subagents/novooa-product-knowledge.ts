import {taskBuilderAssistantPrimitives} from "../../../../domain/entities/task-builder-assistant-response.js";

/**
 * Produktwissen für Anforderungsanalyse und Aufgabenstudio-Agent. Quelle: docs/notes/bausteinkatalog.md
 * § Primitives — bei neuen oder geänderten Bausteinen hier mitpflegen.
 */
const buildingBlocks: ReadonlyArray<readonly [primitive: string, description: string]> = [
  ["stringInput", "Text input: passes on fixed text."],
  ["prompt", "Prompt: LLM call with a template and workflow values; output text, a decision, structured fields or an image."],
  ["script", "Script: runs Python in isolation (5 s, 10 KB output); reads values with workflow_input, provides them with workflow_output."],
  ["conditionalFlow", "Conditional flow: branches on a decision or boolean conditions."],
  ["iterativeRefinement", "Iterative refinement: reviews and improves a draft."],
  ["writeFile", "Write file: saves a value as a file (tables as .xlsx)."],
  ["readFile", "Read file: reads a specific file version."],
  ["readEmail", "Read email: sender, subject and content of an email event."],
  ["readChannelEvent", "Read message: reads an email, WhatsApp or SMS event."],
  ["sendChannelMessage", "Send message: sends an email, WhatsApp message or SMS."],
  ["notificationSend", "Sends a push notification to all team members."],
  ["humanApproval", "Approval: pauses the run until a person decides."],
  ["dialogInput", "Form input: asks for typed input through a form."],
  ["modelInference", "Run model: ONNX model from the model catalog (e.g. image/text classification, OCR)."],
  ["textToSpeech", "Reads text aloud through a connected language model."],
  ["speechToText", "Transcribes audio through a connected language model."],
  ["forEach", "For each element: runs an embedded plan for every element of a JSON array."],
  ["documentLookup", "Find record (local runtime only)."],
  ["saveDocument", "Save or update a record (local runtime only)."],
  ["tableFromCollection", "Read a collection as a table (local runtime only)."],
  ["readWebhook", "Reads the webhook event that started the task (local runtime only)."],
  ["shopware", "Shopware action: orders, products, customers (local runtime only, connection required)."],
  ["googleDrive", "Google Drive: save, read or search files; only shared files and files created by novooa (Google account required)."],
  ["teamwork", "Teamwork: an orchestrator hands out assignments to selected employees (each with a responsibility and its own model; they remember earlier assignments in the run) and delivers a structured result, including text files. Optionally a separate, often stronger model reviews the result before delivery (local runtime only)."],
  ["httpRequest", "HTTP request to an external API, optionally through a saved connection (local runtime only)."],
];

function buildingBlockLines(): string {
  const addable = new Set<string>(taskBuilderAssistantPrimitives);
  return buildingBlocks
    .map(([primitive, description]) => `- ${primitive}${addable.has(primitive) ? " [addable]" : ""}: ${description}`)
    .join("\n");
}

/** Begriffe der App bleiben deutsch in Klammern, damit Antworten die Bezeichnungen der Oberfläche treffen. */
export const novooaProductKnowledge = `- A task (Aufgabe) is a workflow of building blocks (Bausteine) and edges. It starts manually, on a schedule
  (Zeitplan), on an event (email, WhatsApp, SMS, Shopware) or through a webhook.
- Building blocks provide typed workflow output values; script blocks can additionally set variables.
  References use templates, e.g. {{rechnung.summe}}.
- Employees (Mitarbeiter) are subagents (constraint + skills) for prompt blocks.
- The knowledge base (Wissensbasis), files (Dateien) and data collections (Sammlungen) are available to building blocks.

Building blocks ([addable] = the agent can propose it directly today):
${buildingBlockLines()}`;
