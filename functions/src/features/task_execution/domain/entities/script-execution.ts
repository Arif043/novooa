export type ScriptExecutionRequest = {
  script: string;
  variables: Record<string, unknown>;
};

export type ScriptExecutionResult = {
  variables: Record<string, unknown>;
  printed: string;
  /** Alles, was das Script auf stderr geschrieben hat (Warnungen, Unterprozesse); leer oder fehlend, wenn nichts. */
  errorOutput?: string;
  /** Per `workflow_output(name, type, value)` definierte Ausgaben, ungeprüft wie vom Script-Dienst geliefert. */
  workflowOutputs?: unknown[];
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
