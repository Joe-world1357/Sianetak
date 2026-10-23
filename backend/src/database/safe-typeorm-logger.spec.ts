import { Logger } from '@nestjs/common';
import { SafeTypeOrmLogger } from './safe-typeorm-logger';

describe('SafeTypeOrmLogger', () => {
  it('logs failing SQL without its parameters', () => {
    const spy = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
    const typeormLogger = new SafeTypeOrmLogger() as unknown as {
      logQueryError: (e: string, q: string, p: unknown[]) => void;
    };
    // TypeORM passes parameters as a third argument; they must never be written.
    typeormLogger.logQueryError('boom', 'INSERT INTO users (phone) VALUES ($1)', ['+201012345678']);
    const logged = spy.mock.calls.map((c) => String(c[0])).join('\n');
    expect(logged).toContain('INSERT INTO users');
    expect(logged).not.toContain('+201012345678');
    spy.mockRestore();
  });
});
