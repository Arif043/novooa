import {type RuntimeLicenseContext} from "../entities/runtime-license-context.js";
import {RuntimeAlreadyActivatedError} from "../entities/runtime-license-errors.js";

type LicenseActivator = {
  activate(input: {activationToken: string}): Promise<RuntimeLicenseContext>;
  activeContext(): RuntimeLicenseContext | null;
  matchesActivationToken(token: unknown): boolean;
};

export class ActivateRuntime {
  constructor(
    private readonly licenses: LicenseActivator,
    private readonly activateWorkspace: (context: RuntimeLicenseContext) => Promise<void>,
  ) {}

  /**
   * Ein Token ist nur einmal einlösbar. Erreicht die Antwort der ersten
   * Aktivierung den Client nicht, bestätigt eine erneute Eingabe desselben
   * Tokens die bestehende Lizenz; ein fremder Token wird abgewiesen.
   */
  async execute(activationToken: string): Promise<RuntimeLicenseContext> {
    const context = await this.licensedContext(activationToken);
    await this.activateWorkspace(context);
    return context;
  }

  private async licensedContext(activationToken: string): Promise<RuntimeLicenseContext> {
    const active = this.licenses.activeContext();
    if (active === null) return this.licenses.activate({activationToken});
    if (this.licenses.matchesActivationToken(activationToken)) return active;
    throw new RuntimeAlreadyActivatedError();
  }
}
