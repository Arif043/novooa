/** Wie viele Konten die Lizenz erlaubt; `null` = unbegrenzt. */
export interface RuntimeUserLimit {
  maxUsers(): number | null;
}
