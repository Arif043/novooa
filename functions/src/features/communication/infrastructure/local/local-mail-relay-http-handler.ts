import {type SignedRuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";
import {type RuntimeMailRelayClient} from "./runtime-mail-relay-client.js";

export class LocalMailRelayHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly signedLicense: () => SignedRuntimeLicense | null,
    private readonly relay: RuntimeMailRelayClient,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    const path = pathFrom(request.url);
    if (request.method === "POST" && path === "/v1/mail-connectors/microsoft/authorization") {
      return this.beginAuthorization();
    }
    if (request.method === "GET" && path === "/v1/mail-relay/dead-letters") return this.deadLetters();
    const eventId = replayEventId(path, request.method);
    return eventId ? this.replay(eventId) : null;
  }

  private async beginAuthorization(): Promise<LocalRuntimeResponse> {
    const license = this.activeLicense();
    const authorization = await this.relay.beginMicrosoftAuthorization(license);
    return {statusCode: 200, body: authorization};
  }

  private async deadLetters(): Promise<LocalRuntimeResponse> {
    const items = await this.relay.listDeadLetters(this.activeLicense());
    return {statusCode: 200, body: {items}};
  }

  private async replay(eventId: string): Promise<LocalRuntimeResponse> {
    await this.relay.replayDeadLetter(this.activeLicense(), eventId);
    return {statusCode: 200, body: {status: "ok"}};
  }

  private activeLicense(): SignedRuntimeLicense {
    const license = this.signedLicense();
    if (license === null) throw new Error("Die lokale Runtime hat keine aktive Lizenz.");
    return license;
  }
}

function pathFrom(url: string | undefined): string {
  return (url ?? "").split("?")[0] ?? "";
}

function replayEventId(path: string, method: string | undefined): string | null {
  const match = /^\/v1\/mail-relay\/dead-letters\/([^/]+)\/replay$/.exec(path);
  return method === "POST" && match?.[1] ? decodeURIComponent(match[1]) : null;
}
