import path from "node:path";
import { PublishSystemModel } from "../../domain/usecases/publish-system-model.js";
import { LocalFileModelCatalog } from "../local/local-file-model-catalog.js";
import { LocalModelArtifactPublisher } from "../local/local-model-artifact-publisher.js";
import { type ModelPublishCommandDependencies } from "./model-publish-command.js";
import { type LocalModelInstallOptions } from "./local-model-install-options.js";
import { pythonModelValidators } from "./python-model-validators.js";

export function localModelInstallDependencies(
  options: LocalModelInstallOptions,
): ModelPublishCommandDependencies {
  return {
    publisher: new PublishSystemModel(
      new LocalModelArtifactPublisher(options.runtimeRoot),
      new LocalFileModelCatalog(
        path.join(options.runtimeRoot, "model-catalog"),
      ),
    ),
    ...pythonModelValidators(options.pythonExecutable),
  };
}
