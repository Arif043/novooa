import {
  isActiveRuntimeLicense,
  type RuntimeLicense,
  type SignedRuntimeLicense,
} from "../../domain/entities/runtime-license-lease.js";
import {runtimeActivationTokenFrom} from "../../domain/entities/activation-token.js";
import {verifiesRuntimeLicense} from "../license-lease-crypto.js";
import {
  type RuntimeLicenseStore,
  type StoredRuntimeLicenseState,
} from "./file-local-runtime-license-store.js";
import {type RuntimeLicenseGatewayClient} from "./local-runtime-license-gateway-client.js";

export type RuntimeLicenseContext = Pick<
  RuntimeLicense,
  "licenseId" | "workspaceId" | "expiresAt"
>;

export type RuntimeLicenseStatus = {
  state: "active" | "expired" | "notActivated";
  expiresAt?: string;
};

export type RuntimeLicenseActivation = {
  activationToken: string;
};

export interface RuntimeLicenseService {
  restore(): Promise<RuntimeLicenseContext | null>;
  activate(input: RuntimeLicenseActivation): Promise<RuntimeLicenseContext>;
  activeContext(): RuntimeLicenseContext | null;
  signedActiveLicense(): SignedRuntimeLicense | null;
  status(): RuntimeLicenseStatus;
}

export class GatewayRuntimeLicenseService implements RuntimeLicenseService {
  private state: StoredRuntimeLicenseState | undefined;

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

  async activate(input: RuntimeLicenseActivation): Promise<RuntimeLicenseContext> {
    const token = runtimeActivationTokenFrom(input.activationToken);
    return this.saveAndActivate({license: await this.gateway.requestLicense(token)});
  }

  activeContext(): RuntimeLicenseContext | null {
    if (this.state === undefined || !this.isValid(this.state)) return null;
    const {licenseId, workspaceId, expiresAt} = this.state.license.payload;
    return {licenseId, workspaceId, expiresAt};
  }

  signedActiveLicense(): SignedRuntimeLicense | null {
    return this.state !== undefined && this.isValid(this.state)
      ? this.state.license
      : null;
  }

  status(): RuntimeLicenseStatus {
    const active = this.activeContext();
    if (active !== null) return {state: "active", expiresAt: active.expiresAt};
    if (this.state !== undefined) {
      return {state: "expired", expiresAt: this.state.license.payload.expiresAt};
    }
    return {state: "notActivated"};
  }

  private async saveAndActivate(
    state: StoredRuntimeLicenseState,
  ): Promise<RuntimeLicenseContext> {
    if (!this.isValid(state)) throw new Error("Der Lizenzschlüssel ist ungültig.");
    this.state = state;
    await this.store.save(state);
    return this.activeContext()!;
  }

  private isValid(state: StoredRuntimeLicenseState): boolean {
    return verifiesRuntimeLicense(state.license, this.publicKeyPem) &&
      isActiveRuntimeLicense(state.license.payload, this.now());
  }
}

export class DevelopmentRuntimeLicenseService implements RuntimeLicenseService {
  constructor(private readonly context: RuntimeLicenseContext) {}

  async restore(): Promise<RuntimeLicenseContext> {
    return this.context;
  }

  async activate(): Promise<RuntimeLicenseContext> {
    return this.context;
  }

  activeContext(): RuntimeLicenseContext {
    return this.context;
  }

  signedActiveLicense(): SignedRuntimeLicense | null {
    return null;
  }

  status(): RuntimeLicenseStatus {
    return {state: "active", expiresAt: this.context.expiresAt};
  }
}
