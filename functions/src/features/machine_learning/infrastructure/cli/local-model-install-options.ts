import {modelPublishOptionsFromArguments, type ModelPublishOptions} from "./model-publish-options.js";

export type LocalModelInstallOptions = ModelPublishOptions & {runtimeRoot: string};

export function localModelInstallOptionsFromArguments(arguments_: readonly string[]): LocalModelInstallOptions {
  const runtimeRoot = optionValue(arguments_, "runtime-root");
  const publishArguments = ["--project", "local", ...withoutRuntimeRoot(arguments_)];
  return {...modelPublishOptionsFromArguments(publishArguments), runtimeRoot};
}

export const localModelInstallUsage = [
  "Verwendung: npm --prefix functions run models:install-local -- --runtime-root <ordner>",
  "  --manifest <model.json> --artifact <model.onnx> [--python <pfad>] [--dry-run]",
].join("\n");

function optionValue(arguments_: readonly string[], name: string): string {
  const index = arguments_.indexOf(`--${name}`);
  const value = index >= 0 ? arguments_[index + 1] : undefined;
  if (value === undefined || value.startsWith("--") || value.trim().length === 0) {
    throw new Error(`Die Option --${name} fehlt.`);
  }
  return value;
}

function withoutRuntimeRoot(arguments_: readonly string[]): readonly string[] {
  const index = arguments_.indexOf("--runtime-root");
  return index < 0 ? arguments_ : [...arguments_.slice(0, index), ...arguments_.slice(index + 2)];
}
