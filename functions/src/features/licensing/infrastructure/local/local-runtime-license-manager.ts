import {type RuntimeLicenseActivation} from "../../domain/entities/runtime-license-activation.js";
import {isActiveRuntimeLicense, type SignedRuntimeLicense} from "../../domain/entities/runtime-license-lease.js";
import {runtimeActivationTokenFrom} from "../../domain/entities/activation-token.js";
import {verifiesRuntimeLicense} from "../license-lease-crypto.js";
import {type RuntimeLicenseStore} from "./file-local-runtime-license-store.js";
import {type RuntimeLicenseGatewayClient} from "./local-runtime-license-gateway-client.js";

export type RuntimeLicenseContext = {
  licenseId: string;
  licenseName: string;
  workspaceId: string;
  expiresAt?: string;
};
export type RuntimeLicenseStatus = {state: "active" | "expired" | "notActivated"; expiresAt?: string; name?: string;};
export type RuntimeLicenseActivationInput = {activationToken: string;};

export interface RuntimeLicenseService {
  restore(): Promise<RuntimeLicenseContext | null>;
  activate(input: RuntimeLicenseActivationInput): Promise<RuntimeLicenseContext>;
  release(): Promise<void>;
  activeContext(): RuntimeLicenseContext | null;
  signedActiveLicense(): SignedRuntimeLicense | null;
  status(): RuntimeLicenseStatus;
}

export class GatewayRuntimeLicenseService implements RuntimeLicenseService {
  private state: RuntimeLicenseActivation | undefined;

  constructor(
    private readonly store: RuntimeLicenseStore,
    private readonly gateway: RuntimeLicenseGatewayClient,
    private readonly publicKeyPem: string,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async restore(): Promise<RuntimeLicenseContext | null> {
    this.state = (await this.store.load()) ?? undefined;
    return this.activeContext();
  }

  async activate(input: RuntimeLicenseActivationInput): Promise<RuntimeLicenseContext> {
    const token = runtimeActivationTokenFrom(input.activationToken);
    const activation = await this.gateway.activate(token);
    return this.saveAndActivate(activation);
  }

  async release(): Promise<void> {
    if (this.state === undefined || !this.isValid(this.state)) throw new Error("Keine aktive Lizenz.");
    await this.gateway.release(this.state);
    await this.store.clear();
    this.state = undefined;
  }

  activeContext(): RuntimeLicenseContext | null {
    if (this.state === undefined || !this.isValid(this.state)) return null;
    const {licenseId, licenseName, workspaceId, expiresAt} = this.state.license.payload;
    return {licenseId, licenseName, workspaceId, expiresAt};
  }

  signedActiveLicense(): SignedRuntimeLicense | null {
    return this.state !== undefined && this.isValid(this.state) ? this.state.license : null;
  }

  status(): RuntimeLicenseStatus {
    const active = this.activeContext();
    if (active !== null) return {state: "active", expiresAt: active.expiresAt, name: active.licenseName};
    if (this.state !== undefined) return {state: "expired", expiresAt: this.state.license.payload.expiresAt};
    return {state: "notActivated"};
  }

  private async saveAndActivate(state: RuntimeLicenseActivation): Promise<RuntimeLicenseContext> {
    if (!this.isValid(state)) throw new Error("Der Lizenzschlüssel ist ungültig.");
    this.state = state;
    await this.store.save(state);
    return this.activeContext()!;
  }

  private isValid(state: RuntimeLicenseActivation): boolean {
    return verifiesRuntimeLicense(state.license, this.publicKeyPem) &&
      isActiveRuntimeLicense(state.license.payload, this.now());
  }
}

export class DevelopmentRuntimeLicenseService implements RuntimeLicenseService {
  constructor(private readonly context: RuntimeLicenseContext) {}
  async restore(): Promise<RuntimeLicenseContext> { return this.context; }
  async activate(): Promise<RuntimeLicenseContext> { return this.context; }
  async release(): Promise<void> {}
  activeContext(): RuntimeLicenseContext { return this.context; }
  signedActiveLicense(): SignedRuntimeLicense | null { return null; }
  status(): RuntimeLicenseStatus { return {state: "active", name: this.context.licenseName, expiresAt: this.context.expiresAt}; }
}
