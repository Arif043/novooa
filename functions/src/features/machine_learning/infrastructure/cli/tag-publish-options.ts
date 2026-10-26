import {cliOptionValues, requiredCliValue} from "./cli-option-values.js";
import {shippedModelTagsPath} from "./repository-files.js";

export type TagPublishOptions = {
  projectId: string;
  tagsPath: string;
  dryRun: boolean;
};

const rules = {flags: new Set(["dry-run"]), repeatable: new Set<string>()};

export function tagPublishOptionsFromArguments(arguments_: readonly string[]): TagPublishOptions {
  const values = cliOptionValues(arguments_, rules);
  return {
    projectId: requiredCliValue(values, "project"),
    tagsPath: values.get("tags")?.[0] ?? shippedModelTagsPath,
    dryRun: values.has("dry-run"),
  };
}

export const tagPublishUsage = [
  "Verwendung: npm --prefix functions run models:tags:publish -- --project <projekt-id> [--tags <tags.json>] [--dry-run]",
  "Ohne --tags gilt models/tags.json. Tags werden angelegt oder aktualisiert, nie gelöscht.",
].join("\n");
