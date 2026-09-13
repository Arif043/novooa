import {type ModelContract, type ModelInput} from "../domain/entities/model-contract.js";
import {validateModelOutputPostprocessing} from "../domain/services/model-output-postprocessor.js";

export interface ModelInputContractCapability {
  supports(input: ModelInput): boolean;
  validate(input: ModelInput): void;
}

export class ModelContractCapabilityValidator {
  constructor(private readonly capabilities: readonly ModelInputContractCapability[]) {}

  validate(contract: ModelContract): void {
    for (const input of contract.inputs) this.capabilityFor(input).validate(input);
    contract.outputs.forEach(validateModelOutputPostprocessing);
  }

  private capabilityFor(input: ModelInput): ModelInputContractCapability {
    const capability = this.capabilities.find((candidate) => candidate.supports(input));
    if (capability !== undefined) return capability;
    throw new Error(`Die Cloud-Runtime unterstützt ${input.source}-Eingänge noch nicht.`);
  }
}

export class ImageInputContractCapability implements ModelInputContractCapability {
  constructor(private readonly transformations: ReadonlySet<string>) {}

  supports(input: ModelInput): boolean {
    return input.source === "image";
  }

  validate(input: ModelInput): void {
    for (const transformation of input.preprocessing) {
      if (!this.transformations.has(transformation.type)) {
        throw new Error(`Die Bildtransformation ${transformation.type} wird noch nicht unterstützt.`);
      }
    }
  }
}

export class TensorInputContractCapability implements ModelInputContractCapability {
  supports(input: ModelInput): boolean {
    return input.source === "tensor";
  }

  validate(input: ModelInput): void {
    if (input.preprocessing.length > 0) {
      throw new Error("Tensor-Eingänge mit Vorverarbeitung werden noch nicht unterstützt.");
    }
  }
}

export function cloudModelContractCapabilityValidator(): ModelContractCapabilityValidator {
  return new ModelContractCapabilityValidator([
    new ImageInputContractCapability(new Set([
      "image.decode", "image.resize", "tensor.layout", "tensor.normalize",
    ])),
    new TensorInputContractCapability(),
  ]);
}
