import assert from "node:assert/strict";
import test from "node:test";
import {type ModelInputTransformationRequest} from "../../domain/repositories/model-input-transformer.js";
import {
  HttpPythonModelInputTransformer,
  type PythonTransformHttpClient,
} from "./http-python-model-input-transformer.js";

test("sends image transformations to the private Python sidecar", async () => {
  const client = new RecordingClient();
  const transformer = new HttpPythonModelInputTransformer(
    "http://novooa-ml:8081",
    client,
  );

  const tensor = await transformer.transform(imageRequest());

  assert.equal(client.url, "http://novooa-ml:8081/v1/input-transforms");
  assert.equal(client.payload?.source.type, "image");
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

test("sends number transformations to the private Python sidecar", async () => {
  const client = new RecordingClient();
  const transformer = new HttpPythonModelInputTransformer("http://novooa-ml:8081", client);

  await transformer.transform({
    input: {
      name: "speed", source: "number", dataType: "float32", shape: [1],
      transformations: [{type: "tensor.constant", parameters: {values: [1]}}],
    },
    source: {name: "speed", type: "number", value: 1},
  });

  assert.equal(client.payload?.source.type, "number");
});

test("sends audio, json, boolean and datetime sources to the sidecar as well", async () => {
  const sources = [
    {name: "eingabe", type: "audio" as const, contentType: "audio/wav", bytes: Uint8Array.from([1])},
    {name: "eingabe", type: "json" as const, value: {land: "DE"}},
    {name: "eingabe", type: "boolean" as const, value: true},
    {name: "eingabe", type: "datetime" as const, value: "2026-10-09T10:00:00Z"},
  ];
  for (const source of sources) {
    const client = new RecordingClient();
    const transformer = new HttpPythonModelInputTransformer("http://novooa-ml:8081", client);

    await transformer.transform({
      input: {name: "eingabe", source: source.type, dataType: "float32", shape: [1], transformations: []},
      source,
    });

    assert.equal(client.payload?.source.type, source.type);
  }
});

class RecordingClient implements PythonTransformHttpClient {
  url: string | undefined;
  payload: {source: {type: string; dataBase64?: string}} | undefined;

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
      transformations: [{type: "image.resize", parameters: {width: 1, height: 1}}],
    },
    source: {name: "image", type: "image", contentType: "image/png", bytes: Uint8Array.from([1])},
  };
}

function tensorRequest(): ModelInputTransformationRequest {
  return {
    input: {name: "tensor", source: "tensor", dataType: "uint8", shape: [1], transformations: []},
    source: {
      name: "tensor", type: "tensor",
      tensor: {name: "tensor", dataType: "uint8", shape: [1], bytes: Uint8Array.from([1])},
    },
  };
}
