import {type RuntimeLicenseContext} from "../entities/runtime-license-context.js";

type LicenseActivator = {
  activate(input: {activationToken: string}): Promise<RuntimeLicenseContext>;
  activeContext(): RuntimeLicenseContext | null;
};

export class ActivateRuntime {
  constructor(
    private readonly licenses: LicenseActivator,
    private readonly activateWorkspace: (context: RuntimeLicenseContext) => Promise<void>,
  ) {}

  /**
   * Ein Token ist nur einmal einlösbar. Ist die Runtime bereits lizenziert
   * (z. B. weil die Antwort der ersten Aktivierung den Client nicht erreicht
   * hat), würde eine erneute Gateway-Anfrage abgelehnt — deshalb wird dann
   * die bestehende Lizenz bestätigt.
   */
  async execute(activationToken: string): Promise<RuntimeLicenseContext> {
    const context = this.licenses.activeContext() ?? await this.licenses.activate({activationToken});
    await this.activateWorkspace(context);
    return context;
  }
}
