import {
  type ModelInference,
  type ModelInferenceRequest,
  type ModelInferenceResult,
} from "../../domain/repositories/model-inference.js";
import {
  modelInferenceRequestJson,
  modelInferenceResultFromJson,
} from "../model-inference-http-codec.js";

type LocalJsonRequest = {url: string; body: object};

export interface LocalJsonHttpClient {
  post(request: LocalJsonRequest): Promise<unknown>;
}

export class LocalHttpModelInference implements ModelInference {
  constructor(
    private readonly serviceUrl: () => string,
    private readonly httpClient: LocalJsonHttpClient,
  ) {}

  async execute(request: ModelInferenceRequest): Promise<ModelInferenceResult> {
    const serviceUrl = configuredLocalServiceUrl(this.serviceUrl());
    const response = await this.httpClient.post({
      url: new URL("/v1/inferences", serviceUrl).toString(),
      body: modelInferenceRequestJson(request),
    });
    return modelInferenceResultFromJson(response);
  }
}

export class FetchLocalJsonHttpClient implements LocalJsonHttpClient {
  async post(request: LocalJsonRequest): Promise<unknown> {
    const response = await fetch(request.url, {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify(request.body),
    });
    const body = await response.json() as unknown;
    if (!response.ok) throw new Error(responseError(body, response.status));
    return body;
  }
}

function configuredLocalServiceUrl(value: string): string {
  const url = new URL(value.trim());
  if (url.protocol !== "http:" || !isLoopbackHost(url.hostname) || url.search || url.hash) {
    throw new Error("Der lokale Inferenzdienst muss über eine lokale HTTP-URL erreichbar sein.");
  }
  return url.toString().replace(/\/$/, "");
}

function isLoopbackHost(hostname: string): boolean {
  return hostname === "localhost" || hostname === "127.0.0.1" || hostname === "[::1]";
}

function responseError(body: unknown, status: number): string {
  if (typeof body === "object" && body !== null && "error" in body && typeof body.error === "string") {
    return body.error;
  }
  return `Der lokale Inferenzdienst antwortete mit HTTP ${status}.`;
}
