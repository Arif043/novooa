export type OutboundAddressKind = "whatsapp" | "sms" | "email";

export function addressFor(kind: OutboundAddressKind, value: string): string {
  const address = value.trim();
  if (kind === "email") return address;
  if (kind === "whatsapp") {
    return address.startsWith("whatsapp:") ? address : `whatsapp:${address}`;
  }
  return address.startsWith("whatsapp:")
    ? address.slice("whatsapp:".length)
    : address;
}
