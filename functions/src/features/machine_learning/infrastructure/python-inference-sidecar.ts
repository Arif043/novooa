import {type Readable} from "node:stream";
import {type ModelCatalogEntry} from "../domain/entities/model-catalog-entry.js";
import {type ModelOutput} from "../domain/entities/model-contract.js";
import {type ModelTensor} from "../domain/entities/model-tensor.js";
import {type ModelArtifactPrefetcher} from "../domain/repositories/model-artifact-prefetcher.js";
import {
  type ModelInferenceRuntime,
  type ModelInputPreparationRuntime,
  type ModelRuntimeOutput,
  type ModelRuntimePreparationRequest,
  type ModelRuntimeRequest,
} from "../domain/repositories/model-inference-runtime.js";
import {type ModelBundle, type ModelBundleFile, modelBundleFor} from "./model-artifact-bundle.js";
import {type ModelBundleSource, type ModelBundleSources} from "./model-bundle-sources.js";

/** Der ML-Dienst: lädt Modelle über Referenzen, nie über ihre Bytes in JSON. */
export interface PythonInferenceSidecar {
  load(bundle: ModelBundle, source: ModelBundleSource): Promise<void>;
  prefetch(bundle: ModelBundle): Promise<void>;
  /** `open` liefert den Inhalt je Versuch neu, damit ein Upload wiederholt werden kann. */
  upload(bundle: ModelBundle, file: ModelBundleFile, open: () => Readable): Promise<void>;
  infer(request: SidecarInferenceRequest): Promise<readonly ModelRuntimeOutput[]>;
}

export type SidecarInferenceRequest = {
  readonly modelKey: string;
  readonly inputs: readonly ModelTensor[];
  readonly outputs: readonly ModelOutput[];
};

export class ModelNotLoadedError extends Error {}

/** Dem ML-Dienst fehlen Dateien eines Teammodells; die Runtime lädt sie hoch und versucht es erneut. */
export class BundleFilesMissingError extends Error {
  constructor(readonly missing: readonly string[]) {
    super("Dem ML-Dienst fehlen Dateien des Modells.");
  }
}

export class SidecarOnnxInferenceRuntime implements ModelInferenceRuntime, ModelInputPreparationRuntime, ModelArtifactPrefetcher {
  private readonly loadedModels = new Map<string, Promise<void>>();

  constructor(
    private readonly sidecar: PythonInferenceSidecar,
    private readonly sources: ModelBundleSources,
  ) {}

  async execute(request: ModelRuntimeRequest): Promise<readonly ModelRuntimeOutput[]> {
    const bundle = modelBundleFor(request.model.artifactReference);
    await this.load(request.model, bundle);
    try {
      return await this.infer(bundle, request);
    } catch (error) {
      if (!(error instanceof ModelNotLoadedError)) throw error;
      this.loadedModels.delete(bundle.key);
      await this.load(request.model, bundle);
      return this.infer(bundle, request);
    }
  }

  async prepareInputs(request: ModelRuntimePreparationRequest): Promise<string> {
    const bundle = modelBundleFor(request.model.artifactReference);
    await this.load(request.model, bundle);
    return bundle.key;
  }

  async prefetch(entry: ModelCatalogEntry): Promise<void> {
    if (this.sources.sourceOf(entry) !== "global") return;
    await this.sidecar.prefetch(modelBundleFor(entry.artifactReference));
  }

  private load(model: ModelCatalogEntry, bundle: ModelBundle): Promise<void> {
    const running = this.loadedModels.get(bundle.key);
    if (running !== undefined) return running;
    const loading = this.loadWithUpload(model, bundle).catch((error: unknown) => {
      this.loadedModels.delete(bundle.key);
      throw error;
    });
    this.loadedModels.set(bundle.key, loading);
    return loading;
  }

  private async loadWithUpload(model: ModelCatalogEntry, bundle: ModelBundle): Promise<void> {
    const source = this.sources.sourceOf(model);
    try {
      await this.sidecar.load(bundle, source);
    } catch (error) {
      if (!(error instanceof BundleFilesMissingError) || source !== "team") throw error;
      await this.uploadMissing(bundle, error.missing);
      await this.sidecar.load(bundle, source);
    }
  }

  private async uploadMissing(bundle: ModelBundle, missing: readonly string[]): Promise<void> {
    for (const file of bundle.files.filter((item) => missing.includes(item.path))) {
      await this.sidecar.upload(bundle, file, () => this.sources.teamFileContent(file));
    }
  }

  private infer(bundle: ModelBundle, request: ModelRuntimeRequest) {
    return this.sidecar.infer({modelKey: bundle.key, inputs: request.inputs, outputs: request.model.contract.outputs});
  }
}
