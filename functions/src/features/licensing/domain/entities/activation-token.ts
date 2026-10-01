const tokenPattern = /^[A-HJ-NP-Z2-9]{16}$/;

export function runtimeActivationTokenFrom(value: unknown): string {
  if (typeof value !== "string") throw new Error("Der Lizenzschlüssel ist ungültig.");
  const token = value.replace(/[\s-]/g, "").toUpperCase();
  if (!tokenPattern.test(token)) throw new Error("Der Lizenzschlüssel ist ungültig.");
  return token;
}
