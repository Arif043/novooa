export function addressFor(kind: "whatsapp" | "sms", value: string): string {
  const address = value.trim();
  if (kind === "whatsapp") {
    return address.startsWith("whatsapp:") ? address : `whatsapp:${address}`;
  }
  return address.startsWith("whatsapp:")
    ? address.slice("whatsapp:".length)
    : address;
}
