import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";

export function scriptOutputLogger(logger: ApplicationLogger): (printed: string) => void {
  return (printed) => logScriptOutput(logger, printed);
}

function logScriptOutput(logger: ApplicationLogger, printed: string): void {
  if (printed.trim().length === 0) return;
  logger.readableInfo(["[Script-Log]", printed.trimEnd()].join("\n"));
  logger.info("script_node.printed", {
    length: printed.length,
    preview: printed.slice(0, 1000),
  });
}
