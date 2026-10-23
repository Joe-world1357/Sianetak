import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { Service, ServiceCategory } from '../src/catalog/catalog.entities';
import { API, createTestApp, resetDatabase } from './helpers';

describe('Catalog API (guest)', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  beforeAll(async () => {
    ({ app, dataSource } = await createTestApp());
  });
  beforeEach(() => resetDatabase(dataSource));
  afterAll(() => app.close());

  const http = () => request(app.getHttpServer());

  it('lists active categories in order with active service counts, without signing in', async () => {
    const res = await http().get(`${API}/catalog/categories`).expect(200);
    const slugs = res.body.items.map((c: { slug: string }) => c.slug);
    expect(slugs).toEqual([
      'plumbing',
      'electrical',
      'air-conditioning',
      'carpentry',
      'painting',
      'appliances',
    ]);
    const plumbing = res.body.items[0];
    expect(plumbing).toMatchObject({
      name: { ar: 'سباكة', en: 'Plumbing' },
      serviceCount: 3,
      isSample: true,
      iconKey: 'plumbing',
    });
  });

  it('hides inactive categories and does not count inactive services', async () => {
    await dataSource
      .getRepository(ServiceCategory)
      .update({ slug: 'painting' }, { isActive: false });
    await dataSource
      .getRepository(Service)
      .update({ slug: 'plumbing-leak-repair' }, { isActive: false });
    const res = await http().get(`${API}/catalog/categories`).expect(200);
    const slugs = res.body.items.map((c: { slug: string }) => c.slug);
    expect(slugs).not.toContain('painting');
    expect(res.body.items.find((c: { slug: string }) => c.slug === 'plumbing').serviceCount).toBe(
      2,
    );
  });

  it('returns an empty list when no categories are configured', async () => {
    await resetDatabase(dataSource, { seed: false });
    const res = await http().get(`${API}/catalog/categories`).expect(200);
    expect(res.body.items).toEqual([]);
  });

  it('returns a category with its active services and pricing guidance', async () => {
    const res = await http().get(`${API}/catalog/categories/plumbing`).expect(200);
    expect(res.body.slug).toBe('plumbing');
    expect(res.body.services).toHaveLength(3);
    for (const s of res.body.services) {
      expect(s.pricing).toEqual({ type: 'inspection_required', currency: 'EGP' });
    }
  });

  it('returns an empty service list for a category with no active services', async () => {
    await dataSource.getRepository(ServiceCategory).insert({
      slug: 'roofing',
      nameAr: 'أسطح',
      nameEn: 'Roofing',
      sortOrder: 99,
    });
    const res = await http().get(`${API}/catalog/categories/roofing`).expect(200);
    expect(res.body.services).toEqual([]);
    expect(res.body.serviceCount).toBe(0);
  });

  it('returns 404 for unknown, inactive or malformed category slugs', async () => {
    const unknown = await http().get(`${API}/catalog/categories/unknown`).expect(404);
    expect(unknown.body.error.code).toBe('CATEGORY_NOT_FOUND');
    await dataSource
      .getRepository(ServiceCategory)
      .update({ slug: 'painting' }, { isActive: false });
    await http().get(`${API}/catalog/categories/painting`).expect(404);
    const bad = await http().get(`${API}/catalog/categories/DROP%20TABLE`).expect(404);
    expect(bad.body.error.code).toBe('NOT_FOUND');
  });

  it('returns service details with category and bilingual text', async () => {
    const res = await http().get(`${API}/catalog/services/ac-cleaning`).expect(200);
    expect(res.body).toMatchObject({
      slug: 'ac-cleaning',
      name: { ar: 'تنظيف وصيانة تكييف', en: 'AC cleaning and service' },
      pricing: { type: 'inspection_required', currency: 'EGP' },
      category: { slug: 'air-conditioning' },
      isSample: true,
    });
    expect(res.body.description.ar).toBeTruthy();
    expect(res.body.description.en).toBeTruthy();
  });

  it('shows an approved indicative price range in minor units', async () => {
    const category = await dataSource
      .getRepository(ServiceCategory)
      .findOneByOrFail({ slug: 'plumbing' });
    await dataSource.getRepository(Service).insert({
      categoryId: category.id,
      slug: 'test-indicative',
      nameAr: 'خدمة اختبار',
      nameEn: 'Test service',
      pricingType: 'indicative' as Service['pricingType'],
      priceMinMinor: 15000,
      priceMaxMinor: 30000,
    });
    const res = await http().get(`${API}/catalog/services/test-indicative`).expect(200);
    expect(res.body.pricing).toEqual({
      type: 'indicative',
      currency: 'EGP',
      minMinor: 15000,
      maxMinor: 30000,
    });
  });

  it('rejects inconsistent pricing at the database level', async () => {
    const category = await dataSource
      .getRepository(ServiceCategory)
      .findOneByOrFail({ slug: 'plumbing' });
    await expect(
      dataSource.getRepository(Service).insert({
        categoryId: category.id,
        slug: 'bad-pricing',
        nameAr: 'خطأ',
        nameEn: 'Bad',
        pricingType: 'indicative' as Service['pricingType'],
        priceMinMinor: null,
        priceMaxMinor: null,
      }),
    ).rejects.toThrow(/chk_services_pricing/);
    await expect(
      dataSource.getRepository(Service).insert({
        categoryId: category.id,
        slug: 'bad-pricing-2',
        nameAr: 'خطأ',
        nameEn: 'Bad',
        pricingType: 'inspection_required' as Service['pricingType'],
        priceMinMinor: 100,
        priceMaxMinor: 200,
      }),
    ).rejects.toThrow(/chk_services_pricing/);
  });

  it('returns 404 for inactive services and services in inactive categories', async () => {
    await dataSource.getRepository(Service).update({ slug: 'ac-cleaning' }, { isActive: false });
    const res = await http().get(`${API}/catalog/services/ac-cleaning`).expect(404);
    expect(res.body.error.code).toBe('SERVICE_NOT_FOUND');
    await dataSource
      .getRepository(ServiceCategory)
      .update({ slug: 'carpentry' }, { isActive: false });
    await http().get(`${API}/catalog/services/carpentry-door-repair`).expect(404);
  });

  it('seeding is idempotent', async () => {
    const { seedSampleCatalog } = await import('../src/database/seeds/seed-catalog');
    const again = await seedSampleCatalog(dataSource);
    expect(again).toEqual({ categoriesInserted: 0, servicesInserted: 0 });
  });

  it('reports health', async () => {
    await http().get(`${API}/health`).expect(200, { status: 'ok', database: 'ok' });
  });
});
