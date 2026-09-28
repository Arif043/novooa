import {type SignedRuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../../../../shared/local/local-runtime-http-server.js";
import {type RuntimeMailRelayClient} from "./runtime-mail-relay-client.js";
import {routeMatch} from "../../../../shared/local/local-runtime-route.js";

export class LocalMailRelayHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly signedLicense: () => SignedRuntimeLicense | null,
    private readonly relay: RuntimeMailRelayClient,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (routeMatch(request, "POST", "/v1/mail-connectors/microsoft/authorization")) {
      return this.beginAuthorization();
    }
    if (routeMatch(request, "GET", "/v1/mail-relay/dead-letters")) return this.deadLetters();
    const replay = routeMatch(request, "POST", "/v1/mail-relay/dead-letters/:eventId/replay");
    return replay ? this.replay(replay.params.eventId) : null;
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


