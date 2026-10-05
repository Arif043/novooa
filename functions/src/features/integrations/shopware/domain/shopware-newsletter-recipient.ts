/** Das einfache Modell einer Newsletter-Anmeldung. */
export type ShopwareNewsletterRecipient = {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  /** `direct`, `notSet`, `optIn`, `optOut` … wie in Shopware. */
  status: string;
  createdAt: string;
  confirmedAt: string;
  raw: Record<string, unknown>;
};
