import {createPublicKey, verify, type KeyObject} from "node:crypto";
import {type PluginSignatureVerifier} from "../../domain/repositories/plugin-signature-verifier.js";

export class Ed25519PluginSignatureVerifier implements PluginSignatureVerifier {
  private readonly key: KeyObject;

  constructor(publicKeyPem: string) {
    this.key = createPublicKey(publicKeyPem);
  }

  verify(digest: Uint8Array, signature: Uint8Array | undefined): boolean {
    if (signature === undefined) return false;
    try {
      return verify(null, digest, this.key, signature);
    } catch {
      return false;
    }
  }
}

/** Nur für die Entwicklung (`NOVOOA_PLUGIN_ALLOW_UNSIGNED=true`): nimmt jedes Paket an. */
export class AcceptAnyPluginSignature implements PluginSignatureVerifier {
  verify(): boolean {
    return true;
  }
}

/** Ohne eingerichteten Schlüssel wird nichts installiert (fail closed). */
export class RejectAllPluginSignatures implements PluginSignatureVerifier {
  verify(): boolean {
    return false;
  }
}

/**
 * `NOVOOA_PLUGIN_PUBLIC_KEY` ist der öffentliche Ed25519-Schlüssel des Herausgebers (PEM; `\n` als Zeilenumbruch erlaubt).
 */
export function pluginSignatureVerifierFrom(environment: NodeJS.ProcessEnv = process.env): PluginSignatureVerifier {
  const pem = environment.NOVOOA_PLUGIN_PUBLIC_KEY?.trim().replace(/\\n/g, "\n");
  if (pem) return new Ed25519PluginSignatureVerifier(pem);
  return environment.NOVOOA_PLUGIN_ALLOW_UNSIGNED === "true" ? new AcceptAnyPluginSignature() : new RejectAllPluginSignatures();
}
