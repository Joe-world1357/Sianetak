import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Sprint 2 schema: service areas, saved addresses, private media, service requests with photo
 * and event history, technician applications with specialties/areas/documents, and an
 * append-only audit log.
 */
export class RequestsAndOnboarding1761350400000 implements MigrationInterface {
  name = 'RequestsAndOnboarding1761350400000';

  public async up(q: QueryRunner): Promise<void> {
    await q.query(`
      CREATE TABLE service_areas (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        slug varchar(64) NOT NULL,
        name_ar varchar(80) NOT NULL,
        name_en varchar(80) NOT NULL,
        sort_order int NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        is_sample boolean NOT NULL DEFAULT false,
        created_at timestamptz NOT NULL DEFAULT now(),
        updated_at timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT uq_service_areas_slug UNIQUE (slug),
        CONSTRAINT chk_service_areas_slug CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
      )`);

    await q.query(`
      CREATE TABLE customer_addresses (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        label varchar(40),
        area_id uuid NOT NULL REFERENCES service_areas(id) ON DELETE RESTRICT,
        details varchar(300) NOT NULL,
        landmark varchar(150),
        latitude double precision,
        longitude double precision,
        deleted_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT now(),
        updated_at timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT chk_customer_addresses_coords CHECK (
          (latitude IS NULL AND longitude IS NULL)
          OR (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
        )
      )`);
    await q.query(
      `CREATE INDEX idx_customer_addresses_user ON customer_addresses (user_id) WHERE deleted_at IS NULL`,
    );

    await q.query(`
      CREATE TABLE media_files (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        owner_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
        purpose varchar(32) NOT NULL,
        content_type varchar(64) NOT NULL,
        byte_size int NOT NULL,
        sha256 char(64) NOT NULL,
        storage_key varchar(200) NOT NULL,
        attached_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT uq_media_files_storage_key UNIQUE (storage_key),
        CONSTRAINT chk_media_files_purpose CHECK (purpose IN ('request_photo', 'technician_document')),
        CONSTRAINT chk_media_files_type CHECK (
          content_type IN ('image/jpeg', 'image/png', 'application/pdf')
        ),
        CONSTRAINT chk_media_files_size CHECK (byte_size > 0)
      )`);
    await q.query(`CREATE INDEX idx_media_files_owner ON media_files (owner_id, attached_at)`);

    await q.query(`
      CREATE TABLE service_requests (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        reference varchar(20) NOT NULL,
        customer_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
        service_id uuid NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
        status varchar(24) NOT NULL DEFAULT 'submitted',
        description text NOT NULL,
        address_id uuid REFERENCES customer_addresses(id) ON DELETE SET NULL,
        area_id uuid NOT NULL REFERENCES service_areas(id) ON DELETE RESTRICT,
        address_details varchar(300) NOT NULL,
        address_landmark varchar(150),
        latitude double precision,
        longitude double precision,
        schedule_type varchar(16) NOT NULL,
        scheduled_from timestamptz,
        scheduled_to timestamptz,
        pricing_type varchar(24) NOT NULL,
        price_min_minor int,
        price_max_minor int,
        inspection_fee_minor int,
        currency char(3) NOT NULL DEFAULT 'EGP',
        idempotency_key uuid NOT NULL,
        request_hash char(64) NOT NULL,
        submitted_at timestamptz NOT NULL DEFAULT now(),
        created_at timestamptz NOT NULL DEFAULT now(),
        updated_at timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT uq_service_requests_reference UNIQUE (reference),
        CONSTRAINT uq_service_requests_idempotency UNIQUE (customer_id, idempotency_key),
        CONSTRAINT chk_service_requests_status CHECK (status IN ('submitted')),
        CONSTRAINT chk_service_requests_description CHECK (char_length(description) BETWEEN 1 AND 2000),
        CONSTRAINT chk_service_requests_currency CHECK (currency = 'EGP'),
        CONSTRAINT chk_service_requests_coords CHECK (
          (latitude IS NULL AND longitude IS NULL)
          OR (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
        ),
        CONSTRAINT chk_service_requests_schedule CHECK (
          (schedule_type = 'asap' AND scheduled_from IS NULL AND scheduled_to IS NULL)
          OR (schedule_type = 'scheduled' AND scheduled_from IS NOT NULL
              AND scheduled_to IS NOT NULL AND scheduled_to > scheduled_from)
        ),
        CONSTRAINT chk_service_requests_fee CHECK (inspection_fee_minor IS NULL OR inspection_fee_minor >= 0)
      )`);
    await q.query(
      `CREATE INDEX idx_service_requests_customer ON service_requests (customer_id, submitted_at DESC)`,
    );

    await q.query(`
      CREATE TABLE service_request_photos (
        request_id uuid NOT NULL REFERENCES service_requests(id) ON DELETE CASCADE,
        media_id uuid NOT NULL REFERENCES media_files(id) ON DELETE RESTRICT,
        position int NOT NULL,
        PRIMARY KEY (request_id, media_id),
        CONSTRAINT uq_service_request_photos_media UNIQUE (media_id)
      )`);

    await q.query(`
      CREATE TABLE service_request_events (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        request_id uuid NOT NULL REFERENCES service_requests(id) ON DELETE CASCADE,
        actor_id uuid REFERENCES users(id) ON DELETE RESTRICT,
        from_status varchar(24),
        to_status varchar(24) NOT NULL,
        reason text,
        created_at timestamptz NOT NULL DEFAULT now()
      )`);
    await q.query(
      `CREATE INDEX idx_service_request_events_request ON service_request_events (request_id, created_at)`,
    );

    await q.query(`
      CREATE TABLE technician_profiles (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
        full_name varchar(80) NOT NULL,
        years_experience int,
        bio text,
        status varchar(24) NOT NULL,
        submitted_at timestamptz NOT NULL,
        reviewed_at timestamptz,
        reviewed_by uuid REFERENCES users(id) ON DELETE RESTRICT,
        decision_reason text,
        submission_hash char(64) NOT NULL,
        created_at timestamptz NOT NULL DEFAULT now(),
        updated_at timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT uq_technician_profiles_user UNIQUE (user_id),
        CONSTRAINT chk_technician_profiles_status CHECK (
          status IN ('pending_review', 'approved', 'rejected', 'suspended')
        ),
        CONSTRAINT chk_technician_profiles_years CHECK (
          years_experience IS NULL OR years_experience BETWEEN 0 AND 60
        ),
        CONSTRAINT chk_technician_profiles_bio CHECK (bio IS NULL OR char_length(bio) <= 1000),
        CONSTRAINT chk_technician_profiles_reason CHECK (
          status NOT IN ('rejected', 'suspended') OR decision_reason IS NOT NULL
        ),
        CONSTRAINT chk_technician_profiles_reviewer CHECK (reviewed_by IS NULL OR reviewed_by <> user_id)
      )`);
    await q.query(
      `CREATE INDEX idx_technician_profiles_status ON technician_profiles (status, submitted_at)`,
    );

    await q.query(`
      CREATE TABLE technician_specialties (
        profile_id uuid NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
        category_id uuid NOT NULL REFERENCES service_categories(id) ON DELETE RESTRICT,
        PRIMARY KEY (profile_id, category_id)
      )`);
    await q.query(`
      CREATE TABLE technician_service_areas (
        profile_id uuid NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
        area_id uuid NOT NULL REFERENCES service_areas(id) ON DELETE RESTRICT,
        PRIMARY KEY (profile_id, area_id)
      )`);
    await q.query(`
      CREATE TABLE technician_documents (
        profile_id uuid NOT NULL REFERENCES technician_profiles(id) ON DELETE CASCADE,
        media_id uuid NOT NULL REFERENCES media_files(id) ON DELETE RESTRICT,
        kind varchar(24) NOT NULL,
        PRIMARY KEY (profile_id, media_id),
        CONSTRAINT uq_technician_documents_media UNIQUE (media_id),
        CONSTRAINT chk_technician_documents_kind CHECK (kind IN ('identity', 'qualification', 'other'))
      )`);

    await q.query(`
      CREATE TABLE audit_logs (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        actor_id uuid REFERENCES users(id) ON DELETE RESTRICT,
        action varchar(64) NOT NULL,
        target_type varchar(32) NOT NULL,
        target_id uuid NOT NULL,
        metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
        created_at timestamptz NOT NULL DEFAULT now()
      )`);
    await q.query(
      `CREATE INDEX idx_audit_logs_target ON audit_logs (target_type, target_id, created_at)`,
    );
    // The audit trail is append-only: rows cannot be changed or removed through normal SQL.
    await q.query(`
      CREATE FUNCTION audit_logs_append_only() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'audit_logs is append-only';
      END;
      $$ LANGUAGE plpgsql`);
    await q.query(`
      CREATE TRIGGER trg_audit_logs_append_only
        BEFORE UPDATE OR DELETE ON audit_logs
        FOR EACH ROW EXECUTE FUNCTION audit_logs_append_only()`);
  }

  public async down(q: QueryRunner): Promise<void> {
    await q.query(`DROP TABLE audit_logs`);
    await q.query(`DROP FUNCTION audit_logs_append_only`);
    await q.query(`DROP TABLE technician_documents`);
    await q.query(`DROP TABLE technician_service_areas`);
    await q.query(`DROP TABLE technician_specialties`);
    await q.query(`DROP TABLE technician_profiles`);
    await q.query(`DROP TABLE service_request_events`);
    await q.query(`DROP TABLE service_request_photos`);
    await q.query(`DROP TABLE service_requests`);
    await q.query(`DROP TABLE media_files`);
    await q.query(`DROP TABLE customer_addresses`);
    await q.query(`DROP TABLE service_areas`);
  }
}
