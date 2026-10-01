import {type FastifyInstance, type FastifyPluginAsync} from "fastify";
import {type Server} from "node:http";
import {type RuntimeDatabase} from "../../db/database.js";
import {ActivateRuntime} from "../../features/licensing/domain/usecases/activate-runtime.js";
import {type RuntimeLicenseService} from "../../features/licensing/infrastructure/local/local-runtime-license-manager.js";
import {type SensitiveFieldCipher} from "../../features/runtime_security/domain/repositories/runtime-field-cipher.js";
import {LocalRuntimeApplication} from "./local-runtime-application.js";
import {type LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";
import {createLocalRuntimeHttpServer} from "./local-runtime-http-server.js";
import {registerRuntimeLicenseRoutes} from "./local-runtime-license-routes.js";
import {LocalRuntimeRealtimeNotifier} from "./local-runtime-realtime-notifier.js";
import {attachLocalRuntimeRealtimeServer, type LocalRuntimeRealtimeGateway} from "./local-runtime-realtime-server.js";
import {LocalRuntimeRealtimeTicketStore} from "./local-runtime-realtime-ticket-store.js";
import {localRuntimeApi} from "./local-runtime-routes.js";
import {LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

type BootstrapOptions = {
  database: RuntimeDatabase;
  runtimeRoot: string;
  fieldCipher: SensitiveFieldCipher;
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
  application: LocalRuntimeApplication;
};

export async function bootstrapLocalRuntime(options: BootstrapOptions): Promise<{
  server: Server; application: LocalRuntimeApplication; closeHttp: () => Promise<void>;
}> {
  const shared = sharedFor(options);
  try {
    const restored = await options.licenses.restore();
    if (restored !== null) await shared.application.activate(restored);
    const http = await listenForRequests(options, shared);
    reportStarted(options.port);
    return {server: http.server, application: shared.application, closeHttp: () => http.close()};
  } catch (error) {
    await shared.application.stop();
    throw error;
  }
}

function sharedFor(options: BootstrapOptions): RuntimeShared {
  const {database, runtimeRoot, fieldCipher, licenses} = options;
  const notifier = new LocalRuntimeRealtimeNotifier();
  const application = new LocalRuntimeApplication({
    database, runtimeRoot, fieldCipher, realtimeNotifier: notifier,
    isLicenseActive: () => licenses.activeContext() !== null,
    signedLicense: () => licenses.signedActiveLicense(),
    activeLicenseActivation: () => licenses.activeActivation(),
  });
  return {sessions: new LocalRuntimeSessionStore(database), notifier, tickets: new LocalRuntimeRealtimeTicketStore(), application};
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
    registerRuntimeLicenseRoutes(routes, options.licenses, activate);
    await routes.register(localRuntimeApi({
      database: options.database, runtimeRoot: options.runtimeRoot, fieldCipher: options.fieldCipher,
      licenses: options.licenses, sessions: shared.sessions, notifier: shared.notifier, tickets: shared.tickets,
      workspaceContext: () => shared.application.workspaceContext(),
    }));
  };
}

/** Tickets gibt es erst nach der Lizenzaktivierung (die Ticket-Route liegt hinter den Lizenz-Hooks). */
function realtimeGatewayFor({tickets, notifier}: RuntimeShared): LocalRuntimeRealtimeGateway {
  return {
    consumeRealtimeTicket: (ticket) => tickets.consume(ticket),
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

function reportStarted(port: number): void {
  console.info(JSON.stringify({event: "local_runtime.started", port}));
}
