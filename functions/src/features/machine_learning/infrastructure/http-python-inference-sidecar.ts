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
import {type MlServiceHttp, responseCode} from "./ml-service-http.js";
import {isRecord, runtimeOutputsFrom, sidecarErrorMessage} from "./python-inference-sidecar-codec.js";

export class HttpPythonInferenceSidecar implements PythonInferenceSidecar {
  constructor(private readonly http: MlServiceHttp) {}

  async load(bundle: ModelBundle, source: ModelBundleSource): Promise<void> {
    await this.post("/v1/models", bundleJson(bundle, source));
  }

  async prefetch(bundle: ModelBundle): Promise<void> {
    await this.post("/v1/bundles", bundleJson(bundle, "global"));
  }

  async upload(bundle: ModelBundle, file: ModelBundleFile, open: () => Readable): Promise<void> {
    const response = await this.http.send({
      method: "PUT",
      path: `/v1/bundles/${bundle.key}/files/${file.path}`,
      headers: {"content-length": String(file.sizeBytes), "x-sha256": file.sha256},
      body: () => Readable.toWeb(open()) as ReadableStream<Uint8Array>,
    });
    if (response.status >= 400) throw new Error(sidecarErrorMessage(response.payload));
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
    const response = await this.http.send({
      method: "POST", path, headers: {"content-type": "application/json"}, body: () => JSON.stringify(body),
    });
    const code = responseCode(response);
    if (response.status === 404 && code === "model_not_loaded") throw new ModelNotLoadedError();
    if (response.status === 409 && code === "bundle_files_missing" && isRecord(response.payload)) {
      throw new BundleFilesMissingError(missingFiles(response.payload.missing));
    }
    if (response.status >= 400) throw new Error(sidecarErrorMessage(response.payload));
    return response.payload;
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
