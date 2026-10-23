import type { Service, ServiceCategory } from '../catalog/catalog.entities';
import { presentPricing } from '../catalog/catalog.presenter';
import type { ServiceArea } from '../locations/location.entities';
import { presentArea } from '../locations/location.presenter';
import type { MediaFile } from '../media/media.entity';
import type { ServiceRequest, ServiceRequestEvent, ServiceRequestPhoto } from './request.entities';

export type LoadedRequest = ServiceRequest & {
  service: Service & { category: ServiceCategory };
  area: ServiceArea;
  photos: (ServiceRequestPhoto & { media: MediaFile })[];
  events: ServiceRequestEvent[];
};

const schedule = (r: ServiceRequest) => ({
  type: r.scheduleType,
  from: r.scheduledFrom?.toISOString() ?? null,
  to: r.scheduledTo?.toISOString() ?? null,
});

const service = (s: Service & { category: ServiceCategory }) => ({
  id: s.id,
  slug: s.slug,
  name: { ar: s.nameAr, en: s.nameEn },
  category: { slug: s.category.slug, name: { ar: s.category.nameAr, en: s.category.nameEn } },
});

export function presentRequestSummary(r: LoadedRequest) {
  return {
    id: r.id,
    reference: r.reference,
    status: r.status,
    service: service(r.service),
    area: presentArea(r.area),
    schedule: schedule(r),
    photoCount: r.photos.length,
    submittedAt: r.submittedAt.toISOString(),
  };
}

/** Full request, returned only to its owner. */
export function presentRequestDetail(r: LoadedRequest) {
  return {
    ...presentRequestSummary(r),
    description: r.description,
    photos: [...r.photos]
      .sort((a, b) => a.position - b.position)
      .map((p) => ({
        id: p.media.id,
        contentType: p.media.contentType,
        byteSize: p.media.byteSize,
      })),
    location: {
      addressId: r.addressId,
      area: presentArea(r.area),
      details: r.addressDetails,
      landmark: r.addressLandmark,
      coordinates:
        r.latitude !== null && r.longitude !== null
          ? { latitude: r.latitude, longitude: r.longitude }
          : null,
    },
    pricing: presentPricing({
      pricingType: r.pricingType,
      priceMinMinor: r.priceMinMinor,
      priceMaxMinor: r.priceMaxMinor,
      currency: r.currency,
    } as Service),
    fees: {
      inspectionFee:
        r.inspectionFeeMinor === null
          ? null
          : { amountMinor: r.inspectionFeeMinor, currency: r.currency },
    },
    timeline: [...r.events]
      .sort((a, b) => a.createdAt.getTime() - b.createdAt.getTime())
      .map((e) => ({ status: e.toStatus, at: e.createdAt.toISOString() })),
  };
}
