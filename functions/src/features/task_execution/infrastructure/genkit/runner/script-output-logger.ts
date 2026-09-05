import {logInfo, logReadableInfo} from "./structured-logger.js";

export function logScriptOutput(printed: string): void {
  if (printed.trim().length === 0) return;
  logReadableInfo(["[Script-Log]", printed.trimEnd()].join("\n"));
  logInfo("script_node.printed", {
    length: printed.length,
    preview: printed.slice(0, 1000),
  });
}
