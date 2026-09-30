import {CurrentRuntimeFieldCipher} from "../../features/runtime_security/infrastructure/current-runtime-field-cipher.js";
import {RuntimeSecretFileAccess} from "../../features/runtime_security/infrastructure/runtime-secret-file-access.js";
import {FileRuntimeKeyRepository} from "../../features/runtime_security/infrastructure/file-runtime-key-repository.js";
import {LocalRuntimeSecretRotationStore} from "../../features/runtime_security/infrastructure/local-runtime-secret-rotation-store.js";
import {RotateRuntimeMasterKey} from "../../features/runtime_security/domain/usecases/rotate-runtime-master-key.js";
import {RotateRuntimeMasterKeyIfDue} from "../../features/runtime_security/domain/usecases/rotate-runtime-master-key-if-due.js";
import {AutomaticRuntimeKeyRotation, type RotationTimer} from "../../features/runtime_security/infrastructure/automatic-runtime-key-rotation.js";
import {type LocalSqlDatabase} from "./local-sql-database.js";

export class LocalRuntimeSecurity {
  readonly cipher: CurrentRuntimeFieldCipher;
  readonly licenseAccess = new RuntimeSecretFileAccess();
  private worker: AutomaticRuntimeKeyRotation | undefined;

  constructor(
    private readonly keyFile: string,
    keyring: string,
    private readonly database: LocalSqlDatabase,
    private readonly runtimeRoot: string,
    private readonly now: () => Date = () => new Date(),
  ) {
    this.cipher = new CurrentRuntimeFieldCipher(keyring);
  }

  start(): void {
    if (this.worker) return;
    const keys = new FileRuntimeKeyRepository(this.keyFile, (keyring) => this.cipher.update(keyring), this.now);
    const secrets = new LocalRuntimeSecretRotationStore(this.database, this.runtimeRoot, this.licenseAccess);
    const workflow = new RotateRuntimeMasterKeyIfDue(keys, new RotateRuntimeMasterKey(keys, secrets), this.now);
    this.worker = new AutomaticRuntimeKeyRotation(workflow, scheduleRotation, rotationLog, this.now);
    this.worker.start();
  }

  async stop(): Promise<void> {
    await this.worker?.stop();
  }
}

function scheduleRotation(callback: () => void, delayMs: number): RotationTimer {
  const timer = setTimeout(callback, delayMs);
  timer.unref();
  return {cancel: () => clearTimeout(timer)};
}

function rotationLog(event: string, details: Record<string, unknown>): void {
  const line = JSON.stringify({event, ...details});
  if (event.endsWith("_failed")) console.error(line);
  else console.info(line);
}
