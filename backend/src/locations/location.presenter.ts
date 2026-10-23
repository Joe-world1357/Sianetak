import type { CustomerAddress, ServiceArea } from './location.entities';

export function presentArea(a: ServiceArea) {
  return {
    id: a.id,
    slug: a.slug,
    name: { ar: a.nameAr, en: a.nameEn },
    isSample: a.isSample,
  };
}

/** Saved address, returned only to its owner. */
export function presentAddress(a: CustomerAddress & { area: ServiceArea }) {
  return {
    id: a.id,
    label: a.label,
    area: presentArea(a.area),
    details: a.details,
    landmark: a.landmark,
    location:
      a.latitude !== null && a.longitude !== null
        ? { latitude: a.latitude, longitude: a.longitude }
        : null,
    createdAt: a.createdAt.toISOString(),
  };
}
