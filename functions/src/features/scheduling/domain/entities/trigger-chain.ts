/**
 * Ursachenkette eines Laufs: die IDs aller Event-Trigger, die ihn
 * (mittelbar) ausgelöst haben, ältester zuerst. Sie reist im Lauf-Input mit
 * und landet in jedem Ereignis, das der Lauf erzeugt — so lässt sich ein
 * Zyklus erkennen, bevor er sich schließt.
 */
export const triggerChainInputKey = "triggerChain";

export function triggerChainFrom(input: Record<string, unknown> | undefined): string[] {
  const value = input?.[triggerChainInputKey];
  if (!Array.isArray(value)) return [];
  return value.filter((id): id is string => typeof id === "string");
}
