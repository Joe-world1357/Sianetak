/**
 * Operator CLI: grant the technician or admin role to a phone number.
 *   npm run user:create-staff -- --phone 01012345678 --role admin
 *
 * Self sign-up always creates customers; elevated roles are granted only through this tool until
 * the admin dashboard and technician onboarding (Sprint 2) exist.
 */
import 'reflect-metadata';
import dataSource from '../database/data-source';
import { normalizeEgyptMobile, maskPhone } from '../common/phone/egypt-phone';
import { User, UserRole, UserStatus } from '../users/user.entity';

function arg(name: string) {
  const i = process.argv.indexOf(`--${name}`);
  return i >= 0 ? process.argv[i + 1] : undefined;
}

async function main() {
  const phone = normalizeEgyptMobile(arg('phone'));
  const role = arg('role') as UserRole | undefined;
  if (!phone || !role || ![UserRole.Technician, UserRole.Admin].includes(role)) {
    console.error('Usage: --phone <Egyptian mobile> --role <technician|admin>');
    process.exit(2);
  }
  await dataSource.initialize();
  try {
    const repo = dataSource.getRepository(User);
    const existing = await repo.findOneBy({ phone });
    const user = existing ?? repo.create({ phone, status: UserStatus.Active });
    user.role = role;
    await repo.save(user);
    console.log(`${existing ? 'Updated' : 'Created'} ${role} account for ${maskPhone(phone)}`);
  } finally {
    await dataSource.destroy();
  }
}

main().catch((err) => {
  console.error('Failed:', (err as Error).message);
  process.exit(1);
});
