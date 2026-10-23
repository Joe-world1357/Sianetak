/**
 * Operator CLI: grant the admin role to a phone number.
 *   npm run user:create-staff -- --phone 01012345678 --role admin [--name "Full name"]
 *
 * Self sign-up always creates customers. Since Sprint 2 the technician role is granted only by
 * approving a technician application, so this tool no longer grants it: a technician created
 * here would bypass verification.
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
  // The reviewer's name is shown on audited decisions, so name the account where one is given.
  const name = arg('name')?.trim();
  if (!phone || role !== UserRole.Admin) {
    console.error(
      'Usage: --phone <Egyptian mobile> --role admin [--name "Full name"]  (technicians apply in the app and are approved by an admin)',
    );
    process.exit(2);
  }
  await dataSource.initialize();
  try {
    const repo = dataSource.getRepository(User);
    const existing = await repo.findOneBy({ phone });
    const user = existing ?? repo.create({ phone, status: UserStatus.Active });
    user.role = role;
    if (name) user.name = name;
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
