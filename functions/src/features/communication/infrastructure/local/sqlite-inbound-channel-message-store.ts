import {type EmailReceivedEvent} from
  "../../domain/entities/channel-message-event.js";
import {type LocalSqlDatabase, type SqlRow} from
  "../../../../shared/local/local-sql-database.js";

type ExistingRow = SqlRow & {event_id: string};

export class SQLiteInboundChannelMessageStore {
  constructor(private readonly database: LocalSqlDatabase) {}

  async store(input: {
    teamId: string;
    eventId: string;
    connectorId: string;
    event: EmailReceivedEvent;
  }): Promise<boolean> {
    return this.database.transaction(async () => {
      const existing = await this.database.get<ExistingRow>(byEventIdSql(), [input.eventId]);
      if (existing !== null) return false;
      await this.database.run(insertSql(), valuesFrom(input));
      return true;
    });
  }
}

function valuesFrom(input: {
  teamId: string;
  eventId: string;
  connectorId: string;
  event: EmailReceivedEvent;
}) {
  return [input.eventId, input.teamId, input.connectorId, input.event.provider,
    input.event.providerMessageId, JSON.stringify(input.event), input.event.receivedAt] as const;
}

function byEventIdSql(): string {
  return "SELECT event_id FROM inbound_channel_events WHERE event_id = ?";
}

function insertSql(): string {
  return `INSERT INTO inbound_channel_events (
    event_id, team_id, connector_id, provider, provider_message_id, event_json, received_at
  ) VALUES (?, ?, ?, ?, ?, ?, ?)`;
}
