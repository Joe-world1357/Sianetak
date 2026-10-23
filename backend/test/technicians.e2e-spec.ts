import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { ServiceCategory } from '../src/catalog/catalog.entities';
import { ServiceArea } from '../src/locations/location.entities';
import { UserRole } from '../src/users/user.entity';
import { jpegWithMetadata, pdfDocument } from './fixtures/images';
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

describe('Technician onboarding and admin verification', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  let applicant: Session;
  let admin: Session;
  let plumbingId: string;
  let electricalId: string;
  let kimaId: string;
  let atlasId: string;

  beforeAll(async () => {
    ({ app, dataSource } = await createTestApp());
  });
  beforeEach(async () => {
    await resetDatabase(dataSource);
    applicant = await signIn(app);
    admin = await signInAs(app, dataSource, UserRole.Admin);
    const categories = dataSource.getRepository(ServiceCategory);
    plumbingId = (await categories.findOneByOrFail({ slug: 'plumbing' })).id;
    electricalId = (await categories.findOneByOrFail({ slug: 'electrical' })).id;
    const areas = dataSource.getRepository(ServiceArea);
    kimaId = (await areas.findOneByOrFail({ slug: 'kima' })).id;
    atlasId = (await areas.findOneByOrFail({ slug: 'atlas' })).id;
  });
  afterAll(() => app.close());

  const http = () => request(app.getHttpServer());

  const uploadDoc = async (session = applicant, data = pdfDocument(), name = 'doc.pdf') => {
    const res = await uploadFile(app, session, 'technician_document', data, name);
    expect(res.status).toBe(201);
    return res.body.id as string;
  };

  const application = (overrides: Record<string, unknown> = {}) => ({
    fullName: 'محمود عبد الرحيم',
    yearsOfExperience: 8,
    bio: 'سباك وكهربائي منازل في أسوان.',
    specialtyCategoryIds: [plumbingId, electricalId],
    serviceAreaIds: [kimaId, atlasId],
    documents: [],
    ...overrides,
  });

  const submit = (session: Session, body: object) =>
    http().put(`${API}/technician/application`).set(bearer(session)).send(body);

  const submitValid = async (session = applicant) => {
    const docs = [await uploadDoc(session), await uploadDoc(session, jpegWithMetadata(), 'id.jpg')];
    const res = await submit(
      session,
      application({
        documents: [
          { mediaId: docs[0], kind: 'qualification' },
          { mediaId: docs[1], kind: 'identity' },
        ],
      }),
    ).expect(201);
    return { id: res.body.application.id as string, docs, body: res.body };
  };

  const review = (session: Session, id: string, action: string, body: object = {}) =>
    http()
      .post(`${API}/admin/technician-applications/${id}/${action}`)
      .set(bearer(session))
      .send(body);

  const auditActions = async (id: string) =>
    (
      await dataSource.query(
        'SELECT action, actor_id FROM audit_logs WHERE target_id = $1 ORDER BY created_at, action',
        [id],
      )
    ).map((r: { action: string; actor_id: string }) => [r.action, r.actor_id]);

  describe('application', () => {
    it('starts with no application and states the document requirements', async () => {
      const res = await http()
        .get(`${API}/technician/application`)
        .set(bearer(applicant))
        .expect(200);
      expect(res.body.application).toBeNull();
      expect(res.body.requirements).toMatchObject({
        minDocuments: 0,
        documentKinds: ['identity', 'qualification', 'other'],
        uploadsAvailable: true,
      });
    });

    it('submits a valid application for review and records an audit event', async () => {
      const { id, docs, body } = await submitValid();
      expect(body.application).toMatchObject({
        status: 'pending_review',
        fullName: 'محمود عبد الرحيم',
        yearsOfExperience: 8,
        decisionReason: null,
        canResubmit: false,
        eligibleForWork: false,
      });
      expect(body.application.specialties.map((s: { slug: string }) => s.slug)).toEqual([
        'plumbing',
        'electrical',
      ]);
      expect(body.application.serviceAreas.map((a: { slug: string }) => a.slug).sort()).toEqual([
        'atlas',
        'kima',
      ]);
      expect(body.application.documents.map((d: { id: string }) => d.id).sort()).toEqual(
        [...docs].sort(),
      );
      expect(await auditActions(id)).toEqual([
        ['technician_application.submitted', applicant.user.id],
      ]);
      // Applying does not grant the technician role.
      const me = await http().get(`${API}/me`).set(bearer(applicant)).expect(200);
      expect(me.body.role).toBe('customer');
    });

    it('treats an identical retry as the same submission and refuses a second one', async () => {
      const body = application();
      const first = await submit(applicant, body).expect(201);
      const retry = await submit(applicant, body).expect(200);
      expect(retry.body.application.id).toBe(first.body.application.id);
      const second = await submit(applicant, application({ fullName: 'اسم آخر' })).expect(409);
      expect(second.body.error.code).toBe('APPLICATION_ALREADY_SUBMITTED');
      const [{ count }] = await dataSource.query(
        'SELECT count(*)::int AS count FROM technician_profiles',
      );
      expect(count).toBe(1);
    });

    it('creates one application when submissions race', async () => {
      const results = await Promise.all([1, 2, 3].map(() => submit(applicant, application())));
      expect(results.map((r) => r.status).sort()).toEqual([200, 200, 201]);
    });

    it.each([
      ['no specialties', { specialtyCategoryIds: [] }],
      ['no service areas', { serviceAreaIds: [] }],
      ['a name with digits', { fullName: 'Ali 123' }],
      ['a one-letter name', { fullName: 'A' }],
      ['impossible experience', { yearsOfExperience: 99 }],
      ['duplicate specialties', { specialtyCategoryIds: ['x', 'x'] }],
      ['an unknown document kind', { documents: [{ mediaId: randomUUID(), kind: 'passport' }] }],
    ])('rejects %s with a validation error', async (_label, overrides) => {
      const res = await submit(applicant, application(overrides)).expect(400);
      expect(res.body.error.code).toBe('VALIDATION_FAILED');
    });

    it('rejects specialties and areas that are not offered', async () => {
      await submit(applicant, application({ specialtyCategoryIds: [randomUUID()] }))
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('CATEGORY_NOT_AVAILABLE'));
      await submit(applicant, application({ serviceAreaIds: [randomUUID()] }))
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('AREA_NOT_AVAILABLE'));
    });

    it("rejects someone else's document or a request photo as a document", async () => {
      const other = await signIn(app);
      const foreign = await uploadDoc(other);
      await submit(applicant, application({ documents: [{ mediaId: foreign, kind: 'identity' }] }))
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('MEDIA_INVALID'));
      const photo = await uploadFile(app, applicant, 'request_photo', jpegWithMetadata());
      await submit(
        applicant,
        application({ documents: [{ mediaId: photo.body.id, kind: 'identity' }] }),
      )
        .expect(422)
        .expect((r) => expect(r.body.error.code).toBe('MEDIA_INVALID'));
    });

    it('enforces a configured minimum number of documents', async () => {
      process.env.TECHNICIAN_MIN_DOCUMENTS = '1';
      const { app: strict } = await createTestApp();
      try {
        const session = await signIn(strict);
        const res = await request(strict.getHttpServer())
          .put(`${API}/technician/application`)
          .set(bearer(session))
          .send(application())
          .expect(422);
        expect(res.body.error).toMatchObject({ code: 'DOCUMENTS_REQUIRED', details: { min: 1 } });
      } finally {
        delete process.env.TECHNICIAN_MIN_DOCUMENTS;
        await strict.close();
      }
    });

    it('does not let admins apply', async () => {
      const res = await submit(admin, application()).expect(403);
      expect(res.body.error.code).toBe('FORBIDDEN');
    });

    it('requires authentication', async () => {
      await http().get(`${API}/technician/application`).expect(401);
      await http().put(`${API}/technician/application`).send(application()).expect(401);
    });
  });

  describe('admin access control', () => {
    it('refuses verification tools to unauthenticated users, customers and technicians', async () => {
      const { id } = await submitValid();
      const tech = await signInAs(app, dataSource, UserRole.Technician);
      await http().get(`${API}/admin/technician-applications`).expect(401);
      for (const session of [applicant, tech]) {
        await http().get(`${API}/admin/technician-applications`).set(bearer(session)).expect(403);
        await http()
          .get(`${API}/admin/technician-applications/${id}`)
          .set(bearer(session))
          .expect(403);
        await review(session, id, 'approve').expect(403);
      }
      const after = await http()
        .get(`${API}/technician/application`)
        .set(bearer(applicant))
        .expect(200);
      expect(after.body.application.status).toBe('pending_review');
    });

    it('does not let a reviewer decide their own application', async () => {
      const { id } = await submitValid();
      // The applicant is later made an admin: they still cannot approve themselves.
      await dataSource.query('UPDATE users SET role = $1 WHERE id = $2', [
        'admin',
        applicant.user.id,
      ]);
      const res = await review(applicant, id, 'approve').expect(403);
      expect(res.body.error.code).toBe('CANNOT_REVIEW_OWN_APPLICATION');
    });
  });

  describe('review', () => {
    it('lists pending applications and shows full details to admins', async () => {
      const { id, docs } = await submitValid();
      const list = await http()
        .get(`${API}/admin/technician-applications?status=pending_review`)
        .set(bearer(admin))
        .expect(200);
      expect(list.body).toMatchObject({ total: 1, limit: 20, offset: 0 });
      expect(list.body.items[0]).toMatchObject({
        id,
        status: 'pending_review',
        specialtyCount: 2,
        areaCount: 2,
        documentCount: 2,
      });
      const empty = await http()
        .get(`${API}/admin/technician-applications?status=approved`)
        .set(bearer(admin))
        .expect(200);
      expect(empty.body.items).toEqual([]);
      await http()
        .get(`${API}/admin/technician-applications?status=bogus`)
        .set(bearer(admin))
        .expect(400);

      const detail = await http()
        .get(`${API}/admin/technician-applications/${id}`)
        .set(bearer(admin))
        .expect(200);
      expect(detail.body.applicant).toMatchObject({
        userId: applicant.user.id,
        phone: applicant.user.phone,
        role: 'customer',
      });
      expect(detail.body.history).toEqual([
        {
          action: 'technician_application.submitted',
          actorId: applicant.user.id,
          at: expect.any(String),
          reason: null,
        },
      ]);

      // Documents are readable by admins, never by other users.
      const doc = await http()
        .get(`${API}/media/${docs[0]}/content`)
        .set(bearer(admin))
        .expect(200);
      expect(doc.headers['content-type']).toBe('application/pdf');
      expect(doc.headers['content-disposition']).toMatch(/^attachment/);
      const stranger = await signIn(app);
      await http().get(`${API}/media/${docs[0]}/content`).set(bearer(stranger)).expect(404);
      await http()
        .get(`${API}/admin/technician-applications/${randomUUID()}`)
        .set(bearer(admin))
        .expect(404);
    });

    it('approves an application, grants the technician role and records who decided', async () => {
      const { id } = await submitValid();
      const res = await review(admin, id, 'approve', { note: 'تم التحقق من المستندات' }).expect(
        200,
      );
      expect(res.body).toMatchObject({
        status: 'approved',
        reviewedBy: { id: admin.user.id },
        eligibleForWork: true,
        applicant: { role: 'technician' },
      });
      expect(res.body.reviewedAt).toEqual(expect.any(String));
      expect(await auditActions(id)).toEqual([
        ['technician_application.submitted', applicant.user.id],
        ['technician_application.approved', admin.user.id],
      ]);

      const own = await http()
        .get(`${API}/technician/application`)
        .set(bearer(applicant))
        .expect(200);
      expect(own.body.application).toMatchObject({ status: 'approved', eligibleForWork: true });
      // An approval note is internal; only rejection/suspension reasons are shown to applicants.
      expect(own.body.application.decisionReason).toBeNull();

      await review(admin, id, 'approve')
        .expect(409)
        .expect((r) => expect(r.body.error.code).toBe('APPLICATION_STATE_CONFLICT'));
      await review(admin, id, 'reject', { reason: 'late' }).expect(409);
      await submit(applicant, application())
        .expect(409)
        .expect((r) => expect(r.body.error.code).toBe('APPLICATION_STATE_CONFLICT'));
    });

    it('requires a reason to reject, shows it to the applicant and allows resubmission', async () => {
      const { id, docs } = await submitValid();
      await review(admin, id, 'reject').expect(400);
      await review(admin, id, 'reject', { reason: '  ' }).expect(400);
      const rejected = await review(admin, id, 'reject', {
        reason: 'صورة البطاقة غير واضحة، أعد رفعها',
      }).expect(200);
      expect(rejected.body).toMatchObject({ status: 'rejected', eligibleForWork: false });

      const own = await http()
        .get(`${API}/technician/application`)
        .set(bearer(applicant))
        .expect(200);
      expect(own.body.application).toMatchObject({
        status: 'rejected',
        decisionReason: 'صورة البطاقة غير واضحة، أعد رفعها',
        canResubmit: true,
      });
      const me = await http().get(`${API}/me`).set(bearer(applicant)).expect(200);
      expect(me.body.role).toBe('customer');

      // Keep one existing document, add a new one.
      const replacement = await uploadDoc(applicant, jpegWithMetadata(), 'id-new.jpg');
      const resubmitted = await submit(
        applicant,
        application({
          documents: [
            { mediaId: docs[0], kind: 'qualification' },
            { mediaId: replacement, kind: 'identity' },
          ],
        }),
      ).expect(200);
      expect(resubmitted.body.application).toMatchObject({
        id,
        status: 'pending_review',
        decisionReason: null,
      });
      expect(
        resubmitted.body.application.documents.map((d: { id: string }) => d.id).sort(),
      ).toEqual([docs[0], replacement].sort());
      const actions = (await auditActions(id)).map(([a]: string[]) => a);
      expect(actions).toEqual([
        'technician_application.submitted',
        'technician_application.rejected',
        'technician_application.resubmitted',
      ]);
      const detail = await http()
        .get(`${API}/admin/technician-applications/${id}`)
        .set(bearer(admin))
        .expect(200);
      expect(detail.body.history[1]).toMatchObject({
        action: 'technician_application.rejected',
        actorId: admin.user.id,
        reason: 'صورة البطاقة غير واضحة، أعد رفعها',
      });
    });

    it('suspends an approved technician with a reason, removing eligibility, and can reinstate', async () => {
      const { id } = await submitValid();
      await review(admin, id, 'suspend', { reason: 'early' }).expect(409);
      await review(admin, id, 'approve').expect(200);
      await review(admin, id, 'suspend').expect(400);
      const suspended = await review(admin, id, 'suspend', {
        reason: 'شكاوى متكررة قيد المراجعة',
      }).expect(200);
      expect(suspended.body).toMatchObject({ status: 'suspended', eligibleForWork: false });
      const own = await http()
        .get(`${API}/technician/application`)
        .set(bearer(applicant))
        .expect(200);
      expect(own.body.application).toMatchObject({
        status: 'suspended',
        decisionReason: 'شكاوى متكررة قيد المراجعة',
        eligibleForWork: false,
        canResubmit: false,
      });
      const reinstated = await review(admin, id, 'approve').expect(200);
      expect(reinstated.body.eligibleForWork).toBe(true);
    });

    it('applies exactly one decision when two reviewers act at once', async () => {
      const { id } = await submitValid();
      const other = await signInAs(app, dataSource, UserRole.Admin);
      const [a, b] = await Promise.all([
        review(admin, id, 'approve'),
        review(other, id, 'reject', { reason: 'مستندات ناقصة' }),
      ]);
      expect([a.status, b.status].sort()).toEqual([200, 409]);
      const decisions = (await auditActions(id)).filter(([action]: string[]) =>
        /approved|rejected/.test(action),
      );
      expect(decisions).toHaveLength(1);
    });

    it('keeps the audit trail append-only', async () => {
      const { id } = await submitValid();
      await expect(
        dataSource.query(`UPDATE audit_logs SET action = 'tampered' WHERE target_id = $1`, [id]),
      ).rejects.toThrow(/append-only/);
      await expect(
        dataSource.query('DELETE FROM audit_logs WHERE target_id = $1', [id]),
      ).rejects.toThrow(/append-only/);
    });
  });

  describe('eligibility', () => {
    it('gives approved technicians no access to customer requests', async () => {
      const customer = await signIn(app);
      const kima = await dataSource.getRepository(ServiceArea).findOneByOrFail({ slug: 'kima' });
      const service = await dataSource.query(`SELECT id FROM services LIMIT 1`);
      const created = await http()
        .post(`${API}/requests`)
        .set(bearer(customer))
        .set('Idempotency-Key', randomUUID())
        .send({
          serviceId: service[0].id,
          description: 'الكهرباء تفصل في المطبخ',
          address: { areaId: kima.id, details: 'شارع النيل، عمارة 3' },
          schedule: { type: 'asap' },
        })
        .expect(201);
      const { id } = await submitValid();
      await review(admin, id, 'approve').expect(200);
      await http().get(`${API}/requests/${created.body.id}`).set(bearer(applicant)).expect(403);
      await http().get(`${API}/requests`).set(bearer(applicant)).expect(403);
    });
  });
});
