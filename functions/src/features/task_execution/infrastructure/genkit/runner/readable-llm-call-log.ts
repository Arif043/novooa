import {type LlmOutputSpec} from "../../../../language_models/domain/prompting/llm-gateway.js";
import {
  type LlmCallFinished, type LlmCallLog, type LlmCallStarted,
} from "../../../../language_models/infrastructure/genkit/llm/llm-call-log.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";
import {formatModelCallFinished, formatModelCallStarted} from "./structured-log-format.js";

/** Schreibt Aufrufe des LLM-Frameworks in das lesbare Ausführungsprotokoll einer Aufgabe. */
export class ReadableLlmCallLog implements LlmCallLog {
  constructor(private readonly logger: ApplicationLogger) {}

  started(entry: LlmCallStarted): void {
    this.logger.readableInfo(formatModelCallStarted({
      label: entry.label, model: entry.model, options: entry.options, mediaCount: entry.mediaCount,
      outputSchema: outputSchemaLabel(entry.output),
      prompt: entry.system === undefined ? entry.user : `${entry.system}\n\n${entry.user}`,
    }));
  }

  finished(entry: LlmCallFinished): void {
    this.logger.readableInfo(formatModelCallFinished({
      label: entry.label, durationMs: entry.durationMs, output: entry.data,
      // Bilder kommen als lange Data-URL; im Protokoll genügt die Größe.
      text: entry.mediaUrl === undefined ? entry.text : `Bild generiert (${entry.mediaUrl.length} Zeichen)`,
    }));
  }
}

function outputSchemaLabel(output: LlmOutputSpec): string | undefined {
  switch (output.kind) {
    case "choice": return "answer: enum";
    case "structured": return output.fields.map((field) => field.name.trim()).join(", ");
    case "image": return "dataUrl: Bild-Data-URL";
    default: return undefined;
  }
}
