import {type SensitiveFieldCipher} from "../../../runtime_security/domain/repositories/runtime-field-cipher.js";
import {type RuntimeSecretFileAccess} from "../../../runtime_security/infrastructure/runtime-secret-file-access.js";
import {MlServiceHttp} from "../ml-service-http.js";
import {FileMlTenantTokenStore} from "./file-ml-tenant-token-store.js";
import {MlTenantSession} from "./ml-tenant-session.js";

/** Zugang der Runtime zum ML-Dienst: `client` für alle Anfragen, `session` für An- und Abmeldung. */
export type LocalMlService = {client: MlServiceHttp; session: MlTenantSession};

export type LocalMlServiceOptions = {
  runtimeRoot: string;
  cipher: SensitiveFieldCipher;
  secretFileAccess: RuntimeSecretFileAccess;
  /** Die Arbeitsbereichs-ID der aktiven Lizenz, sonst `null`. */
  tenantId: () => string | null;
};

export function localMlServiceFromEnvironment(options: LocalMlServiceOptions): LocalMlService | undefined {
  const url = process.env.PYTHON_INFERENCE_SIDECAR_URL?.trim();
  if (!url) return undefined;
  const session = new MlTenantSession(
    new MlServiceHttp(url),
    new FileMlTenantTokenStore(options.runtimeRoot, options.cipher, options.secretFileAccess),
    options.tenantId,
  );
  return {client: new MlServiceHttp(url, session), session};
}
