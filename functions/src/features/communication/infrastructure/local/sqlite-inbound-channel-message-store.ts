import {eq} from "drizzle-orm";
import {type RuntimeExecutor} from "../../../../db/database.js";
import {inboundChannelEvents} from "../../../../db/schema.js";
import {type EmailReceivedEvent} from "../../domain/entities/channel-message-event.js";

export class SQLiteInboundChannelMessageStore {
  constructor(private readonly database: RuntimeExecutor) {}

  async store(input: {
    teamId: string;
    eventId: string;
    connectorId: string;
    event: EmailReceivedEvent;
  }): Promise<boolean> {
    return this.database.transaction(async (tx) => {
      const existing = (await tx.select({event_id: inboundChannelEvents.event_id}).from(inboundChannelEvents).where(eq(inboundChannelEvents.event_id, input.eventId)).get()) ?? null;
      if (existing !== null) return false;
      await tx.insert(inboundChannelEvents).values({event_id: input.eventId, team_id: input.teamId,
        connector_id: input.connectorId, provider: input.event.provider, provider_message_id: input.event.providerMessageId,
        event_json: JSON.stringify(input.event), received_at: input.event.receivedAt});
      return true;
    });
  }
}
