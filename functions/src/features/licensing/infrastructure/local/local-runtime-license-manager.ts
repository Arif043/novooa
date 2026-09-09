import {
  isActiveLocalRuntimeLicense,
  type LocalRuntimeLicense,
} from "../../domain/entities/local-runtime-license-lease.js";
import {localRuntimeActivationTokenFrom} from "../../domain/entities/local-runtime-activation-token.js";
import {verifiesLocalRuntimeLicense} from "../license-lease-crypto.js";
import {
  type LocalRuntimeLicenseStore,
  type StoredLocalRuntimeLicenseState,
} from "./file-local-runtime-license-store.js";
import {type LocalRuntimeLicenseGatewayClient} from "./local-runtime-license-gateway-client.js";

export type LocalRuntimeLicenseContext = Pick<
  LocalRuntimeLicense,
  "licenseId" | "workspaceId" | "expiresAt"
>;

export type LocalRuntimeLicenseStatus = {
  state: "active" | "expired" | "notActivated";
  expiresAt?: string;
};

export type LocalRuntimeLicenseActivation = {
  activationToken: string;
};

export interface LocalRuntimeLicenseService {
  restore(): Promise<LocalRuntimeLicenseContext | null>;
  activate(input: LocalRuntimeLicenseActivation): Promise<LocalRuntimeLicenseContext>;
  activeContext(): LocalRuntimeLicenseContext | null;
  status(): LocalRuntimeLicenseStatus;
}

export class GatewayLocalRuntimeLicenseService implements LocalRuntimeLicenseService {
  private state: StoredLocalRuntimeLicenseState | undefined;

  constructor(
    private readonly store: LocalRuntimeLicenseStore,
    private readonly gateway: LocalRuntimeLicenseGatewayClient,
    private readonly publicKeyPem: string,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async restore(): Promise<LocalRuntimeLicenseContext | null> {
    this.state = (await this.store.load()) ?? undefined;
    return this.activeContext();
  }

  async activate(input: LocalRuntimeLicenseActivation): Promise<LocalRuntimeLicenseContext> {
    const token = localRuntimeActivationTokenFrom(input.activationToken);
    return this.saveAndActivate({license: await this.gateway.requestLicense(token)});
  }

  activeContext(): LocalRuntimeLicenseContext | null {
    if (this.state === undefined || !this.isValid(this.state)) return null;
    const {licenseId, workspaceId, expiresAt} = this.state.license.payload;
    return {licenseId, workspaceId, expiresAt};
  }

  status(): LocalRuntimeLicenseStatus {
    const active = this.activeContext();
    if (active !== null) return {state: "active", expiresAt: active.expiresAt};
    if (this.state !== undefined) {
      return {state: "expired", expiresAt: this.state.license.payload.expiresAt};
    }
    return {state: "notActivated"};
  }

  private async saveAndActivate(
    state: StoredLocalRuntimeLicenseState,
  ): Promise<LocalRuntimeLicenseContext> {
    if (!this.isValid(state)) throw new Error("Der Lizenzschlüssel ist ungültig.");
    this.state = state;
    await this.store.save(state);
    return this.activeContext()!;
  }

  private isValid(state: StoredLocalRuntimeLicenseState): boolean {
    return verifiesLocalRuntimeLicense(state.license, this.publicKeyPem) &&
      isActiveLocalRuntimeLicense(state.license.payload, this.now());
  }
}

export class DevelopmentLocalRuntimeLicenseService implements LocalRuntimeLicenseService {
  constructor(private readonly context: LocalRuntimeLicenseContext) {}

  async restore(): Promise<LocalRuntimeLicenseContext> {
    return this.context;
  }

  async activate(): Promise<LocalRuntimeLicenseContext> {
    return this.context;
  }

  activeContext(): LocalRuntimeLicenseContext {
    return this.context;
  }

  status(): LocalRuntimeLicenseStatus {
    return {state: "active", expiresAt: this.context.expiresAt};
  }
}
