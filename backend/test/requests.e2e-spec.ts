import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { Service } from '../src/catalog/catalog.entities';
import { ServiceArea } from '../src/locations/location.entities';
import { UnavailableMediaStorage } from '../src/media/media-storage';
import { UserRole } from '../src/users/user.entity';
import { jpegWithMetadata, pdfDocument, pngWithMetadata } from './fixtures/images';
import {
  API,
  bearer,
  createTestApp,
  resetDatabase,
  Session,
  signIn,
  signInAs,
  uploadFile,
} from './helpers';

describe('Service requests API', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let customer: Session;
  let serviceId: string;
  let areaId: string;

  beforeAll(async () => {
    ({ app, dataSource } = await createTestApp());
  });
  beforeEach(async () => {
    await resetDatabase(dataSource);
    customer = await signIn(app);
    serviceId = (
      await dataSource.getRepository(Service).findOneByOrFail({
        slug: 'plumbing-leak-repair',
      })
    ).id;
    areaId = (await dataSource.getRepository(ServiceArea).findOneByOrFail({ slug: 'kima' })).id;
  });
  afterAll(() => app.close());

  const http = () => request(app.getHttpServer());

  const firstSlot = async () => {
    const res = await http().get(`${API}/requests/options`).expect(200);
    return res.body.schedule.slots[0] as { from: string; to: string };
  };

  const validBody = (overrides: Record<string, unknown> = {}) => ({
    serviceId,
    description: 'تسريب مياه تحت حوض المطبخ منذ يومين',
    address: {
      areaId,
      details: 'شارع النيل، عمارة 12، الدور الثالث، شقة 7',
      landmark: 'بجوار مسجد الطابية',
      latitude: 24.0889123,
      longitude: 32.8998456,
    },
    schedule: { type: 'asap' },
    ...overrides,
  });

  const submit = (session: Session, body: object, key: string | null = randomUUID()) => {
    const req = http().post(`${API}/requests`).set(bearer(session));
    if (key) req.set('Idempotency-Key', key);
    return req.send(body);
  };

  const uploadPhoto = async (session = customer, data = jpegWithMetadata()) => {
    const res = await uploadFile(app, session, 'request_photo', data);
    expect(res.status).toBe(201);
    return res.body.id as string;
  };

  describe('form options', () => {
    it('are public and describe limits, slots, areas and fee disclosure', async () => {
      const res = await http().get(`${API}/requests/options`).expect(200);
      expect(res.body.description).toEqual({ minLength: 10, maxLength: 1000 });
      expect(res.body.photos).toMatchObject({ max: 3, uploadsAvailable: true });
      expect(res.body.schedule.timeZone).toBe('Africa/Cairo');
      expect(res.body.schedule.asapAvailable).toBe(true);
      expect(res.body.schedule.slots.length).toBeGreaterThan(0);
      expect(res.body.fees).toEqual({ inspectionFee: null });
      expect(res.body.areas.map((a: { slug: string }) => a.slug)).toContain('kima');
    });

    it('lists active service areas for guests', async () => {
      await dataSource.getRepository(ServiceArea).update({ slug: 'atlas' }, { isActive: false });
      const res = await http().get(`${API}/service-areas`).expect(200);
      const slugs = res.body.items.map((a: { slug: string }) => a.slug);
      expect(slugs).toContain('kima');
      expect(slugs).not.toContain('atlas');
      expect(res.body.items[0]).toMatchObject({ isSample: true, name: { ar: expect.any(String) } });
    });
  });

  describe('submission', () => {
    it('requires authentication', async () => {
      await http().post(`${API}/requests`).send(validBody()).expect(401);
      await http().get(`${API}/requests`).expect(401);
    });

    it('creates a request with photos, a saved address and a slot, and returns it to its owner', async () => {
      const photo1 = await uploadPhoto();
      const photo2 = await uploadPhoto(customer, pngWithMetadata());
      const slot = await firstSlot();
      const res = await submit(
        customer,
        validBody({
          photoIds: [photo1, photo2],
          saveAddress: true,
          schedule: { type: 'scheduled', ...slot },
        }),
      ).expect(201);

      expect(res.body.reference).toMatch(/^SN-\d{6}-[0-9A-Z]{5}$/);
      expect(res.body).toMatchObject({
        status: 'submitted',
        description: 'تسريب مياه تحت حوض المطبخ منذ يومين',
        service: { slug: 'plumbing-leak-repair', category: { slug: 'plumbing' } },
        schedule: { type: 'scheduled', from: slot.from, to: slot.to },
        pricing: { type: 'inspection_required', currency: 'EGP' },
        fees: { inspectionFee: null },
        photoCount: 2,
        location: {
          area: { slug: 'kima' },
          details: 'شارع النيل، عمارة 12، الدور الثالث، شقة 7',
          landmark: 'بجوار مسجد الطابية',
          coordinates: { latitude: 24.08891, longitude: 32.89985 },
        },
      });
      expect(res.body.photos.map((p: { id: string }) => p.id)).toEqual([photo1, photo2]);
      expect(res.body.timeline).toEqual([{ status: 'submitted', at: expect.any(String) }]);
      // No technician is implied at this stage.
      expect(JSON.stringify(res.body)).not.toMatch(/technician/i);

      // Persisted: the address was saved, photos are bound, and an event was recorded.
      const addresses = await http().get(`${API}/me/addresses`).set(bearer(customer)).expect(200);
      expect(addresses.body.items).toHaveLength(1);
      expect(res.body.location.addressId).toBe(addresses.body.items[0].id);
      const [{ count }] = await dataSource.query(
        'SELECT count(*)::int AS count FROM media_files WHERE attached_at IS NOT NULL',
      );
      expect(count).toBe(2);

      const detail = await http()
        .get(`${API}/requests/${res.body.id}`)
        .set(bearer(customer))
        .expect(200);
      expect(detail.body).toEqual(res.body);

      const list = await http().get(`${API}/requests`).set(bearer(customer)).expect(200);
      expect(list.body.items).toHaveLength(1);
      expect(list.body.items[0]).toMatchObject({
        id: res.body.id,
        reference: res.body.reference,
        status: 'submitted',
        photoCount: 2,
      });
      expect(list.body.nextCursor).toBeNull();
    });

    it('accepts a request without photos for a saved address', async () => {
      const address = await http()
        .post(`${API}/me/addresses`)
        .set(bearer(customer))
        .send({ areaId, details: 'شارع كورنيش النيل، فيلا 3', label: 'البيت' })
        .expect(201);
      const res = await submit(
        customer,
        validBody({ address: undefined, addressId: address.body.id }),
      ).expect(201);
      expect(res.body.location).toMatchObject({
        addressId: address.body.id,
        details: 'شارع كورنيش النيل، فيلا 3',
        coordinates: null,
      });
      expect(res.body.photos).toEqual([]);
    });

    it('keeps the submitted location after the saved address is deleted', async () => {
      const address = await http()
        .post(`${API}/me/addresses`)
        .set(bearer(customer))
        .send({ areaId, details: 'شارع السوق، عمارة 4' })
        .expect(201);
      const created = await submit(
        customer,
        validBody({ address: undefined, addressId: address.body.id }),
      ).expect(201);
      await http()
        .delete(`${API}/me/addresses/${address.body.id}`)
        .set(bearer(customer))
        .expect(204);
      const detail = await http()
        .get(`${API}/requests/${created.body.id}`)
        .set(bearer(customer))
        .expect(200);
      expect(detail.body.location.details).toBe('شارع السوق، عمارة 4');
      await submit(customer, validBody({ address: undefined, addressId: address.body.id }))
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('ADDRESS_NOT_FOUND'));
    });

    it('shows the disclosed inspection fee when one is configured', async () => {
      const previous = process.env.INSPECTION_FEE_MINOR;
      process.env.INSPECTION_FEE_MINOR = '7500';
      const { app: feeApp, dataSource: feeDs } = await createTestApp();
      try {
        const session = await signIn(feeApp);
        const options = await request(feeApp.getHttpServer())
          .get(`${API}/requests/options`)
          .expect(200);
        expect(options.body.fees).toEqual({
          inspectionFee: { amountMinor: 7500, currency: 'EGP' },
        });
        const res = await request(feeApp.getHttpServer())
          .post(`${API}/requests`)
          .set(bearer(session))
          .set('Idempotency-Key', randomUUID())
          .send(validBody())
          .expect(201);
        expect(res.body.fees).toEqual({ inspectionFee: { amountMinor: 7500, currency: 'EGP' } });
        expect(feeDs).toBeDefined();
      } finally {
        if (previous === undefined) delete process.env.INSPECTION_FEE_MINOR;
        else process.env.INSPECTION_FEE_MINOR = previous;
        await feeApp.close();
      }
    });
  });

  describe('validation', () => {
    it('rejects missing required fields with field messages', async () => {
      const res = await submit(customer, {}).expect(400);
      expect(res.body.error.code).toBe('VALIDATION_FAILED');
      const fields = res.body.error.details.fields.join(' ');
      expect(fields).toMatch(/serviceId/);
      expect(fields).toMatch(/description/);
      expect(fields).toMatch(/schedule/);
    });

    it.each([
      ['too short', 'تسريب'],
      ['only spaces', '            '],
      ['too long', 'x'.repeat(1001)],
    ])('rejects a description that is %s', async (_label, description) => {
      const res = await submit(customer, validBody({ description })).expect(400);
      expect(res.body.error.details.fields.join(' ')).toMatch(/description/);
    });

    it('rejects unknown fields such as a client-chosen status', async () => {
      await submit(customer, validBody({ status: 'completed' })).expect(400);
    });

    it('rejects an unknown or inactive service', async () => {
      await submit(customer, validBody({ serviceId: randomUUID() }))
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('SERVICE_NOT_AVAILABLE'));
      await dataSource.getRepository(Service).update({ id: serviceId }, { isActive: false });
      await submit(customer, validBody())
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('SERVICE_NOT_AVAILABLE'));
      await submit(customer, validBody({ serviceId: 'plumbing' })).expect(400);
    });

    it('requires a location', async () => {
      const res = await submit(customer, validBody({ address: undefined })).expect(422);
      expect(res.body.error.code).toBe('LOCATION_REQUIRED');
    });

    it('rejects coordinates outside the service region or sent without a pair', async () => {
      const outside = validBody({
        address: { areaId, details: 'ميدان التحرير', latitude: 30.0444, longitude: 31.2357 },
      });
      await submit(customer, outside)
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('LOCATION_OUT_OF_AREA'));
      await submit(
        customer,
        validBody({ address: { areaId, details: 'شارع النيل 5', latitude: 24.08 } }),
      ).expect(400);
      await submit(
        customer,
        validBody({ address: { areaId, details: 'شارع النيل 5', latitude: 124, longitude: 32 } }),
      ).expect(400);
    });

    it('rejects an unknown or inactive area', async () => {
      await submit(
        customer,
        validBody({ address: { areaId: randomUUID(), details: 'شارع 1 عمارة 2' } }),
      )
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('AREA_NOT_AVAILABLE'));
      await dataSource.getRepository(ServiceArea).update({ id: areaId }, { isActive: false });
      await submit(customer, validBody())
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('AREA_NOT_AVAILABLE'));
    });

    it('rejects sending both a saved address and a typed one', async () => {
      await submit(customer, validBody({ addressId: randomUUID() })).expect(400);
    });

    it('accepts only appointment slots that are currently offered', async () => {
      const slot = await firstSlot();
      const shifted = new Date(new Date(slot.from).getTime() + 30 * 60_000).toISOString();
      await submit(
        customer,
        validBody({ schedule: { type: 'scheduled', from: shifted, to: slot.to } }),
      )
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('INVALID_SCHEDULE'));
      const past = { type: 'scheduled', from: '2020-01-01T07:00:00Z', to: '2020-01-01T10:00:00Z' };
      await submit(customer, validBody({ schedule: past }))
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('INVALID_SCHEDULE'));
      await submit(customer, validBody({ schedule: { type: 'scheduled' } })).expect(400);
      await submit(customer, validBody({ schedule: { type: 'tomorrow' } })).expect(400);
    });

    it('caps the number of photos', async () => {
      const ids = [
        await uploadPhoto(),
        await uploadPhoto(),
        await uploadPhoto(),
        await uploadPhoto(),
      ];
      await submit(customer, validBody({ photoIds: ids }))
        .expect(422)
        .expect((r) =>
          expect(r.body.error).toMatchObject({ code: 'MEDIA_TOO_MANY', details: { max: 3 } }),
        );
    });

    it('caps the number of open requests per customer', async () => {
      for (let i = 0; i < 5; i++) await submit(customer, validBody()).expect(201);
      const res = await submit(customer, validBody()).expect(422);
      expect(res.body.error).toMatchObject({ code: 'TOO_MANY_OPEN_REQUESTS', details: { max: 5 } });
    });

    it('rejects a document upload used as a request photo', async () => {
      const doc = await uploadFile(app, customer, 'technician_document', pdfDocument(), 'id.pdf');
      expect(doc.status).toBe(201);
      await submit(customer, validBody({ photoIds: [doc.body.id] }))
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('MEDIA_INVALID'));
    });
  });

  describe('duplicate submission protection', () => {
    it('requires a UUID Idempotency-Key', async () => {
      await submit(customer, validBody(), null)
        .expect(400)
        .expect((r) => expect(r.body.error.code).toBe('IDEMPOTENCY_KEY_REQUIRED'));
      await submit(customer, validBody(), 'not-a-uuid').expect(400);
    });

    it('returns the original request when the same submission is retried', async () => {
      const key = randomUUID();
      const photo = await uploadPhoto();
      const body = validBody({ photoIds: [photo] });
      const first = await submit(customer, body, key).expect(201);
      const retry = await submit(customer, body, key).expect(200);
      expect(retry.headers['idempotent-replayed']).toBe('true');
      expect(retry.body.id).toBe(first.body.id);
      expect(retry.body.reference).toBe(first.body.reference);
      const [{ count }] = await dataSource.query(
        'SELECT count(*)::int AS count FROM service_requests',
      );
      expect(count).toBe(1);
    });

    it('creates exactly one request when identical retries arrive concurrently', async () => {
      const key = randomUUID();
      const body = validBody();
      const results = await Promise.all([1, 2, 3, 4].map(() => submit(customer, body, key)));
      const statuses = results.map((r) => r.status).sort();
      expect(statuses).toEqual([200, 200, 200, 201]);
      expect(new Set(results.map((r) => r.body.id)).size).toBe(1);
    });

    it('refuses to reuse a key for a different request', async () => {
      const key = randomUUID();
      await submit(customer, validBody(), key).expect(201);
      const res = await submit(customer, validBody({ description: 'مشكلة مختلفة في السخان' }), key);
      expect(res.status).toBe(409);
      expect(res.body.error.code).toBe('IDEMPOTENCY_KEY_REUSED');
    });

    it('does not let one photo be attached to two requests', async () => {
      const photo = await uploadPhoto();
      await submit(customer, validBody({ photoIds: [photo] })).expect(201);
      await submit(customer, validBody({ photoIds: [photo] }))
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('MEDIA_INVALID'));
    });

    it('rolls back entirely when part of the submission is invalid', async () => {
      const photo = await uploadPhoto();
      await submit(
        customer,
        validBody({ photoIds: [photo, randomUUID()], saveAddress: true }),
      ).expect(422);
      // Nothing was created, the address was not saved and the photo can still be used.
      const addresses = await http().get(`${API}/me/addresses`).set(bearer(customer)).expect(200);
      expect(addresses.body.items).toEqual([]);
      await submit(customer, validBody({ photoIds: [photo] })).expect(201);
    });
  });

  describe('privacy and authorization', () => {
    it("hides another customer's request, photos and saved address", async () => {
      const photo = await uploadPhoto();
      const created = await submit(
        customer,
        validBody({ photoIds: [photo], saveAddress: true }),
      ).expect(201);
      const other = await signIn(app);

      await http()
        .get(`${API}/requests/${created.body.id}`)
        .set(bearer(other))
        .expect(404)
        .expect((r) => expect(r.body.error.code).toBe('REQUEST_NOT_FOUND'));
      await http().get(`${API}/media/${photo}/content`).set(bearer(other)).expect(404);
      const list = await http().get(`${API}/requests`).set(bearer(other)).expect(200);
      expect(list.body.items).toEqual([]);

      // Another customer's photo or address cannot be referenced either.
      const foreignPhoto = await uploadPhoto(other);
      await submit(customer, validBody({ photoIds: [foreignPhoto] }))
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('MEDIA_INVALID'));
      await submit(
        other,
        validBody({ address: undefined, addressId: created.body.location.addressId }),
      )
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('ADDRESS_NOT_FOUND'));
      await http()
        .delete(`${API}/me/addresses/${created.body.location.addressId}`)
        .set(bearer(other))
        .expect(404);
    });

    it('lets technicians and admins neither create nor read customer requests', async () => {
      const created = await submit(customer, validBody()).expect(201);
      for (const role of [UserRole.Technician, UserRole.Admin]) {
        const staff = await signInAs(app, dataSource, role);
        await submit(staff, validBody()).expect(403);
        await http().get(`${API}/requests`).set(bearer(staff)).expect(403);
        await http().get(`${API}/requests/${created.body.id}`).set(bearer(staff)).expect(403);
      }
    });

    it('serves photos privately to the owner, without location metadata', async () => {
      const photo = await uploadPhoto();
      const res = await http()
        .get(`${API}/media/${photo}/content`)
        .set(bearer(customer))
        .expect(200);
      expect(res.headers['content-type']).toBe('image/jpeg');
      expect(res.headers['cache-control']).toBe('private, no-store');
      expect(res.headers['x-content-type-options']).toBe('nosniff');
      const body = res.body as Buffer;
      expect(body.toString('latin1')).not.toContain('GPS24.0889N');
      await http().get(`${API}/media/${photo}/content`).expect(401);
    });

    it('treats malformed ids as not found', async () => {
      await http().get(`${API}/requests/not-a-uuid`).set(bearer(customer)).expect(404);
      await http().get(`${API}/media/../../etc/passwd/content`).set(bearer(customer)).expect(404);
    });
  });

  describe('uploads', () => {
    it.each([
      ['an SVG', Buffer.from('<svg xmlns="http://www.w3.org/2000/svg"/>'), 'x.jpg'],
      ['a GIF', Buffer.from('GIF89a......'), 'x.png'],
      ['an executable', Buffer.from([0x4d, 0x5a, 0x90, 0, 3, 0]), 'photo.jpg'],
      ['a PDF as a photo', pdfDocument(), 'photo.pdf'],
      ['a truncated JPEG', jpegWithMetadata().subarray(0, 40), 'photo.jpg'],
    ])('rejects %s by its content, not its name', async (_label, data, name) => {
      const res = await uploadFile(app, customer, 'request_photo', data, name);
      expect(res.status).toBe(415);
      expect(res.body.error.code).toBe('UNSUPPORTED_FILE_TYPE');
    });

    it('rejects files over the size limit', async () => {
      const big = Buffer.concat([jpegWithMetadata(), Buffer.alloc(250_000)]);
      const res = await uploadFile(app, customer, 'request_photo', big);
      expect(res.status).toBe(413);
      expect(res.body.error.code).toBe('FILE_TOO_LARGE');
      const huge = Buffer.concat([jpegWithMetadata(), Buffer.alloc(500_000)]);
      const hugeRes = await uploadFile(app, customer, 'request_photo', huge);
      expect(hugeRes.status).toBe(413);
      expect(hugeRes.body.error.code).toBe('FILE_TOO_LARGE');
    });

    it('requires a file and a valid purpose', async () => {
      const noFile = await http()
        .post(`${API}/media`)
        .set(bearer(customer))
        .field('purpose', 'request_photo');
      expect(noFile.status).toBe(400);
      expect(noFile.body.error.code).toBe('FILE_REQUIRED');
      const badPurpose = await uploadFile(app, customer, 'avatar', jpegWithMetadata());
      expect(badPurpose.status).toBe(400);
    });

    it('lets only customers upload request photos', async () => {
      const tech = await signInAs(app, dataSource, UserRole.Technician);
      const res = await uploadFile(app, tech, 'request_photo', jpegWithMetadata());
      expect(res.status).toBe(403);
    });

    it('recovers from a failed upload with a retry and a successful submission', async () => {
      const failed = await uploadFile(app, customer, 'request_photo', Buffer.from('broken'));
      expect(failed.status).toBe(415);
      const photo = await uploadPhoto();
      await submit(customer, validBody({ photoIds: [photo] })).expect(201);
    });

    it('lets the owner remove an unattached upload but not an attached one', async () => {
      const spare = await uploadPhoto();
      await http().delete(`${API}/media/${spare}`).set(bearer(customer)).expect(204);
      await submit(customer, validBody({ photoIds: [spare] }))
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('MEDIA_INVALID'));

      const used = await uploadPhoto();
      await submit(customer, validBody({ photoIds: [used] })).expect(201);
      await http()
        .delete(`${API}/media/${used}`)
        .set(bearer(customer))
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('MEDIA_INVALID'));
    });

    it('reports uploads as unavailable when no storage is configured, while requests still work', async () => {
      const { app: noStorage } = await createTestApp({
        mediaStorage: new UnavailableMediaStorage(),
      });
      try {
        const session = await signIn(noStorage);
        const options = await request(noStorage.getHttpServer())
          .get(`${API}/requests/options`)
          .expect(200);
        expect(options.body.photos.uploadsAvailable).toBe(false);
        const upload = await uploadFile(noStorage, session, 'request_photo', jpegWithMetadata());
        expect(upload.status).toBe(503);
        expect(upload.body.error.code).toBe('MEDIA_STORAGE_UNAVAILABLE');
        await request(noStorage.getHttpServer())
          .post(`${API}/requests`)
          .set(bearer(session))
          .set('Idempotency-Key', randomUUID())
          .send(validBody())
          .expect(201);
      } finally {
        await noStorage.close();
      }
    });
  });

  describe('history', () => {
    it('pages through requests newest first', async () => {
      const refs: string[] = [];
      for (let i = 0; i < 3; i++) {
        refs.push((await submit(customer, validBody()).expect(201)).body.reference);
      }
      const page1 = await http().get(`${API}/requests?limit=2`).set(bearer(customer)).expect(200);
      expect(page1.body.items.map((r: { reference: string }) => r.reference)).toEqual([
        refs[2],
        refs[1],
      ]);
      expect(page1.body.nextCursor).toEqual(expect.any(String));
      const page2 = await http()
        .get(`${API}/requests?limit=2&cursor=${page1.body.nextCursor}`)
        .set(bearer(customer))
        .expect(200);
      expect(page2.body.items.map((r: { reference: string }) => r.reference)).toEqual([refs[0]]);
      expect(page2.body.nextCursor).toBeNull();
      await http().get(`${API}/requests?cursor=garbage`).set(bearer(customer)).expect(400);
    });
  });

  describe('saved addresses', () => {
    it('limits the number of saved addresses', async () => {
      for (let i = 0; i < 10; i++) {
        await http()
          .post(`${API}/me/addresses`)
          .set(bearer(customer))
          .send({ areaId, details: `شارع رقم ${i + 1} عمارة 1` })
          .expect(201);
      }
      const res = await http()
        .post(`${API}/me/addresses`)
        .set(bearer(customer))
        .send({ areaId, details: 'شارع رقم 11 عمارة 1' })
        .expect(422);
      expect(res.body.error.code).toBe('ADDRESS_LIMIT_REACHED');
    });

    it('validates address fields', async () => {
      const res = await http()
        .post(`${API}/me/addresses`)
        .set(bearer(customer))
        .send({ areaId: 'kima', details: 'x' })
        .expect(400);
      expect(res.body.error.details.fields.join(' ')).toMatch(/areaId/);
    });
  });
});
