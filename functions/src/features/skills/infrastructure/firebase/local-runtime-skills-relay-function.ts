import {defineSecret, defineString} from "firebase-functions/params";
import {onRequest} from "firebase-functions/v2/https";
import {type Response} from "express";
import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {FirebaseRuntimeRelayLicenseVerifier} from "../../../licensing/infrastructure/firebase/firebase-runtime-relay-license-verifier.js";
import {localRuntimeLicenseSigningKey} from "../../../licensing/infrastructure/firebase/local-runtime-license-signing-key.js";
import {logException} from "../../../../shared/logging/logger.js";
import {SkillRelayRateLimitedError, SkillRelayRequestError} from "../../domain/entities/skill-relay-request.js";
import {TokenBucketRateLimiter} from "../../domain/usecases/token-bucket-rate-limiter.js";
import {FirestoreBucketStateStore} from "./firestore-bucket-state-store.js";
import {RemoteConfigBucketSettings} from "./remote-config-bucket-settings.js";
import {RelaySkillsCatalogRequest} from "../../domain/usecases/relay-skills-catalog-request.js";
import {HttpSkillsCatalogUpstream} from "./http-skills-catalog-upstream.js";

const skillsProxyUrl = defineString("SKILLS_PROXY_URL");
const skillsProxyHmacKey = defineSecret("SKILLS_PROXY_HMAC_KEY");

const relay = new RelaySkillsCatalogRequest(
  new FirebaseRuntimeRelayLicenseVerifier(),
  new TokenBucketRateLimiter(new FirestoreBucketStateStore(), new RemoteConfigBucketSettings()),
  new HttpSkillsCatalogUpstream(() => skillsProxyUrl.value(), () => skillsProxyHmacKey.value()),
);

/**
 * Katalog-Relay für lokale Runtimes: prüft die signierte Lizenz und die Anfrage, begrenzt je Lizenz per Token Bucket
 * (Werte aus Firebase Remote Config) und reicht lesende skills.sh-Abfragen an den Vercel-Proxy weiter (HMAC zwischen
 * den Servern). Status, `Retry-After` und `X-RateLimit-*` kommen unverändert
 * zurück, damit der Client der Runtime das Limit selbst einhalten kann.
 */
export const localRuntimeSkillsRelay = onRequest(
  {cors: false, invoker: "public", secrets: [localRuntimeLicenseSigningKey, skillsProxyHmacKey]},
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({error: "method_not_allowed", message: "Methode nicht erlaubt."});
      return;
    }
    try {
      const input = record(request.body);
      const upstream = await relay.execute(licenseFrom(input.license), input.path, input.query);
      for (const [name, value] of Object.entries(upstream.headers)) response.setHeader(name, value);
      response.status(upstream.status).send(upstream.body);
    } catch (error) {
      reject(response, error);
    }
  },
);

function reject(response: Response, error: unknown): void {
  if (error instanceof SkillRelayRateLimitedError) {
    response.setHeader("retry-after", String(error.retryAfterSeconds));
    response.status(429).json({error: "rate_limited", message: error.message});
    return;
  }
  if (error instanceof SkillRelayRequestError) {
    response.status(400).json({error: "invalid_request", message: error.message});
    return;
  }
  if (error instanceof TypeError || (error as Error | null)?.name === "TimeoutError") {
    logException("local_runtime_skills_relay.upstream_failed", error);
    response.status(503).json({error: "upstream_unavailable", message: "Der Skill-Katalog ist nicht erreichbar."});
    return;
  }
  logException("local_runtime_skills_relay.rejected", error);
  response.status(401).json({error: "unauthorized", message: "Die Relay-Anfrage wurde abgelehnt."});
}

function licenseFrom(value: unknown): SignedRuntimeLicense {
  const signed = record(value);
  const payload = record(signed.payload);
  return {
    signature: text(signed.signature, "signature", 4096),
    payload: {
      licenseId: text(payload.licenseId, "licenseId", 200),
      licenseName: text(payload.licenseName, "licenseName", 200),
      activationId: text(payload.activationId, "activationId", 200),
      workspaceId: text(payload.workspaceId, "workspaceId", 200),
      issuedAt: text(payload.issuedAt, "issuedAt", 80),
      expiresAt: text(payload.expiresAt, "expiresAt", 80),
    },
  };
}

function record(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) return value as Record<string, unknown>;
  throw new Error("Ungültige Relay-Anfrage.");
}

function text(value: unknown, name: string, max: number): string {
  if (typeof value !== "string" || value.trim().length === 0 || value.length > max) throw new Error(`${name} ist ungültig.`);
  return value.trim();
}
