import {isIP} from "node:net";

export function pageUrlFrom(value: string): URL {
  const rawUrl = value.trim();
  if (rawUrl.length === 0 || rawUrl.length > 2048) throw new Error("Ungültige URL.");
  const url = parsedUrlFrom(rawUrl);
  assertSupportedUrl(url);
  return url;
}

export function isPublicInternetAddress(address: string): boolean {
  if (isIP(address) === 4) return isPublicIpv4(address);
  if (isIP(address) === 6) return isPublicIpv6(address);
  return false;
}

function parsedUrlFrom(rawUrl: string): URL {
  try {
    return new URL(hasScheme(rawUrl) ? rawUrl : `https://${rawUrl}`);
  } catch (_) {
    throw new Error("Ungültige URL.");
  }
}

function hasScheme(value: string): boolean {
  return /^[a-z][a-z\d+.-]*:/i.test(value);
}

function assertSupportedUrl(url: URL): void {
  if (url.protocol !== "http:" && url.protocol !== "https:") throw new Error("Nur HTTP(S)-URLs sind erlaubt.");
  if (url.username || url.password || localHostname(url.hostname)) throw new Error("Nur öffentliche URLs sind erlaubt.");
  if (isIP(url.hostname) !== 0 && !isPublicInternetAddress(url.hostname)) {
    throw new Error("Nur öffentliche URLs sind erlaubt.");
  }
}

function localHostname(hostname: string): boolean {
  const lowerCaseHostname = hostname.toLowerCase();
  return lowerCaseHostname === "localhost" || lowerCaseHostname.endsWith(".localhost") || lowerCaseHostname.endsWith(".local");
}

function isPublicIpv4(address: string): boolean {
  const [first, second] = address.split(".").map(Number);
  if (first === 10 || first === 127 || first >= 224 || first === 0) return false;
  if (first === 169 && second === 254) return false;
  if (first === 172 && second >= 16 && second <= 31) return false;
  if (first === 192 && (second === 0 || second === 168)) return false;
  if (first === 198 && (second === 18 || second === 19)) return false;
  return !(first === 100 && second >= 64 && second <= 127);
}

function isPublicIpv6(address: string): boolean {
  const normalizedAddress = address.toLowerCase();
  if (normalizedAddress === "::" || normalizedAddress === "::1") return false;
  if (normalizedAddress.startsWith("fc") || normalizedAddress.startsWith("fd")) return false;
  if (/^fe[89ab]/.test(normalizedAddress)) return false;
  return !normalizedAddress.startsWith("::ffff:");
}
