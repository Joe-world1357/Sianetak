import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminCatalogController, CatalogController } from './catalog.controller';
import { Service, ServiceCategory } from './catalog.entities';
import { CatalogService } from './catalog.service';

@Module({
  imports: [TypeOrmModule.forFeature([ServiceCategory, Service])],
  controllers: [CatalogController, AdminCatalogController],
  providers: [CatalogService],
})
export class CatalogModule {}
