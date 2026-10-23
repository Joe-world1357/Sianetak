import { DataSource } from 'typeorm';
import { Service, ServiceCategory } from '../../catalog/catalog.entities';
import { ServiceArea } from '../../locations/location.entities';
import { SAMPLE_CATALOG, SAMPLE_PRICING } from './catalog.sample';
import { SAMPLE_SERVICE_AREAS } from './service-areas.sample';

/**
 * Idempotently inserts the sample catalog by slug. Existing rows are never modified or deleted,
 * so operator-approved data is safe; a slug already used by approved data is skipped.
 */
export async function seedSampleCatalog(dataSource: DataSource) {
  let categoriesInserted = 0;
  let servicesInserted = 0;
  await dataSource.transaction(async (em) => {
    for (const [ci, c] of SAMPLE_CATALOG.entries()) {
      let category = await em.findOneBy(ServiceCategory, { slug: c.slug });
      if (!category) {
        category = await em.save(
          em.create(ServiceCategory, {
            slug: c.slug,
            nameAr: c.nameAr,
            nameEn: c.nameEn,
            descriptionAr: c.descriptionAr,
            descriptionEn: c.descriptionEn,
            iconKey: c.iconKey,
            sortOrder: (ci + 1) * 10,
            isActive: true,
            isSample: true,
          }),
        );
        categoriesInserted++;
      }
      if (!category.isSample) continue;

      for (const [si, s] of c.services.entries()) {
        if (await em.existsBy(Service, { slug: s.slug })) continue;
        await em.save(
          em.create(Service, {
            categoryId: category.id,
            slug: s.slug,
            nameAr: s.nameAr,
            nameEn: s.nameEn,
            descriptionAr: s.descriptionAr,
            descriptionEn: s.descriptionEn,
            pricingType: SAMPLE_PRICING.pricingType,
            priceMinMinor: null,
            priceMaxMinor: null,
            currency: 'EGP',
            sortOrder: (si + 1) * 10,
            isActive: true,
            isSample: true,
          }),
        );
        servicesInserted++;
      }
    }
  });
  return { categoriesInserted, servicesInserted };
}

/** Idempotently inserts sample service areas by slug; existing rows are never modified. */
export async function seedSampleServiceAreas(dataSource: DataSource) {
  let areasInserted = 0;
  await dataSource.transaction(async (em) => {
    for (const [i, a] of SAMPLE_SERVICE_AREAS.entries()) {
      if (await em.existsBy(ServiceArea, { slug: a.slug })) continue;
      await em.insert(ServiceArea, {
        ...a,
        sortOrder: (i + 1) * 10,
        isActive: true,
        isSample: true,
      });
      areasInserted++;
    }
  });
  return { areasInserted };
}
