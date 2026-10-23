import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, Repository } from 'typeorm';
import { User, UserRole, UserStatus } from './user.entity';

@Injectable()
export class UsersService {
  constructor(@InjectRepository(User) private readonly repo: Repository<User>) {}

  findById(id: string) {
    return this.repo.findOneBy({ id });
  }

  /**
   * Returns the user for a verified phone, creating a customer account on first sign-in.
   * New accounts are always customers; technician/admin roles are granted only by staff tooling.
   */
  async findOrCreateCustomerByPhone(em: EntityManager, phone: string, now: Date): Promise<User> {
    await em
      .createQueryBuilder()
      .insert()
      .into(User)
      .values({ phone, role: UserRole.Customer, status: UserStatus.Active })
      .orIgnore()
      .execute();
    const user = await em.findOneByOrFail(User, { phone });
    user.phoneVerifiedAt ??= now;
    user.lastSignInAt = now;
    return em.save(user);
  }

  async updateName(user: User, name: string) {
    user.name = name;
    return this.repo.save(user);
  }
}
