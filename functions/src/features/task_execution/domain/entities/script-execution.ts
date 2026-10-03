export type ScriptExecutionRequest = {
  input: string;
  script: string;
  variables: Record<string, unknown>;
};

export type ScriptExecutionResult = {
  output: string;
  variables: Record<string, unknown>;
  printed: string;
  /** Alles, was das Script auf stderr geschrieben hat (Warnungen, Unterprozesse); leer oder fehlend, wenn nichts. */
  errorOutput?: string;
};

/** Die angehängten Dateien eines Script-Bausteins, wie sie auf der Platte der Runtime liegen. */
export type ScriptWorkspace = {
  rootDirectory: string;
  files: readonly ScriptWorkspaceFile[];
};

export type ScriptWorkspaceFile = {
  displayName: string;
  contentType: string;
  sizeBytes: number;
  versionCreatedAt?: number;
  filename: string;
};

/**
 * Ein Script ist gescheitert. Die Meldung ist für den Nutzer bestimmt; [printed] ist alles, was das
 * Script bis dahin auf stdout ausgegeben hat, [errorOutput] das auf stderr — gerade beim Fehlersuchen
 * das Wichtigste.
 */
export class ScriptExecutionError extends Error {
  constructor(message: string, readonly printed: string = "", readonly errorOutput: string = "") {
    super(message);
    this.name = "ScriptExecutionError";
  }
}
