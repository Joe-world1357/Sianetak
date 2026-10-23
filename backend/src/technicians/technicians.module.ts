import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LocationsModule } from '../locations/locations.module';
import { MediaModule } from '../media/media.module';
import { ApprovedTechnicianGuard } from './approved-technician.guard';
import {
  TechnicianDocument,
  TechnicianProfile,
  TechnicianServiceArea,
  TechnicianSpecialty,
} from './technician.entities';
import {
  AdminTechnicianApplicationsController,
  TechnicianApplicationController,
} from './technicians.controller';
import { TechniciansService } from './technicians.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      TechnicianProfile,
      TechnicianSpecialty,
      TechnicianServiceArea,
      TechnicianDocument,
    ]),
    LocationsModule,
    MediaModule,
  ],
  controllers: [TechnicianApplicationController, AdminTechnicianApplicationsController],
  providers: [TechniciansService, ApprovedTechnicianGuard],
  exports: [TechniciansService, ApprovedTechnicianGuard],
})
export class TechniciansModule {}
