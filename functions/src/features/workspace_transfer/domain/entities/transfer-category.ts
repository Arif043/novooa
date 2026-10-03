import {InvalidTransferRequestError} from "./transfer-errors.js";

/**
 * Reihenfolge ist zugleich Import-Reihenfolge: Aufgaben können auf Dateien,
 * Notizen, Fähigkeiten und Mitarbeiter verweisen, deshalb kommen sie zuletzt.
 */
export const transferCategories = ["files", "data", "knowledge", "skills", "employees", "tasks"] as const;

export type TransferCategory = typeof transferCategories[number];

export type TransferCounts = Partial<Record<TransferCategory, number>>;

export function isTransferCategory(value: unknown): value is TransferCategory {
  return typeof value === "string" && (transferCategories as readonly string[]).includes(value);
}

export class TransferCategorySelection {
  private constructor(readonly categories: readonly TransferCategory[]) {}

  static from(value: unknown): TransferCategorySelection {
    if (!Array.isArray(value) || value.length === 0) {
      throw new InvalidTransferRequestError("Bitte wähle mindestens einen Bereich aus.");
    }
    if (!value.every(isTransferCategory)) {
      throw new InvalidTransferRequestError("Die Auswahl enthält einen unbekannten Bereich.");
    }
    return TransferCategorySelection.of(value);
  }

  static of(categories: readonly TransferCategory[]): TransferCategorySelection {
    return new TransferCategorySelection(transferCategories.filter((category) => categories.includes(category)));
  }

  restrictedTo(available: readonly TransferCategory[]): TransferCategorySelection {
    const categories = this.categories.filter((category) => available.includes(category));
    if (categories.length === 0) {
      throw new InvalidTransferRequestError("Der Export enthält keinen der ausgewählten Bereiche.");
    }
    return new TransferCategorySelection(categories);
  }
}
