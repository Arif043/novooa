import {type Connection, type ConnectionInput} from "../entities/connection.js";

export interface ConnectionStore {
  list(teamId: string): Promise<Connection[]>;
  find(teamId: string, connectionId: string): Promise<Connection | undefined>;
  create(teamId: string, input: ConnectionInput, secret: string): Promise<Connection>;
  /** Ohne `secret` bleibt das gespeicherte erhalten; bei neuer Anmeldeart ist eines Pflicht. Wirft `ConnectionNotFoundError`. */
  update(teamId: string, connectionId: string, input: ConnectionInput, secret?: string): Promise<Connection>;
  delete(teamId: string, connectionId: string): Promise<void>;
  /** Nur für `ConnectionAuthorizer`; wirft `ConnectionNotFoundError`. */
  loadSecret(teamId: string, connectionId: string): Promise<string>;
}
