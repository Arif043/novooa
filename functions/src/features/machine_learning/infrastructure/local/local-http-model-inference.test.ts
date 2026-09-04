import assert from "node:assert/strict";
import test from "node:test";
import {
  LocalHttpModelInference,
  type LocalJsonHttpClient,
} from "./local-http-model-inference.js";

test("calls the local inference service without an ID token", async () => {
  const httpClient = new RecordingClient();
  const inference = new LocalHttpModelInference(() => "http://127.0.0.1:8080", httpClient);

  const result = await inference.execute({teamId: "team-1", modelId: "classifier", inputs: []});

  assert.equal(httpClient.request?.url, "http://127.0.0.1:8080/v1/inferences");
  assert.deepEqual(httpClient.request?.body, {teamId: "team-1", modelId: "classifier", inputs: []});
  assert.equal(result.modelId, "classifier");
});

test("rejects a non-local endpoint", async () => {
  const inference = new LocalHttpModelInference(
    () => "http://model-inference.internal:8080",
    new RecordingClient(),
  );

  await assert.rejects(
    () => inference.execute({teamId: "team-1", modelId: "classifier", inputs: []}),
    /lokale HTTP-URL/,
  );
});

class RecordingClient implements LocalJsonHttpClient {
  request?: {url: string; body: object};

  async post(request: {url: string; body: object}): Promise<unknown> {
    this.request = request;
    return {
      modelId: "classifier",
      outputs: [{
        name: "scores", semantic: "classification.scores", dataType: "uint8",
        shape: [1], dataBase64: "AQ==",
      }],
    };
  }
}
