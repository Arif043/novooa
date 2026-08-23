import {type ModelContract} from "../domain/entities/model-contract.js";
import {type PythonJsonProcess} from "./local/local-python-process.js";

export type OnnxModelValidationRequest = {
  artifactPath: string;
  contract: ModelContract;
};

export class PythonOnnxModelValidator {
  constructor(private readonly process: PythonJsonProcess) {}

  async validate(request: OnnxModelValidationRequest): Promise<void> {
    const response = await this.process.execute(JSON.stringify(request));
    if (JSON.parse(response).valid !== true) throw new Error("Die ONNX-Modellprüfung lieferte kein gültiges Ergebnis.");
  }
}
