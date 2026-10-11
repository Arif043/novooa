import {Readable} from "node:stream";
import {type ModelRuntimeOutput} from "../domain/repositories/model-inference-runtime.js";
import {modelTensorToJson} from "./local/model-tensor-json-codec.js";
import {type ModelBundle, type ModelBundleFile} from "./model-artifact-bundle.js";
import {type ModelBundleSource} from "./model-bundle-sources.js";
import {
  BundleFilesMissingError,
  ModelNotLoadedError,
  type PythonInferenceSidecar,
  type SidecarInferenceRequest,
} from "./python-inference-sidecar.js";
import {isRecord, runtimeOutputsFrom, sidecarErrorMessage} from "./python-inference-sidecar-codec.js";

export class HttpPythonInferenceSidecar implements PythonInferenceSidecar {
  constructor(private readonly baseUrl: string) {}

  async load(bundle: ModelBundle, source: ModelBundleSource): Promise<void> {
    await this.post("/v1/models", bundleJson(bundle, source));
  }

  async prefetch(bundle: ModelBundle): Promise<void> {
    await this.post("/v1/bundles", bundleJson(bundle, "global"));
  }

  async upload(bundle: ModelBundle, file: ModelBundleFile, content: Readable): Promise<void> {
    const response = await fetch(new URL(`/v1/bundles/${bundle.key}/files/${file.path}`, this.baseUrl), {
      method: "PUT",
      headers: {"content-length": String(file.sizeBytes), "x-sha256": file.sha256},
      body: Readable.toWeb(content) as ReadableStream<Uint8Array>,
      duplex: "half",
    } as RequestInit & {duplex: "half"});
    if (!response.ok) throw new Error(sidecarErrorMessage(await response.json() as unknown));
  }

  async infer(request: SidecarInferenceRequest): Promise<readonly ModelRuntimeOutput[]> {
    const body = await this.post("/v1/inferences", {
      modelKey: request.modelKey,
      inputs: request.inputs.map(modelTensorToJson),
      outputs: request.outputs,
    });
    return runtimeOutputsFrom(body);
  }

  private async post(path: string, body: object): Promise<unknown> {
    const response = await fetch(new URL(path, this.baseUrl), {
      method: "POST", headers: {"content-type": "application/json"}, body: JSON.stringify(body),
    });
    const payload = await response.json() as unknown;
    if (response.status === 404 && isRecord(payload) && payload.code === "model_not_loaded") throw new ModelNotLoadedError();
    if (response.status === 409 && isRecord(payload) && payload.code === "bundle_files_missing") {
      throw new BundleFilesMissingError(missingFiles(payload.missing));
    }
    if (!response.ok) throw new Error(sidecarErrorMessage(payload));
    return payload;
  }
}

/** Globale Dateien tragen ihren Speicherpfad; Teamdateien nicht, denn die liefert die Runtime selbst. */
function bundleJson(bundle: ModelBundle, source: ModelBundleSource): object {
  return {
    modelKey: bundle.key,
    source,
    files: bundle.files.map((file) => ({
      path: file.path, sha256: file.sha256, sizeBytes: file.sizeBytes,
      ...(source === "global" ? {storePath: file.storePath} : {}),
    })),
  };
}

function missingFiles(value: unknown): readonly string[] {
  if (!Array.isArray(value) || !value.every((item) => typeof item === "string")) {
    throw new Error("Die Antwort des ML-Dienstes ist ungültig.");
  }
  return value;
}
