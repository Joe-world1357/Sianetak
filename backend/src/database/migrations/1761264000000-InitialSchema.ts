import { MigrationInterface, QueryRunner } from 'typeorm';

/** Sprint 1 schema: users/roles, OTP challenges, refresh tokens, service catalog. */
export class InitialSchema1761264000000 implements MigrationInterface {
  name = 'InitialSchema1761264000000';

  public async up(q: QueryRunner): Promise<void> {
    await q.query(`CREATE EXTENSION IF NOT EXISTS pgcrypto`);

    await q.query(`
      CREATE TABLE users (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        phone varchar(16) NOT NULL,
        name varchar(80),
        role varchar(16) NOT NULL DEFAULT 'customer',
        status varchar(16) NOT NULL DEFAULT 'active',
        phone_verified_at timestamptz,
        last_sign_in_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT now(),
        updated_at timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT uq_users_phone UNIQUE (phone),
        CONSTRAINT chk_users_phone_e164 CHECK (phone ~ '^\\+[1-9][0-9]{7,14}$'),
        CONSTRAINT chk_users_role CHECK (role IN ('customer', 'technician', 'admin')),
        CONSTRAINT chk_users_status CHECK (status IN ('active', 'suspended'))
      )`);

    await q.query(`
      CREATE TABLE otp_challenges (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        phone varchar(16) NOT NULL,
        code_hash varchar(64) NOT NULL,
        attempts int NOT NULL DEFAULT 0,
        max_attempts int NOT NULL,
        expires_at timestamptz NOT NULL,
        consumed_at timestamptz,
        invalidated_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT chk_otp_attempts CHECK (attempts >= 0 AND attempts <= max_attempts)
      )`);
    await q.query(
      `CREATE INDEX idx_otp_challenges_phone_created ON otp_challenges (phone, created_at)`,
    );

    await q.query(`
      CREATE TABLE refresh_tokens (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        token_hash varchar(64) NOT NULL,
        family_id uuid NOT NULL,
        expires_at timestamptz NOT NULL,
        revoked_at timestamptz,
        created_at timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT uq_refresh_tokens_hash UNIQUE (token_hash)
      )`);
    await q.query(`CREATE INDEX idx_refresh_tokens_user ON refresh_tokens (user_id)`);
    await q.query(`CREATE INDEX idx_refresh_tokens_family ON refresh_tokens (family_id)`);

    await q.query(`
      CREATE TABLE service_categories (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        slug varchar(64) NOT NULL,
        name_ar varchar(80) NOT NULL,
        name_en varchar(80) NOT NULL,
        description_ar text,
        description_en text,
        icon_key varchar(40),
        sort_order int NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        is_sample boolean NOT NULL DEFAULT false,
        created_at timestamptz NOT NULL DEFAULT now(),
        updated_at timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT uq_service_categories_slug UNIQUE (slug),
        CONSTRAINT chk_service_categories_slug CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
      )`);

    await q.query(`
      CREATE TABLE services (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        category_id uuid NOT NULL REFERENCES service_categories(id) ON DELETE RESTRICT,
        slug varchar(64) NOT NULL,
        name_ar varchar(120) NOT NULL,
        name_en varchar(120) NOT NULL,
        description_ar text,
        description_en text,
        pricing_type varchar(24) NOT NULL,
        price_min_minor int,
        price_max_minor int,
        currency char(3) NOT NULL DEFAULT 'EGP',
        sort_order int NOT NULL DEFAULT 0,
        is_active boolean NOT NULL DEFAULT true,
        is_sample boolean NOT NULL DEFAULT false,
        created_at timestamptz NOT NULL DEFAULT now(),
        updated_at timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT uq_services_slug UNIQUE (slug),
        CONSTRAINT chk_services_slug CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
        CONSTRAINT chk_services_currency CHECK (currency = 'EGP'),
        CONSTRAINT chk_services_pricing CHECK (
          (pricing_type = 'inspection_required'
             AND price_min_minor IS NULL AND price_max_minor IS NULL)
          OR
          (pricing_type = 'indicative'
             AND price_min_minor IS NOT NULL AND price_max_minor IS NOT NULL
             AND price_min_minor > 0 AND price_max_minor >= price_min_minor)
        )
      )`);
    await q.query(`CREATE INDEX idx_services_category ON services (category_id, sort_order)`);
  }

  public async down(q: QueryRunner): Promise<void> {
    await q.query(`DROP TABLE services`);
    await q.query(`DROP TABLE service_categories`);
    await q.query(`DROP TABLE refresh_tokens`);
    await q.query(`DROP TABLE otp_challenges`);
    await q.query(`DROP TABLE users`);
  }
}
