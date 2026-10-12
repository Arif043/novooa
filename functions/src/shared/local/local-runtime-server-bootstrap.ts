import {MailConnectorListCache} from "../../features/communication/infrastructure/local/mail-connector-list-cache.js";
import {type FastifyInstance, type FastifyPluginAsync} from "fastify";
import {type Server} from "node:http";
import {type RuntimeDatabase} from "../../db/database.js";
import {ActivateRuntime} from "../../features/licensing/domain/usecases/activate-runtime.js";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {RuntimeLicenseMonitor} from "../../features/licensing/infrastructure/local/runtime-license-monitor.js";
import {localMlServiceFromEnvironment, type LocalMlService} from "../../features/machine_learning/infrastructure/local/local-ml-service.js";
import {type SensitiveFieldCipher} from "../../features/runtime_security/domain/repositories/runtime-field-cipher.js";
import {type RuntimeSecretFileAccess} from "../../features/runtime_security/infrastructure/runtime-secret-file-access.js";
import {LocalRuntimeAccessCredentialStore} from "./local-runtime-access-credential-store.js";
import {LocalRuntimeApplication} from "./local-runtime-application.js";
import {type LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";
import {createLocalRuntimeHttpServer} from "./local-runtime-http-server.js";
import {registerRuntimeLicenseRoutes} from "./local-runtime-license-routes.js";
import {LocalRuntimeRealtimeConnections, RealtimeSessionGuard} from "./local-runtime-realtime-connections.js";
import {LocalRuntimeRealtimeNotifier} from "./local-runtime-realtime-notifier.js";
import {attachLocalRuntimeRealtimeServer, type LocalRuntimeRealtimeGateway} from "./local-runtime-realtime-server.js";
import {LocalRuntimeRealtimeTicketStore} from "./local-runtime-realtime-ticket-store.js";
import {webhookRoutes} from "../../features/webhooks/infrastructure/local/local-webhook-routes.js";
import {localRuntimeApi} from "./local-runtime-routes.js";
import {LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

type BootstrapOptions = {
  database: RuntimeDatabase;
  runtimeRoot: string;
  fieldCipher: SensitiveFieldCipher;
  /** Sperre für die verschlüsselten Dateien unter `credentials/`, geteilt mit dem Schlüsselwechsel. */
  secretFileAccess: RuntimeSecretFileAccess;
  licenses: RuntimeLicenseService;
  cors: LocalRuntimeCorsPolicy;
  webDirectory: string | undefined;
  port: number;
};

/** Prozessweite Bausteine, die einen Arbeitsbereichswechsel überdauern. */
type RuntimeShared = {
  sessions: LocalRuntimeSessionStore;
  notifier: LocalRuntimeRealtimeNotifier;
  tickets: LocalRuntimeRealtimeTicketStore;
  realtimeConnections: LocalRuntimeRealtimeConnections;
  mailConnectors: MailConnectorListCache;
  application: LocalRuntimeApplication;
  mlService: LocalMlService | undefined;
};

export async function bootstrapLocalRuntime(options: BootstrapOptions): Promise<{
  server: Server; application: LocalRuntimeApplication; closeHttp: () => Promise<void>;
}> {
  const shared = sharedFor(options);
  try {
    const restored = await options.licenses.restore();
    if (restored !== null) await shared.application.activate(restored);
    const http = await listenForRequests(options, shared);
    const licenseMonitor = licenseMonitorFor(options.licenses, shared.mlService);
    licenseMonitor.start();
    const realtimeGuard = realtimeGuardFor(options.licenses, shared);
    realtimeGuard.start();
    reportStarted(options.port);
    const closeHttp = async () => {
      realtimeGuard.stop();
      await licenseMonitor.stop();
      await http.close();
    };
    return {server: http.server, application: shared.application, closeHttp};
  } catch (error) {
    await shared.application.stop();
    throw error;
  }
}

function sharedFor(options: BootstrapOptions): RuntimeShared {
  const {database, runtimeRoot, fieldCipher, licenses} = options;
  const notifier = new LocalRuntimeRealtimeNotifier();
  const mailConnectors = new MailConnectorListCache();
  const mlService = localMlServiceFromEnvironment({
    runtimeRoot, cipher: fieldCipher, secretFileAccess: options.secretFileAccess,
    tenantId: () => licenses.activeContext()?.workspaceId ?? null,
  });
  const application = new LocalRuntimeApplication({
    database, runtimeRoot, fieldCipher, realtimeNotifier: notifier, mailConnectors, mlService,
    isLicenseActive: () => licenses.activeContext() !== null,
    signedLicense: () => licenses.signedActiveLicense(),
    activeLicenseActivation: () => licenses.activeActivation(),
  });
  return {
    sessions: new LocalRuntimeSessionStore(database), notifier, mailConnectors, mlService,
    tickets: new LocalRuntimeRealtimeTicketStore(), realtimeConnections: new LocalRuntimeRealtimeConnections(), application,
  };
}

async function listenForRequests(options: BootstrapOptions, shared: RuntimeShared): Promise<FastifyInstance> {
  const http = createLocalRuntimeHttpServer(runtimeRoutes(options, shared), options.webDirectory, options.cors);
  attachRealtimeLifecycle(http, realtimeGatewayFor(shared), options.cors);
  try {
    await http.listen({port: options.port, host: "0.0.0.0"});
    return http;
  } catch (error) {
    await http.close();
    throw error;
  }
}

function runtimeRoutes(options: BootstrapOptions, shared: RuntimeShared): FastifyPluginAsync {
  return async (routes) => {
    const activate = new ActivateRuntime(options.licenses, (context) => shared.application.activate(context));
    registerRuntimeLicenseRoutes(routes, options.licenses, activate, {
      credentials: new LocalRuntimeAccessCredentialStore(options.database), sessions: shared.sessions,
    });
    await routes.register(localRuntimeApi({
      database: options.database, runtimeRoot: options.runtimeRoot, fieldCipher: options.fieldCipher,
      licenses: options.licenses, sessions: shared.sessions, notifier: shared.notifier, tickets: shared.tickets,
      realtimeConnections: shared.realtimeConnections, mailConnectors: shared.mailConnectors,
      workspaceContext: () => shared.application.workspaceContext(), mlService: shared.mlService,
    }));
    // Neben der API, nicht darin: Externe Systeme haben keine Sitzung (siehe docs/features/webhooks.md).
    await routes.register(webhookRoutes, {
      licenses: options.licenses, workspaceContext: () => shared.application.workspaceContext(),
    });
  };
}

/** Tickets gibt es erst nach der Lizenzaktivierung (die Ticket-Route liegt hinter den Lizenz-Hooks). */
function realtimeGatewayFor({tickets, notifier, realtimeConnections}: RuntimeShared): LocalRuntimeRealtimeGateway {
  return {
    consumeRealtimeTicket: (ticket) => tickets.consume(ticket),
    realtimeConnected: (connection, sessionToken) => realtimeConnections.add(connection, sessionToken),
    realtimeDisconnected: (connection) => realtimeConnections.remove(connection),
    subscribeRealtime: (topic, subscriber) => notifier.subscribe(topic, subscriber),
    unsubscribeRealtime: (topic, subscriber) => notifier.unsubscribe(topic, subscriber),
  };
}

function attachRealtimeLifecycle(
  http: FastifyInstance, gateway: LocalRuntimeRealtimeGateway, cors: LocalRuntimeCorsPolicy,
): void {
  const realtime = attachLocalRuntimeRealtimeServer(http.server, gateway, cors);
  http.addHook("preClose", async () => {
    for (const client of realtime.clients) client.terminate();
    await new Promise<void>((resolve) => realtime.close(() => resolve()));
  });
}

/**
 * Vor der Aktivierung gibt es keinen team-gebundenen Logger — Lizenzereignisse gehen daher nach Stdout.
 * Fällt die Lizenz weg, meldet sich die Runtime beim ML-Dienst ab: Er gibt ihre Teammodelle und ihren Speicher frei.
 */
function licenseMonitorFor(licenses: RuntimeLicenseService, mlService: LocalMlService | undefined): RuntimeLicenseMonitor {
  return new RuntimeLicenseMonitor({
    check: () => licenses.verifyActivation(),
    report: (event, details) => console.info(JSON.stringify({event, ...details})),
    onLicenseLost: mlService === undefined ? undefined : () => mlService.session.unregister(),
  });
}

/** Schließt Realtime-Verbindungen, deren Sitzung abgelaufen ist oder deren Lizenz weggefallen ist. */
function realtimeGuardFor(licenses: RuntimeLicenseService, shared: RuntimeShared): RealtimeSessionGuard {
  return new RealtimeSessionGuard({
    connections: shared.realtimeConnections,
    isSessionActive: (token) => shared.sessions.isActive(token),
    isLicenseActive: () => licenses.activeContext() !== null,
    onFailure: (error) => console.error(JSON.stringify({
      event: "local_runtime.realtime_guard_failed", message: error instanceof Error ? error.message : String(error),
    })),
  });
}

function reportStarted(port: number): void {
  console.info(JSON.stringify({event: "local_runtime.started", port}));
}
