CREATE TABLE IF NOT EXISTS inbound_channel_events (
  event_id TEXT PRIMARY KEY,
  team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  connector_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  provider_message_id TEXT NOT NULL,
  event_json TEXT NOT NULL,
  received_at TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (team_id, provider, provider_message_id)
);

CREATE INDEX IF NOT EXISTS idx_inbound_channel_events_team_received
  ON inbound_channel_events(team_id, received_at DESC);
