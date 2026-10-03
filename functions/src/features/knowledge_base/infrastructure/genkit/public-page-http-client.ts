import {lookup} from "node:dns/promises";
import {
  Agent,
  fetch,
  interceptors,
  type Dispatcher,
  type Response,
} from "undici";
import {isPublicInternetAddress} from "./public-page-url.js";

export type PageHttpResponse = {
  response: PageResponse;
  dispose: () => Promise<void>;
};

export type PageResponse = {
  status: number;
  ok: boolean;
  headers: {get(name: string): string | null};
  body: PageResponseBody | null;
};

export type PageResponseBody = {
  cancel: () => Promise<void>;
  getReader: () => PageResponseReader;
};

export type PageResponseReader = {
  cancel: () => Promise<void>;
  read: () => Promise<{done: boolean; value?: Uint8Array}>;
};

export type PageHttpRequestOptions = {
  redirect: "manual";
  signal: AbortSignal;
  headers: Record<string, string>;
};

export interface PageHttpClient {
  get(url: URL, options: PageHttpRequestOptions): Promise<PageHttpResponse>;
}

export class PublicPageHttpClient implements PageHttpClient {
  async get(url: URL, options: PageHttpRequestOptions): Promise<PageHttpResponse> {
    const dispatcher = publicDnsDispatcher();
    try {
      const response = await fetch(url, {...options, dispatcher});
      return {response: pageResponseFrom(response), dispose: () => dispatcher.close()};
    } catch (error) {
      await dispatcher.close();
      throw error;
    }
  }
}

function pageResponseFrom(response: Response): PageResponse {
  return response;
}

function publicDnsDispatcher(): Dispatcher.ComposedDispatcher {
  return new Agent().compose(interceptors.dns({
    lookup: resolvePublicAddresses,
    maxTTL: 60_000,
  }));
}

function resolvePublicAddresses(
  origin: URL,
  _options: unknown,
  callback: (error: NodeJS.ErrnoException | null, addresses: DnsAddress[]) => void,
): void {
  lookup(origin.hostname, {all: true, verbatim: true})
    .then(publicAddressesFrom)
    .then((addresses) => callback(null, addresses))
    .catch((error: unknown) => callback(dnsErrorFrom(error), []));
}

type DnsAddress = {address: string; family: 4 | 6; ttl: number};

function publicAddressesFrom(addresses: {address: string; family: number}[]): DnsAddress[] {
  if (addresses.length === 0 || addresses.some(({address}) => !isPublicInternetAddress(address))) {
    throw new Error("Nur öffentliche URLs sind erlaubt.");
  }
  return addresses.map(({address, family}) => ({
    address,
    family: family as 4 | 6,
    ttl: 60_000,
  }));
}

function dnsErrorFrom(error: unknown): NodeJS.ErrnoException {
  const message = error instanceof Error ? error.message : "URL konnte nicht aufgelöst werden.";
  return Object.assign(new Error(message), {code: "ENOTFOUND"});
}
