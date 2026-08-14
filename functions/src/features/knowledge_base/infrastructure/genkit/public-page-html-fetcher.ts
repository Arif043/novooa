import {
  type PageHttpClient,
  type PageHttpRequestOptions,
  type PageResponse,
  type PageResponseReader,
} from "./public-page-http-client.js";
import {pageUrlFrom} from "./public-page-url.js";

export type PublicPageHtml = {
  requestedUrl: string;
  responseUrl: string;
  html: string;
};

const maximumRedirects = 3;
const maximumHtmlBytes = 1_000_000;
const requestTimeout = 10_000;

export class PublicPageHtmlFetcher {
  constructor(private readonly client: PageHttpClient) {}

  async fetchPage(rawUrl: string): Promise<PublicPageHtml> {
    const requestedUrl = pageUrlFrom(rawUrl);
    return this.fetchAt(requestedUrl, requestedUrl.href, 0);
  }

  private async fetchAt(
    url: URL,
    requestedUrl: string,
    redirectCount: number,
  ): Promise<PublicPageHtml> {
    const connection = await this.client.get(url, requestOptions());
    try {
      if (isRedirect(connection.response.status)) {
        return this.followRedirect(connection.response, url, requestedUrl, redirectCount);
      }
      return pageFromResponse(connection.response, requestedUrl, url.href);
    } finally {
      await connection.dispose();
    }
  }

  private async followRedirect(
    response: PageResponse,
    currentUrl: URL,
    requestedUrl: string,
    redirectCount: number,
  ): Promise<PublicPageHtml> {
    await response.body?.cancel();
    if (redirectCount >= maximumRedirects) throw new Error("Zu viele Weiterleitungen.");
    const targetUrl = redirectTarget(response, currentUrl);
    return this.fetchAt(targetUrl, requestedUrl, redirectCount + 1);
  }
}

function requestOptions(): PageHttpRequestOptions {
  return {
    redirect: "manual",
    signal: AbortSignal.timeout(requestTimeout),
    headers: {Accept: "text/html,application/xhtml+xml"},
  };
}

function isRedirect(status: number): boolean {
  return status === 301 || status === 302 || status === 303 || status === 307 || status === 308;
}

function redirectTarget(response: PageResponse, currentUrl: URL): URL {
  const location = response.headers.get("location");
  if (!location) throw new Error("Weiterleitung ohne Ziel.");
  return pageUrlFrom(new URL(location, currentUrl).href);
}

async function pageFromResponse(
  response: PageResponse,
  requestedUrl: string,
  responseUrl: string,
): Promise<PublicPageHtml> {
  assertHtmlResponse(response);
  return {requestedUrl, responseUrl, html: await responseTextWithinLimit(response)};
}

function assertHtmlResponse(response: PageResponse): void {
  if (!response.ok) throw new Error(`Abruf fehlgeschlagen (${response.status}).`);
  const contentType = response.headers.get("content-type")?.toLowerCase() ?? "";
  if (!contentType.includes("text/html") && !contentType.includes("application/xhtml+xml")) {
    throw new Error("Die URL liefert keine HTML-Seite.");
  }
  const contentLength = Number(response.headers.get("content-length") ?? "0");
  if (Number.isFinite(contentLength) && contentLength > maximumHtmlBytes) throw new Error("Die HTML-Seite ist zu groß.");
}

async function responseTextWithinLimit(response: PageResponse): Promise<string> {
  const reader = response.body?.getReader();
  if (!reader) throw new Error("Die HTML-Seite enthält keinen lesbaren Inhalt.");
  const chunks: Uint8Array[] = [];
  let byteCount = 0;
  while (true) {
    const {done, value} = await reader.read();
    if (done) return textFromChunks(chunks, byteCount);
    if (!value) throw new Error("Die HTML-Seite enthält keinen lesbaren Inhalt.");
    byteCount += value.byteLength;
    if (byteCount > maximumHtmlBytes) return tooLarge(reader);
    chunks.push(value);
  }
}

function textFromChunks(chunks: Uint8Array[], byteCount: number): string {
  const content = new Uint8Array(byteCount);
  let offset = 0;
  for (const chunk of chunks) {
    content.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return new TextDecoder().decode(content);
}

async function tooLarge(reader: PageResponseReader): Promise<never> {
  await reader.cancel();
  throw new Error("Die HTML-Seite ist zu groß.");
}
