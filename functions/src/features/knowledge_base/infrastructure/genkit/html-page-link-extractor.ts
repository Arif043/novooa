import {load} from "cheerio";

export type ExtractedPageLink = {
  url: string;
  text: string;
};

type LinkExtraction = {
  links: ExtractedPageLink[];
  truncated: boolean;
};

const maximumLinks = 100;
const maximumLinkTextLength = 200;

export function extractPageLinks(
  html: string,
  pageUrl: string,
  includeExternal: boolean,
): LinkExtraction {
  const baseUrl = new URL(pageUrl);
  const linksByUrl = new Map<string, ExtractedPageLink>();
  const document = load(html);
  for (const anchor of document("a[href]").toArray()) {
    addLink(linksByUrl, linkFrom(document(anchor).attr("href"), document(anchor).text(), baseUrl, includeExternal));
  }
  const links = [...linksByUrl.values()];
  return {links: links.slice(0, maximumLinks), truncated: links.length > maximumLinks};
}

function addLink(
  linksByUrl: Map<string, ExtractedPageLink>,
  link: ExtractedPageLink | null,
): void {
  if (!link || linksByUrl.has(link.url)) return;
  linksByUrl.set(link.url, link);
}

function linkFrom(
  href: string | undefined,
  text: string,
  baseUrl: URL,
  includeExternal: boolean,
): ExtractedPageLink | null {
  if (!href || href.trim().startsWith("#")) return null;
  const targetUrl = targetUrlFrom(href, baseUrl);
  if (!targetUrl || targetUrl.href === baseUrl.href) return null;
  if (!includeExternal && targetUrl.origin !== baseUrl.origin) return null;
  return {url: targetUrl.href, text: displayText(text, targetUrl)};
}

function targetUrlFrom(href: string, baseUrl: URL): URL | null {
  try {
    const targetUrl = new URL(href.trim(), baseUrl);
    if (targetUrl.protocol !== "http:" && targetUrl.protocol !== "https:") return null;
    targetUrl.hash = "";
    return targetUrl;
  } catch (_) {
    return null;
  }
}

function displayText(text: string, targetUrl: URL): string {
  const normalizedText = text.replace(/\s+/g, " ").trim();
  if (normalizedText.length > 0) return normalizedText.slice(0, maximumLinkTextLength);
  return targetUrl.href;
}
