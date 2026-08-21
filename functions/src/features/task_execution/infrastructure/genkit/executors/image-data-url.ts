export type ImageData = {
  bytes: Uint8Array;
  contentType: string;
};

export function imageDataFromDataUrl(value: string): ImageData {
  const match = imageDataUrlPattern.exec(value.trim());
  if (!match) throw new Error("Die Bild-Data-URL ist ungültig.");
  const bytes = Buffer.from(match[2], "base64");
  if (bytes.byteLength === 0) throw new Error("Die Bild-Data-URL enthält keine Bilddaten.");
  return {bytes, contentType: match[1].toLowerCase()};
}

export function imageExtensionFor(contentType: string): string {
  const extensions: Record<string, string> = {
    "image/png": "png",
    "image/jpeg": "jpg",
    "image/webp": "webp",
    "image/gif": "gif",
    "image/avif": "avif",
  };
  return extensions[contentType] ?? "img";
}

const imageDataUrlPattern = /^data:(image\/[a-z0-9.+-]+);base64,([A-Za-z0-9+/]+={0,2})$/i;
