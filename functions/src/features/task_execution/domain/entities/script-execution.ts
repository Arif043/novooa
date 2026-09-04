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
