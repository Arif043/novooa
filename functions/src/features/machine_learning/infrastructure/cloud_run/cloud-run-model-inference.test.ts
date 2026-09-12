import assert from "node:assert/strict";
import test from "node:test";
import {CloudRunModelInference} from "./cloud-run-model-inference.js";
import {type AuthenticatedJsonHttpClient} from "./authenticated-json-http-client.js";

test("calls the private service with its URL as ID-token audience", async () => {
  const httpClient = new RecordingClient();
  const inference = new CloudRunModelInference(
    () => "https://model-inference-123.europe-west3.run.app",
    httpClient,
  );

  const result = await inference.execute({
    teamId: "team-1",
    modelId: "classifier",
    inputs: [{name: "prompt", type: "text", value: "Hallo"}],
  });

  assert.equal(httpClient.request?.audience, "https://model-inference-123.europe-west3.run.app");
  assert.equal(httpClient.request?.url, "https://model-inference-123.europe-west3.run.app/v1/inferences");
  assert.deepEqual(httpClient.request?.body, {
    teamId: "team-1",
    modelId: "classifier",
    inputs: [{name: "prompt", type: "text", value: "Hallo"}],
  });
  assert.equal(result.outputs[0].semantic, "classification.scores");
});

test("rejects an endpoint that is not a service HTTPS URL", async () => {
  const inference = new CloudRunModelInference(() => "http://localhost:8080", new RecordingClient());

  await assert.rejects(
    () => inference.execute({teamId: "team-1", modelId: "classifier", inputs: []}),
    /HTTPS-Service-URL/,
  );
});

class RecordingClient implements AuthenticatedJsonHttpClient {
  request?: Parameters<AuthenticatedJsonHttpClient["post"]>[0];

  async post(request: Parameters<AuthenticatedJsonHttpClient["post"]>[0]): Promise<unknown> {
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
