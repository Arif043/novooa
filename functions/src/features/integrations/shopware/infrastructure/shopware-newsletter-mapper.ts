import {type ShopwareNewsletterRecipient} from "../domain/shopware-newsletter-recipient.js";
import {text, type Raw} from "./shopware-record.js";

export const newsletterRecipientAssociations = {};

export function mapShopwareNewsletterRecipient(raw: Raw): ShopwareNewsletterRecipient {
  return {
    id: text(raw.id),
    email: text(raw.email),
    firstName: text(raw.firstName),
    lastName: text(raw.lastName),
    status: text(raw.status),
    createdAt: text(raw.createdAt),
    confirmedAt: text(raw.confirmedAt),
    raw,
  };
}
