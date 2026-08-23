import {GoogleAuth} from "google-auth-library";

export type AuthenticatedJsonRequest = {
  audience: string;
  url: string;
  body: object;
};

export interface AuthenticatedJsonHttpClient {
  post(request: AuthenticatedJsonRequest): Promise<unknown>;
}

type IdTokenClient = {
  request<T>(options: {
    url: string;
    method: "POST";
    data: object;
    headers: Record<string, string>;
  }): Promise<{data: T}>;
};

interface IdTokenClientFactory {
  getIdTokenClient(audience: string): Promise<IdTokenClient>;
}

export class GoogleIdTokenJsonHttpClient implements AuthenticatedJsonHttpClient {
  constructor(private readonly auth: IdTokenClientFactory = new GoogleAuth()) {}

  async post(request: AuthenticatedJsonRequest): Promise<unknown> {
    const client = await this.auth.getIdTokenClient(request.audience);
    const response = await client.request<unknown>({
      url: request.url,
      method: "POST",
      data: request.body,
      headers: {"content-type": "application/json"},
    });
    return response.data;
  }
}
