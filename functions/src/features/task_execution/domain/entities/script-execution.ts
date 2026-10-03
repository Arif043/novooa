export type ScriptExecutionRequest = {
  input: string;
  script: string;
  variables: Record<string, unknown>;
};

export type ScriptExecutionResult = {
  output: string;
  variables: Record<string, unknown>;
  printed: string;
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
 * Script bis dahin auf stdout ausgegeben hat — gerade beim Fehlersuchen das Wichtigste.
 */
export class ScriptExecutionError extends Error {
  constructor(message: string, readonly printed: string = "") {
    super(message);
    this.name = "ScriptExecutionError";
  }
}
