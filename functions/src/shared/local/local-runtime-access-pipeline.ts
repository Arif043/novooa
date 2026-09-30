import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {type LocalRuntimeRequestHandler} from "./local-runtime-http-server.js";
import {RuntimeLicenseMiddleware} from "./local-runtime-license-middleware.js";
import {LocalRuntimeSessionAuthMiddleware} from "./local-runtime-session-auth-middleware.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

type RuntimeApplication = LocalRuntimeRequestHandler & {
  activate(context: Awaited<ReturnType<RuntimeLicenseService["activate"]>>): Promise<void>;
};

/**
 * Zentraler API-Zugriffsschutz: Lizenz → Session → Anwendung.
 * Die Lizenz-Middleware behandelt Status, Aktivierung und Freigabe ohne Session.
 * Die Auth-Middleware lässt Login und das kopplungscodegeschützte Setup durch.
 * Healthcheck, CORS und statische Dateien bleiben Aufgabe des HTTP-Servers;
 * WebSocket-Upgrades bleiben separat durch Einmaltickets geschützt.
 */
export function createLocalRuntimeAccessPipeline(
  licenses: RuntimeLicenseService,
  sessions: Pick<LocalRuntimeSessionStore, "verifySession">,
  application: RuntimeApplication,
): LocalRuntimeRequestHandler {
  const authenticatedApplication = new LocalRuntimeSessionAuthMiddleware(sessions, application);
  return new RuntimeLicenseMiddleware(licenses, application, authenticatedApplication);
}
