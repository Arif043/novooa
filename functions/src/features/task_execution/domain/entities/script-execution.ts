import {type WorkflowInputValue} from "./workflow-value.js";

export type ScriptExecutionRequest = {
  script: string;
  /** Die per `workflow_input("pfad")` gelesenen Werte, unter ihrem Pfad. */
  inputs: Record<string, WorkflowInputValue>;
  /** Normalisierte Paketliste des Bausteins (`normalizedScriptPackages`); leer = nur Standardbibliothek. */
  packages: string[];
};

export type ScriptExecutionResult = {
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
