import {onRequest} from "firebase-functions/v2/https";
import {type Response} from "express";
import {FirebaseRuntimeRelayLicenseVerifier} from "../../../licensing/infrastructure/firebase/firebase-runtime-relay-license-verifier.js";
import {localRuntimeLicenseSigningKey} from "../../../licensing/infrastructure/firebase/local-runtime-license-signing-key.js";
import {record, signedLicenseFromRequest} from "../../../licensing/infrastructure/firebase/relay-license-request.js";
import {SkillRelayRateLimitedError} from "../../../skills/domain/entities/skill-relay-request.js";
import {TokenBucketRateLimiter} from "../../../skills/domain/usecases/token-bucket-rate-limiter.js";
import {FirestoreBucketStateStore} from "../../../skills/infrastructure/firebase/firestore-bucket-state-store.js";
import {RemoteConfigBucketSettings} from "../../../skills/infrastructure/firebase/remote-config-bucket-settings.js";
import {logException} from "../../../../shared/logging/logger.js";
import {PluginCatalogError} from "../../domain/entities/plugin-catalog.js";
import {RelayPluginCatalogRequest} from "../../domain/usecases/relay-plugin-catalog-request.js";
import {FirebasePluginCatalog} from "./firebase-plugin-catalog.js";

const relay = new RelayPluginCatalogRequest(
  new FirebaseRuntimeRelayLicenseVerifier(),
  new TokenBucketRateLimiter(new FirestoreBucketStateStore(), new RemoteConfigBucketSettings()),
  new FirebasePluginCatalog(),
);

/**
 * Plugin-Katalog für lokale Runtimes. Die Runtime weist sich mit ihrer signierten Lizenz aus; `action: "list"` liefert
 * den Katalog als JSON, `action: "download"` das ZIP-Paket eines Plugins. Installiert wird erst in der Runtime, nach
 * Prüfung der Herausgeber-Signatur.
 */
export const localRuntimePluginsRelay = onRequest(
  {cors: false, invoker: "public", secrets: [localRuntimeLicenseSigningKey]},
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).json({error: "method_not_allowed", message: "Methode nicht erlaubt."});
      return;
    }
    try {
      const input = record(request.body);
      const license = signedLicenseFromRequest(input.license);
      if (input.action === "list") {
        response.status(200).json({items: await relay.list(license)});
      } else if (input.action === "download") {
        const bytes = await relay.download(license, input.id, input.version);
        response.status(200).setHeader("content-type", "application/zip").send(Buffer.from(bytes));
      } else {
        response.status(400).json({error: "invalid_request", message: "Unbekannte Aktion."});
      }
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
  if (error instanceof PluginCatalogError) {
    const status = error.kind === "not_found" ? 404 : 400;
    response.status(status).json({error: error.kind, message: error.message});
    return;
  }
  logException("local_runtime_plugins_relay.rejected", error);
  response.status(401).json({error: "unauthorized", message: "Die Relay-Anfrage wurde abgelehnt."});
}
