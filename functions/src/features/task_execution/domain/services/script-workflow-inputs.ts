const callPattern = /\bworkflow_input\(\s*(["'])([^"'\n]+)\1\s*\)/g;

/** Wie ein Template-Pfad: Name, danach Feldnamen oder Listenindizes (`rechnung.positionen.0`). */
const pathPattern = /^[\p{L}_][\p{L}\p{N}_]*(?:\.(?:[\p{L}_][\p{L}\p{N}_]*|\d+))*$/u;

/**
 * Die Pfade aller `workflow_input("…")`-Aufrufe eines Scripts, in Reihenfolge und ohne Doppelte.
 *
 * Erkannt werden nur feste Texte; Aufrufe hinter `#` zählen nicht. Dieselbe Regel gilt im Builder
 * (`ScriptWorkflowInputParser`), damit beide dieselben Werte meinen.
 */
export function scriptWorkflowInputPaths(script: string): string[] {
  const paths: string[] = [];
  for (const line of script.split("\n")) {
    for (const match of line.matchAll(callPattern)) {
      const path = match[2];
      if (line.slice(0, match.index).includes("#") || !pathPattern.test(path)) continue;
      if (!paths.includes(path)) paths.push(path);
    }
  }
  return paths;
}
