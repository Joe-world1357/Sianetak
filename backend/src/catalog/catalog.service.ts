import { HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ApiError } from '../common/errors/api-error';
import { Service, ServiceCategory } from './catalog.entities';
import { presentCategory, presentServiceDetail, presentServiceSummary } from './catalog.presenter';

@Injectable()
export class CatalogService {
  constructor(
    @InjectRepository(ServiceCategory) private readonly categories: Repository<ServiceCategory>,
    @InjectRepository(Service) private readonly services: Repository<Service>,
  ) {}

  /** Active categories with their count of active services, in display order. */
  async listCategories(includeInactive = false) {
    const qb = this.categories
      .createQueryBuilder('c')
      .loadRelationCountAndMap('c.serviceCount', 'c.services', 's', (sq) =>
        includeInactive ? sq : sq.where('s.isActive = true'),
      )
      .orderBy('c.sortOrder', 'ASC')
      .addOrderBy('c.nameEn', 'ASC');
    if (!includeInactive) qb.where('c.isActive = true');
    const rows = (await qb.getMany()) as (ServiceCategory & { serviceCount: number })[];
    return rows.map((c) => ({
      ...presentCategory(c, c.serviceCount),
      ...(includeInactive ? { isActive: c.isActive } : {}),
    }));
  }

  async getCategory(slug: string) {
    const category = await this.categories.findOneBy({ slug, isActive: true });
    if (!category) {
      throw new ApiError(HttpStatus.NOT_FOUND, 'CATEGORY_NOT_FOUND', 'Category not found');
    }
    const services = await this.services.find({
      where: { categoryId: category.id, isActive: true },
      order: { sortOrder: 'ASC', nameEn: 'ASC' },
    });
    return {
      ...presentCategory(category, services.length),
      services: services.map(presentServiceSummary),
    };
  }

  async getService(slug: string) {
    const service = await this.services.findOne({
      where: { slug, isActive: true, category: { isActive: true } },
      relations: { category: true },
    });
    if (!service || !service.category) {
      throw new ApiError(HttpStatus.NOT_FOUND, 'SERVICE_NOT_FOUND', 'Service not found');
    }
    return presentServiceDetail(service as Service & { category: ServiceCategory });
  }
}
