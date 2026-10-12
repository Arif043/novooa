import {type MlServiceCredentials, type MlServiceHttp} from "../ml-service-http.js";
import {isRecord, sidecarErrorMessage} from "../python-inference-sidecar-codec.js";

export type StoredMlTenantToken = {tenantId: string; token: string};

export interface MlTenantTokenStore {
  load(): Promise<StoredMlTenantToken | null>;
  save(token: StoredMlTenantToken): Promise<void>;
  clear(): Promise<void>;
}

export class MlTenantIdTakenError extends Error {
  constructor() {
    super("Diese Runtime ist beim ML-Dienst schon unter ihrer Kennung angemeldet, das Token fehlt aber. "
      + "Der Betreiber muss die Kennung freigeben (python -m novooa_ml.tenants delete <kennung>).");
  }
}

/**
 * Die Anmeldung der Runtime beim zentralen ML-Dienst ihres Servers. Die Kennung ist die Arbeitsbereichs-ID
 * der Lizenz; das Token vergibt der ML-Dienst bei der ersten Anfrage, die Runtime speichert es verschlüsselt.
 * Ohne aktive Lizenz gibt es keine Anmeldung; fällt die Lizenz weg, meldet sich die Runtime ab.
 */
export class MlTenantSession implements MlServiceCredentials {
  private current: Promise<StoredMlTenantToken> | undefined;

  constructor(
    private readonly registration: MlServiceHttp,
    private readonly store: MlTenantTokenStore,
    private readonly tenantId: () => string | null,
  ) {}

  async authorization(): Promise<string> {
    return `Bearer ${(await this.token()).token}`;
  }

  async renew(rejectedAuthorization: string): Promise<void> {
    const current = await this.current?.catch(() => undefined);
    // Mehrere Anfragen können mit demselben alten Token scheitern; nur die erste meldet neu an.
    if (current !== undefined && `Bearer ${current.token}` !== rejectedAuthorization) return;
    this.current = undefined;
    await this.store.clear();
    await this.token();
  }

  async unregister(): Promise<void> {
    this.current = undefined;
    const stored = await this.store.load();
    if (stored === null) return;
    await this.release(stored);
    await this.store.clear();
  }

  private async token(): Promise<StoredMlTenantToken> {
    const tenantId = this.tenantId();
    if (tenantId === null) throw new Error("Ohne aktive Lizenz ist der ML-Dienst nicht verfügbar.");
    const token = await (this.current ??= this.loadOrRegister(tenantId).catch((error: unknown) => {
      this.current = undefined;
      throw error;
    }));
    if (token.tenantId === tenantId) return token;
    this.current = undefined;
    return this.token();
  }

  private async loadOrRegister(tenantId: string): Promise<StoredMlTenantToken> {
    const stored = await this.store.load();
    if (stored?.tenantId === tenantId) return stored;
    // Lizenz mit anderem Arbeitsbereich: die alte Anmeldung freigeben, bevor die neue entsteht.
    if (stored !== null) await this.release(stored);
    const token = {tenantId, token: await this.register(tenantId)};
    await this.store.save(token);
    return token;
  }

  private async register(tenantId: string): Promise<string> {
    const response = await this.registration.send({
      method: "POST", path: "/v1/tenants", headers: {"content-type": "application/json"},
      body: () => JSON.stringify({tenantId}),
    });
    if (response.status === 409) throw new MlTenantIdTakenError();
    if (response.status >= 400) throw new Error(sidecarErrorMessage(response.payload));
    if (!isRecord(response.payload) || typeof response.payload.token !== "string") {
      throw new Error("Der ML-Dienst lieferte kein Token.");
    }
    return response.payload.token;
  }

  /** `401` heißt: schon abgemeldet (z. B. vom Betreiber). Beides ist hier in Ordnung. */
  private async release(stored: StoredMlTenantToken): Promise<void> {
    const response = await this.registration.send({
      method: "DELETE", path: "/v1/tenants/self", headers: {authorization: `Bearer ${stored.token}`},
    });
    if (response.status >= 400 && response.status !== 401) throw new Error(sidecarErrorMessage(response.payload));
  }
}
