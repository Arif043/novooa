const urlPattern = /(?:https?:\/\/|www\.)?[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+(?:\:\d{1,5})?(?:\/[^\s<>()\[\]{}]*)?/gi;

export function promptWithUrlContext(question: string): string {
  const urls = publicUrlsIn(question);
  if (urls.length === 0) return question;
  return `Öffentliche Webseiten, die du für diese Frage auswerten sollst:\n${urls.join("\n")}\n\nNutzerfrage:\n${question}`;
}

function publicUrlsIn(text: string): string[] {
  const urls = new Set<string>();
  for (const match of text.matchAll(urlPattern)) addUrl(urls, match, text);
  return [...urls];
}

function addUrl(urls: Set<string>, match: RegExpMatchArray, text: string): void {
  if (startsInsideEmail(text, match.index ?? 0)) return;
  const url = normalizedUrl(match[0]);
  if (url) urls.add(url);
}

function normalizedUrl(candidate: string): string | null {
  try {
    const value = candidate.replace(/[.,;:!?]+$/, "");
    const url = new URL(hasScheme(value) ? value : `https://${value}`);
    return url.protocol === "http:" || url.protocol === "https:" ? url.href : null;
  } catch (_) {
    return null;
  }
}

function hasScheme(url: string): boolean {
  const normalized = url.toLowerCase();
  return normalized.startsWith("http://") || normalized.startsWith("https://");
}

function startsInsideEmail(text: string, start: number): boolean {
  return start > 0 && text[start - 1] === "@";
}
