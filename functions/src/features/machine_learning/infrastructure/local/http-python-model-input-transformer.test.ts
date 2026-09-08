import assert from "node:assert/strict";
import test from "node:test";
import {type ModelInputTransformationRequest} from "../../domain/repositories/model-input-transformer.js";
import {
  HttpPythonModelInputTransformer,
  type PythonTransformHttpClient,
} from "./http-python-model-input-transformer.js";

test("sends image preprocessing to the private Python sidecar", async () => {
  const client = new RecordingClient();
  const transformer = new HttpPythonModelInputTransformer(
    "http://novooa-ml:8081",
    client,
  );

  const tensor = await transformer.transform(imageRequest());

  assert.equal(client.url, "http://novooa-ml:8081/v1/input-transforms");
  assert.equal(client.payload?.source.dataBase64, "AQ==");
  assert.equal(tensor.name, "image");
});

test("returns a valid tensor source without calling the sidecar", async () => {
  const client = new RecordingClient();
  const transformer = new HttpPythonModelInputTransformer("http://novooa-ml:8081", client);

  const tensor = await transformer.transform(tensorRequest());

  assert.equal(tensor.name, "tensor");
  assert.equal(client.url, undefined);
});

class RecordingClient implements PythonTransformHttpClient {
  url: string | undefined;
  payload: {source: {dataBase64: string}} | undefined;

  async post(url: string, body: string): Promise<unknown> {
    this.url = url;
    this.payload = JSON.parse(body) as typeof this.payload;
    return {tensor: {name: "image", dataType: "uint8", shape: [1], dataBase64: "AQ=="}};
  }
}

function imageRequest(): ModelInputTransformationRequest {
  return {
    input: {
      name: "image", source: "image", dataType: "uint8", shape: [1],
      preprocessing: [{type: "image.resize", parameters: {width: 1, height: 1}}],
    },
    source: {name: "image", type: "image", contentType: "image/png", bytes: Uint8Array.from([1])},
  };
}

function tensorRequest(): ModelInputTransformationRequest {
  return {
    input: {name: "tensor", source: "tensor", dataType: "uint8", shape: [1], preprocessing: []},
    source: {
      name: "tensor", type: "tensor",
      tensor: {name: "tensor", dataType: "uint8", shape: [1], bytes: Uint8Array.from([1])},
    },
  };
}
