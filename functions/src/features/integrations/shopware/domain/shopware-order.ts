/** Das einfache, stabile Modell einer Bestellung; Shopware-Felder ändern sich zwischen Versionen, dieses Modell nicht. */
export type ShopwareAddress = {
  firstName: string;
  lastName: string;
  company: string;
  street: string;
  zip: string;
  city: string;
  country: string;
};

export type ShopwareOrderLineItem = {
  id: string;
  label: string;
  productNumber: string;
  quantity: number;
  unitPrice: number;
  total: number;
  type: string;
};

export type ShopwareOrder = {
  id: string;
  orderNumber: string;
  createdAt: string;
  /** Technischer Name, z. B. `open`, `in_progress`, `completed`, `cancelled`. */
  status: string;
  statusLabel: string;
  paymentStatus: string;
  paymentStatusLabel: string;
  deliveryStatus: string;
  deliveryStatusLabel: string;
  currency: string;
  /** Brutto. */
  total: number;
  netTotal: number;
  customer: {id: string; number: string; email: string; firstName: string; lastName: string; company: string};
  billingAddress: ShopwareAddress | null;
  shippingAddress: ShopwareAddress | null;
  shippingMethod: string;
  paymentMethod: string;
  customerComment: string;
  lineItems: ShopwareOrderLineItem[];
  /** Das Objekt, wie Shopware es geliefert hat. */
  raw: Record<string, unknown>;
};
