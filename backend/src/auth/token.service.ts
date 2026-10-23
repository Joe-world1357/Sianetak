import { HttpStatus, Inject, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { DataSource, EntityManager, IsNull } from 'typeorm';
import { ApiError } from '../common/errors/api-error';
import { APP_CONFIG, AppConfig } from '../config/env.validation';
import { User, UserStatus } from '../users/user.entity';
import { RefreshToken } from './refresh-token.entity';

export interface AccessTokenPayload {
  sub: string;
  role: string;
  typ: 'access';
}

export interface TokenPair {
  accessToken: string;
  accessTokenExpiresIn: number;
  refreshToken: string;
  refreshTokenExpiresAt: string;
}

const sha256 = (value: string) => createHash('sha256').update(value).digest('hex');

@Injectable()
export class TokenService {
  constructor(
    private readonly jwt: JwtService,
    private readonly dataSource: DataSource,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  async issue(em: EntityManager, user: User, familyId: string = randomUUID()): Promise<TokenPair> {
    const payload: AccessTokenPayload = { sub: user.id, role: user.role, typ: 'access' };
    const accessToken = await this.jwt.signAsync(payload);
    const refreshToken = randomBytes(32).toString('base64url');
    const expiresAt = new Date(Date.now() + this.config.refreshTokenTtlDays * 86_400_000);
    await em.insert(RefreshToken, {
      userId: user.id,
      tokenHash: sha256(refreshToken),
      familyId,
      expiresAt,
    });
    return {
      accessToken,
      accessTokenExpiresIn: this.config.jwt.accessTtlSeconds,
      refreshToken,
      refreshTokenExpiresAt: expiresAt.toISOString(),
    };
  }

  /** Rotates a refresh token. Reusing a rotated token revokes the whole family. */
  async rotate(refreshToken: string): Promise<{ user: User; tokens: TokenPair }> {
    const invalid = () =>
      new ApiError(HttpStatus.UNAUTHORIZED, 'REFRESH_TOKEN_INVALID', 'Sign in again');

    const outcome = await this.dataSource.transaction(async (em) => {
      const row = await em.findOne(RefreshToken, {
        where: { tokenHash: sha256(refreshToken) },
        lock: { mode: 'pessimistic_write' },
      });
      if (!row) return { error: invalid() };
      const now = new Date();
      if (row.revokedAt) {
        await em.update(
          RefreshToken,
          { familyId: row.familyId, revokedAt: IsNull() },
          { revokedAt: now },
        );
        return { error: invalid() };
      }
      if (row.expiresAt <= now) return { error: invalid() };

      const user = await em.findOneBy(User, { id: row.userId });
      if (!user) return { error: invalid() };
      if (user.status !== UserStatus.Active) {
        await em.update(RefreshToken, { id: row.id }, { revokedAt: now });
        return {
          error: new ApiError(HttpStatus.FORBIDDEN, 'ACCOUNT_SUSPENDED', 'Account is suspended'),
        };
      }
      await em.update(RefreshToken, { id: row.id }, { revokedAt: now });
      return { user, tokens: await this.issue(em, user, row.familyId) };
    });
    // Throw after commit so the family revocation above is persisted.
    if ('error' in outcome) throw outcome.error;
    return outcome;
  }

  /** Revokes a refresh token. Idempotent and silent about unknown tokens. */
  async revoke(refreshToken: string): Promise<void> {
    await this.dataSource
      .getRepository(RefreshToken)
      .update({ tokenHash: sha256(refreshToken), revokedAt: IsNull() }, { revokedAt: new Date() });
  }
}
