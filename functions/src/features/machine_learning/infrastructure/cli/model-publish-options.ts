export type ModelPublishOptions = {
  projectId: string;
  bucketName: string;
  manifestPath: string;
  artifactPath: string;
  pythonExecutable: string;
  dryRun: boolean;
};

export function modelPublishOptionsFromArguments(arguments_: readonly string[]): ModelPublishOptions {
  const values = optionValues(arguments_);
  const projectId = requiredValue(values, "project");
  return {
    projectId,
    bucketName: values.get("bucket") ?? `${projectId}.firebasestorage.app`,
    manifestPath: requiredValue(values, "manifest"),
    artifactPath: requiredValue(values, "artifact"),
    pythonExecutable: values.get("python") ?? process.env.PYTHON_EXECUTABLE ?? "python3",
    dryRun: values.has("dry-run"),
  };
}

export const modelPublishUsage = [
  "Verwendung: npm --prefix functions run models:publish -- --project <projekt-id>",
  "  --manifest <model.json> --artifact <model.onnx> [--bucket <bucket>] [--python <pfad>] [--dry-run]",
].join("\n");

function optionValues(arguments_: readonly string[]): Map<string, string> {
  const values = new Map<string, string>();
  for (let index = 0; index < arguments_.length; index += 1) {
    const option = arguments_[index];
    if (option === "--dry-run") values.set("dry-run", "true");
    else index = addValue(arguments_, index, values);
  }
  return values;
}

function addValue(arguments_: readonly string[], index: number, values: Map<string, string>): number {
  const option = arguments_[index];
  if (option === undefined || !option.startsWith("--")) throw new Error(`Unbekannte Option: ${option}`);
  const value = arguments_[index + 1];
  if (value === undefined || value.startsWith("--")) throw new Error(`Der Wert für ${option} fehlt.`);
  values.set(option.slice(2), value);
  return index + 1;
}

function requiredValue(values: ReadonlyMap<string, string>, name: string): string {
  const value = values.get(name);
  if (value === undefined || value.trim().length === 0) throw new Error(`Die Option --${name} fehlt.`);
  return value;
}
