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
