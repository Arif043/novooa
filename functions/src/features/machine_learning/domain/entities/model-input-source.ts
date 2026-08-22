import {type ModelInput} from "./model-contract.js";
import {type ModelTensor, validateModelTensor} from "./model-tensor.js";

export type ModelInputSource =
  | {name: string; type: "image"; contentType: string; bytes: Uint8Array}
  | {name: string; type: "tensor"; tensor: ModelTensor};

export function validateModelInputSource(
  source: ModelInputSource,
  input: ModelInput,
): void {
  required(source.name, "Der Name der Modelleingabe fehlt.");
  if (source.type !== input.source) {
    throw new Error(`Die Quelle für ${input.name} hat den falschen Typ.`);
  }
  if (source.type === "image") validateImageSource(source);
  if (source.type === "tensor") validateTensorSource(source);
}

function validateImageSource(source: Extract<ModelInputSource, {type: "image"}>): void {
  if (!source.contentType.startsWith("image/")) {
    throw new Error(`Die Quelle für ${source.name} ist kein Bild.`);
  }
  if (source.bytes.byteLength === 0) {
    throw new Error(`Die Bildquelle für ${source.name} ist leer.`);
  }
}

function validateTensorSource(source: Extract<ModelInputSource, {type: "tensor"}>): void {
  validateModelTensor(source.tensor);
  if (source.tensor.name !== source.name) {
    throw new Error(`Der Tensorname für ${source.name} stimmt nicht mit der Quelle überein.`);
  }
}

function required(value: string, message: string): void {
  if (value.trim().length === 0) throw new Error(message);
}
