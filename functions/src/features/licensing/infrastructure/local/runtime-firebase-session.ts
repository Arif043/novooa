import {deleteApp, initializeApp, type FirebaseApp} from "firebase/app";
import {
  inMemoryPersistence,
  initializeAuth,
  signInWithCustomToken,
  type Auth,
} from "firebase/auth";
import {doc, getFirestore, onSnapshot, type Firestore, type Unsubscribe} from "firebase/firestore";
import {type RuntimeLicenseActivation} from "../../domain/entities/runtime-license-activation.js";

export type RuntimeFirebaseConfiguration = {
  apiKey: string;
  projectId: string;
  tokenEndpoint: string;
};

export class RuntimeFirebaseSession {
  private app: FirebaseApp | undefined;
  private auth: Auth | undefined;
  private database: Firestore | undefined;
  private wakeupUnsubscribe: Unsubscribe | undefined;

  constructor(private readonly configuration: RuntimeFirebaseConfiguration) {}

  async start(activation: RuntimeLicenseActivation): Promise<void> {
    await this.stop();
    this.app = initializeApp({
      apiKey: this.configuration.apiKey,
      projectId: this.configuration.projectId,
    }, `local-runtime-${activation.license.payload.licenseId}`);
    this.auth = initializeAuth(this.app, {persistence: inMemoryPersistence});
    this.database = getFirestore(this.app);
    await signInWithCustomToken(this.auth, await this.customTokenFor(activation));
  }

  listenForWakeups(
    licenseId: string,
    onWakeup: () => void,
    onFailure: (error: unknown) => void,
  ): void {
    if (this.database === undefined) throw new Error("Die Firebase-Sitzung wurde nicht gestartet.");
    this.wakeupUnsubscribe?.();
    this.wakeupUnsubscribe = onSnapshot(
      doc(this.database, "localRuntimeWakeups", licenseId),
      () => onWakeup(),
      onFailure,
    );
  }

  async stop(): Promise<void> {
    this.wakeupUnsubscribe?.();
    this.wakeupUnsubscribe = undefined;
    this.auth = undefined;
    this.database = undefined;
    if (this.app !== undefined) await deleteApp(this.app);
    this.app = undefined;
  }

  private async customTokenFor(activation: RuntimeLicenseActivation): Promise<string> {
    const response = await fetch(this.configuration.tokenEndpoint, {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({license: activation.license, activationSecret: activation.activationSecret}),
      signal: AbortSignal.timeout(10_000),
    });
    if (!response.ok) throw new Error("Die Firebase-Anmeldung der lokalen Runtime wurde abgelehnt.");
    const body = await response.json();
    if (body === null || typeof body !== "object" || Array.isArray(body) ||
      typeof (body as Record<string, unknown>).token !== "string") {
      throw new Error("Die Firebase-Anmeldung der lokalen Runtime ist ungültig.");
    }
    return (body as {token: string}).token;
  }
}

export function runtimeFirebaseConfigurationFromEnvironment(
  environment: NodeJS.ProcessEnv = process.env,
): RuntimeFirebaseConfiguration | undefined {
  const apiKey = environment.LOCAL_RUNTIME_FIREBASE_API_KEY?.trim();
  const projectId = environment.LOCAL_RUNTIME_FIREBASE_PROJECT_ID?.trim();
  const tokenEndpoint = environment.LOCAL_RUNTIME_FIREBASE_TOKEN_URL?.trim();
  if (!apiKey && !projectId && !tokenEndpoint) return undefined;
  if (!apiKey || !projectId || !tokenEndpoint) {
    throw new Error("Die Firebase-Konfiguration der lokalen Runtime ist unvollständig.");
  }
  if (!tokenEndpoint.startsWith("https://")) {
    throw new Error("Der Firebase-Token-Gateway muss HTTPS verwenden.");
  }
  return {apiKey, projectId, tokenEndpoint};
}
