import {
  type ModelInference,
  type ModelInferenceRequest,
  type ModelInferenceResult,
} from "../../domain/repositories/model-inference.js";
import {
  modelInferenceRequestJson,
  modelInferenceResultFromJson,
} from "../model-inference-http-codec.js";
import {type AuthenticatedJsonHttpClient} from "./authenticated-json-http-client.js";

export class CloudRunModelInference implements ModelInference {
  constructor(
    private readonly serviceUrl: () => string,
    private readonly httpClient: AuthenticatedJsonHttpClient,
  ) {}

  async execute(request: ModelInferenceRequest): Promise<ModelInferenceResult> {
    const serviceUrl = configuredServiceUrl(this.serviceUrl());
    const response = await this.httpClient.post({
      audience: serviceUrl,
      url: new URL("/v1/inferences", serviceUrl).toString(),
      body: modelInferenceRequestJson(request),
    });
    return modelInferenceResultFromJson(response);
  }
}

function configuredServiceUrl(value: string): string {
  const url = new URL(value.trim());
  if (url.protocol !== "https:" || url.pathname !== "/" || url.search || url.hash) {
    throw new Error("MODEL_INFERENCE_SERVICE_URL muss eine reine HTTPS-Service-URL sein.");
  }
  return url.toString().replace(/\/$/, "");
}
