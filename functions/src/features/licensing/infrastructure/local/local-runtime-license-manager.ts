import {type RuntimeLicenseActivation} from "../../domain/entities/runtime-license-activation.js";
import {isActiveRuntimeLicense, type SignedRuntimeLicense} from "../../domain/entities/runtime-license-lease.js";
import {runtimeActivationTokenFrom} from "../../domain/entities/activation-token.js";
import {type RuntimeLicenseCheck} from "../../domain/entities/runtime-license-verification.js";
import {activationTokenProofFor, matchesActivationTokenProof} from "../activation-token-proof.js";
import {verifiesRuntimeLicense} from "../license-lease-crypto.js";
import {type RuntimeLicenseStore} from "./file-local-runtime-license-store.js";
import {type RuntimeLicenseGatewayClient} from "./local-runtime-license-gateway-client.js";

import {type RuntimeLicenseContext} from "../../domain/entities/runtime-license-context.js";
export {type RuntimeLicenseContext} from "../../domain/entities/runtime-license-context.js";
export type RuntimeLicenseStatus = {state: "active" | "expired" | "notActivated"; expiresAt?: string; name?: string;};
export type RuntimeLicenseActivationInput = {activationToken: string;};

export interface RuntimeLicenseService {
  restore(): Promise<RuntimeLicenseContext | null>;
  activate(input: RuntimeLicenseActivationInput): Promise<RuntimeLicenseContext>;
  release(): Promise<void>;
  activeContext(): RuntimeLicenseContext | null;
  signedActiveLicense(): SignedRuntimeLicense | null;
  activeActivation(): RuntimeLicenseActivation | null;
  status(): RuntimeLicenseStatus;
  /** Gehört `token` zur aktiven Lizenz? Nachweis für Ersteinrichtung und erneute Aktivierung. */
  matchesActivationToken(token: unknown): boolean;
  /**
   * Fragt das Gateway, ob die Aktivierung noch gilt, und sperrt die Runtime bei
   * `revoked`. Wirft, wenn das Gateway kein eindeutiges Urteil liefert.
   */
  verifyActivation(): Promise<RuntimeLicenseCheck>;
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
    return this.saveAndActivate({...activation, activationTokenHash: activationTokenProofFor(token)});
  }

  matchesActivationToken(token: unknown): boolean {
    const activation = this.activeActivation();
    return activation !== null && matchesActivationTokenProof(activation.activationTokenHash, token);
  }

  async release(): Promise<void> {
    if (this.state === undefined || !this.isValid(this.state)) throw new Error("Keine aktive Lizenz.");
    await this.gateway.release(this.state);
    await this.forget();
  }

  async verifyActivation(): Promise<RuntimeLicenseCheck> {
    const activation = this.activeActivation();
    if (activation === null) return "notActivated";
    const verdict = await this.gateway.verify(activation);
    // Nur sperren, wenn zwischenzeitlich nicht freigegeben oder neu aktiviert wurde.
    if (verdict === "revoked" && this.state === activation) await this.forget();
    return verdict;
  }

  private async forget(): Promise<void> {
    await this.store.clear();
    this.state = undefined;
  }

  activeContext(): RuntimeLicenseContext | null {
    if (this.state === undefined || !this.isValid(this.state)) return null;
    const {licenseId, licenseName, workspaceId, expiresAt, maxUsers} = this.state.license.payload;
    return {licenseId, licenseName, workspaceId, expiresAt, maxUsers};
  }

  signedActiveLicense(): SignedRuntimeLicense | null {
    return this.state !== undefined && this.isValid(this.state) ? this.state.license : null;
  }

  activeActivation(): RuntimeLicenseActivation | null {
    return this.state !== undefined && this.isValid(this.state) ? this.state : null;
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
