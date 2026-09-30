import {type RuntimeLicenseContext} from "../entities/runtime-license-context.js";

type LicenseActivator = {activate(input: {activationToken: string}): Promise<RuntimeLicenseContext>};

export class ActivateRuntime {
  constructor(
    private readonly licenses: LicenseActivator,
    private readonly activateWorkspace: (context: RuntimeLicenseContext) => Promise<void>,
  ) {}

  async execute(activationToken: string): Promise<RuntimeLicenseContext> {
    const context = await this.licenses.activate({activationToken});
    await this.activateWorkspace(context);
    return context;
  }
}
