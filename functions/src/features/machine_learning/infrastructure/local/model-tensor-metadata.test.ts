import assert from "node:assert/strict";
import test from "node:test";
import {modelTensorFromJson, modelTensorToJson} from "./model-tensor-json-codec.js";

const geometry = {sourceWidth: 1000, sourceHeight: 500, scaleX: 0.64, scaleY: 0.64, offsetX: 0, offsetY: 160};

test("keeps the input metadata on its way from input transformation to inference", () => {
  const tensor = modelTensorFromJson({
    name: "bild", dataType: "uint8", shape: [1], dataBase64: "AQ==", metadata: {geometry},
  });

  assert.deepEqual(tensor.metadata, {geometry});
  assert.deepEqual(modelTensorToJson(tensor).metadata, {geometry});
});

test("tensors without metadata stay without metadata", () => {
  const tensor = modelTensorFromJson({name: "zahl", dataType: "uint8", shape: [1], dataBase64: "AQ=="});

  assert.equal(tensor.metadata, undefined);
  assert.equal("metadata" in modelTensorToJson(tensor), false);
});

test("rejects metadata that is not an object", () => {
  assert.throws(
    () => modelTensorFromJson({name: "bild", dataType: "uint8", shape: [1], dataBase64: "AQ==", metadata: [1]}),
    /Metadaten des Tensors bild sind ungültig/,
  );
});
