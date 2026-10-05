import {ConnectionNotFoundError} from "../../domain/entities/connection.js";
import {type AuthorizedConnection, type ConnectionAuthorizer} from "../../domain/repositories/connection-authorizer.js";
import {type ConnectionStore} from "../../domain/repositories/connection-store.js";
import {type OAuthTokenProvider} from "./oauth-token-provider.js";

export class StoredConnectionAuthorizer implements ConnectionAuthorizer {
  constructor(private readonly store: ConnectionStore, private readonly tokens: OAuthTokenProvider) {}

  async authorize(teamId: string, connectionId: string): Promise<AuthorizedConnection> {
    const connection = await this.store.find(teamId, connectionId);
    if (connection === undefined) throw new ConnectionNotFoundError(connectionId);
    const secret = await this.store.loadSecret(teamId, connectionId);
    const auth = connection.auth;
    switch (auth.kind) {
    case "apiKey":
      return {baseUrl: connection.baseUrl, headers: {[auth.headerName.toLowerCase()]: secret}};
    case "bearer":
      return {baseUrl: connection.baseUrl, headers: {authorization: `Bearer ${secret}`}};
    case "oauthClientCredentials":
      return {baseUrl: connection.baseUrl, headers: {authorization: `Bearer ${await this.tokens.token(connection, secret)}`}};
    }
  }
}
