import { Controller, Get, Header, Param } from '@nestjs/common';
import { Public } from '../auth/decorators/public.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { UserRole } from '../users/user.entity';
import { CatalogService } from './catalog.service';
import { SlugPipe } from './slug.pipe';

/** Guest-accessible catalog (FR-AUTH-02, FR-REQ-01, FR-REQ-06). */
@Controller('catalog')
@Public()
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Get('categories')
  @Header('Cache-Control', 'public, max-age=60')
  async categories() {
    return { items: await this.catalog.listCategories() };
  }

  @Get('categories/:slug')
  @Header('Cache-Control', 'public, max-age=60')
  category(@Param('slug', SlugPipe) slug: string) {
    return this.catalog.getCategory(slug);
  }

  @Get('services/:slug')
  @Header('Cache-Control', 'public, max-age=60')
  service(@Param('slug', SlugPipe) slug: string) {
    return this.catalog.getService(slug);
  }
}

/** Admin view of the catalog, including inactive entries. Read-only in Sprint 1. */
@Controller('admin/catalog')
@Roles(UserRole.Admin)
export class AdminCatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Get('categories')
  async categories() {
    return { items: await this.catalog.listCategories(true) };
  }
}
