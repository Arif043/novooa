/** Das einfache Modell eines Kunden. */
export type ShopwareCustomer = {
  id: string;
  customerNumber: string;
  email: string;
  firstName: string;
  lastName: string;
  company: string;
  active: boolean;
  guest: boolean;
  group: string;
  createdAt: string;
  billingAddress: {street: string; zip: string; city: string; country: string} | null;
  raw: Record<string, unknown>;
};
