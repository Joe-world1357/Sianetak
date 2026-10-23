import type { User } from './user.entity';

/** The signed-in user's own profile. Only ever returned to that user. */
export function presentMe(user: User) {
  return {
    id: user.id,
    phone: user.phone,
    name: user.name,
    role: user.role,
    status: user.status,
    createdAt: user.createdAt.toISOString(),
  };
}
