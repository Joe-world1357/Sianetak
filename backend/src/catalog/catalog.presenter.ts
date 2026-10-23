import { PricingType, Service, ServiceCategory } from './catalog.entities';

export interface LocalizedText {
  ar: string;
  en: string;
}

export interface PricingGuidance {
  type: PricingType;
  currency: string;
  /** Integer minor units (piastres); present only for `indicative`. */
  minMinor?: number;
  maxMinor?: number;
}

const text = (ar: string, en: string): LocalizedText => ({ ar, en });
const optionalText = (ar: string | null, en: string | null): LocalizedText | null =>
  ar || en ? { ar: ar ?? en ?? '', en: en ?? ar ?? '' } : null;

/** Never trusts row values blindly: an inconsistent indicative row falls back to inspection. */
export function presentPricing(s: Service): PricingGuidance {
  if (
    s.pricingType === PricingType.Indicative &&
    Number.isInteger(s.priceMinMinor) &&
    Number.isInteger(s.priceMaxMinor) &&
    (s.priceMinMinor as number) > 0 &&
    (s.priceMaxMinor as number) >= (s.priceMinMinor as number)
  ) {
    return {
      type: PricingType.Indicative,
      currency: s.currency,
      minMinor: s.priceMinMinor as number,
      maxMinor: s.priceMaxMinor as number,
    };
  }
  return { type: PricingType.InspectionRequired, currency: s.currency };
}

export function presentCategory(c: ServiceCategory, serviceCount: number) {
  return {
    id: c.id,
    slug: c.slug,
    name: text(c.nameAr, c.nameEn),
    description: optionalText(c.descriptionAr, c.descriptionEn),
    iconKey: c.iconKey,
    serviceCount,
    isSample: c.isSample,
  };
}

export function presentServiceSummary(s: Service) {
  return {
    id: s.id,
    slug: s.slug,
    name: text(s.nameAr, s.nameEn),
    pricing: presentPricing(s),
    isSample: s.isSample,
  };
}

export function presentServiceDetail(s: Service & { category: ServiceCategory }) {
  return {
    ...presentServiceSummary(s),
    description: optionalText(s.descriptionAr, s.descriptionEn),
    category: {
      id: s.category.id,
      slug: s.category.slug,
      name: text(s.category.nameAr, s.category.nameEn),
    },
  };
}
