import {type ScriptOutput} from "../../../domain/executors/script-node-executor.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";

/** Ereignisnamen, an denen die Oberfläche die Script-Ausgabe erkennt (stderr wird rötlich dargestellt). */
export const scriptStdoutEvent = "script_node.stdout";
export const scriptStderrEvent = "script_node.stderr";

export function scriptOutputLogger(logger: ApplicationLogger): (output: ScriptOutput) => void {
  return (output) => {
    logStdout(logger, output.printed);
    logStderr(logger, output.errorOutput);
  };
}

function logStdout(logger: ApplicationLogger, printed: string): void {
  if (printed.trim().length === 0) return;
  logger.readableInfo(["[Script-Log]", printed.trimEnd()].join("\n"), scriptStdoutEvent);
  logger.info("script_node.printed", {
    length: printed.length,
    preview: printed.slice(0, 1000),
  });
}

function logStderr(logger: ApplicationLogger, errorOutput: string): void {
  if (errorOutput.trim().length === 0) return;
  logger.readableError(["[Script-Fehlerausgabe]", errorOutput.trimEnd()].join("\n"), scriptStderrEvent);
}
