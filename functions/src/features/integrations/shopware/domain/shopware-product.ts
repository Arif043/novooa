/** Das einfache Modell eines Produkts. */
export type ShopwareProduct = {
  id: string;
  productNumber: string;
  name: string;
  active: boolean;
  stock: number;
  availableStock: number;
  /** Erster Preis des Produkts (Standardwährung); leer bei Varianten, die den Preis erben. */
  price: {gross: number; net: number} | null;
  ean: string;
  manufacturer: string;
  /** Gesetzt bei Varianten. */
  parentId: string;
  raw: Record<string, unknown>;
};
