import {createServer, type IncomingMessage, type Server, type ServerResponse} from "node:http";
import {type ModelInference} from "../domain/repositories/model-inference.js";
import {modelInferenceRequestFromJson, modelInferenceResultJson} from "./model-inference-http-codec.js";

const maxRequestBytes = 16 * 1024 * 1024;

export function createModelInferenceHttpServer(inference: ModelInference): Server {
  return createServer((request, response) => {
    void respondToRequest(request, response, inference);
  });
}

async function respondToRequest(
  request: IncomingMessage,
  response: ServerResponse,
  inference: ModelInference,
): Promise<void> {
  if (request.method === "GET" && request.url === "/healthz") return respondJson(response, 200, {status: "ok"});
  if (request.method !== "POST" || request.url !== "/v1/inferences") {
    return respondJson(response, 404, {error: "Endpunkt nicht gefunden."});
  }
  await runInferenceRequest(request, response, inference);
}

async function runInferenceRequest(
  request: IncomingMessage,
  response: ServerResponse,
  inference: ModelInference,
): Promise<void> {
  try {
    const input = modelInferenceRequestFromJson(JSON.parse(await requestBody(request)));
    const inferenceResult = await inference.execute(input);
    respondJson(response, 200, modelInferenceResultJson(inferenceResult));
  } catch (error) {
    const statusCode = error instanceof RequestTooLargeError ? 413 : 422;
    respondJson(response, statusCode, {error: errorMessage(error)});
  }
}

function requestBody(request: IncomingMessage): Promise<string> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    let size = 0;
    request.on("data", (chunk: Buffer) => {
      size += chunk.byteLength;
      if (size > maxRequestBytes) return reject(new RequestTooLargeError());
      chunks.push(chunk);
    });
    request.on("end", () => resolve(Buffer.concat(chunks).toString("utf8")));
    request.on("error", reject);
  });
}

function respondJson(response: ServerResponse, statusCode: number, body: object): void {
  response.writeHead(statusCode, {"content-type": "application/json; charset=utf-8"});
  response.end(JSON.stringify(body));
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : "Die Modellausführung ist fehlgeschlagen.";
}

class RequestTooLargeError extends Error {
  constructor() {
    super("Die Inferenzanfrage ist zu groß.");
  }
}
