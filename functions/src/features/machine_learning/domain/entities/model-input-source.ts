import {type ModelInput} from "./model-contract.js";
import {type ModelTensor, validateModelTensor} from "./model-tensor.js";

export type ModelInputValue =
  | {type: "image"; contentType: string; bytes: Uint8Array}
  | {type: "audio"; contentType: string; bytes: Uint8Array}
  | {type: "file"; contentType: string; bytes: Uint8Array}
  | {type: "text"; value: string}
  | {type: "datetime"; value: string}
  | {type: "number"; value: number}
  | {type: "boolean"; value: boolean}
  | {type: "json"; value: unknown}
  | {type: "tensor"; tensor: ModelTensor};

export type ModelInputSource = ModelInputValue & {name: string};

export function validateModelInputSource(
  source: ModelInputSource,
  input: ModelInput,
): void {
  required(source.name, "Der Name der Modelleingabe fehlt.");
  if (source.type !== input.source) {
    throw new Error(`Die Quelle für ${input.name} hat den falschen Typ.`);
  }
  validateSourceValue(source);
}

function validateSourceValue(source: ModelInputSource): void {
  switch (source.type) {
    case "image":
      validateImageSource(source);
      return;
    case "audio":
      validateAudioSource(source);
      return;
    case "file":
      validateFileSource(source);
      return;
    case "text":
    case "datetime":
      return;
    case "number":
      validateNumberSource(source);
      return;
    case "boolean":
    case "json":
      return;
    case "tensor":
      validateTensorSource(source);
  }
}

function validateNumberSource(source: Extract<ModelInputSource, {type: "number"}>): void {
  if (!Number.isFinite(source.value)) {
    throw new Error(`Die Zahlquelle für ${source.name} ist ungültig.`);
  }
}

function validateImageSource(source: Extract<ModelInputSource, {type: "image"}>): void {
  if (!source.contentType.startsWith("image/")) {
    throw new Error(`Die Quelle für ${source.name} ist kein Bild.`);
  }
  if (source.bytes.byteLength === 0) {
    throw new Error(`Die Bildquelle für ${source.name} ist leer.`);
  }
}

function validateAudioSource(source: Extract<ModelInputSource, {type: "audio"}>): void {
  if (!source.contentType.startsWith("audio/")) {
    throw new Error(`Die Quelle für ${source.name} ist keine Audiodatei.`);
  }
  if (source.bytes.byteLength === 0) {
    throw new Error(`Die Audioquelle für ${source.name} ist leer.`);
  }
}

function validateFileSource(source: Extract<ModelInputSource, {type: "file"}>): void {
  if (source.contentType.trim().length === 0) {
    throw new Error(`Der Content-Type für ${source.name} fehlt.`);
  }
  if (source.bytes.byteLength === 0) {
    throw new Error(`Die Dateiquelle für ${source.name} ist leer.`);
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
