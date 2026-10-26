import {type ModelContract} from "../domain/entities/model-contract.js";
import {type ModelContractCheck} from "../domain/repositories/system-model-source.js";
import {type PythonJsonProcess} from "./local/local-python-process.js";

/**
 * Prüft Kette, Parameter und Setting-Bindungen eines Vertrags mit dem Transformationskatalog des
 * ML-Dienstes, ohne dass ein Dienst läuft. So lehnt die Veröffentlichung ab, was die Runtime beim
 * Cachen ablehnen würde — bevor eine unveränderliche Version im Modellspeicher liegt.
 */
export class PythonProcessModelContractValidator implements ModelContractCheck {
  constructor(private readonly process: PythonJsonProcess) {}

  async validate(contract: ModelContract): Promise<void> {
    const response = JSON.parse(await this.process.execute(JSON.stringify({contract}))) as {status?: unknown};
    if (response.status !== "ok") throw new Error("Die Vertragsprüfung lieferte kein gültiges Ergebnis.");
  }
}
