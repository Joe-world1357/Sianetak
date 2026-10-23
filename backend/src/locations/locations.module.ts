import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AddressesController, ServiceAreasController } from './locations.controller';
import { CustomerAddress, ServiceArea } from './location.entities';
import { LocationsService } from './locations.service';

@Module({
  imports: [TypeOrmModule.forFeature([ServiceArea, CustomerAddress])],
  controllers: [ServiceAreasController, AddressesController],
  providers: [LocationsService],
  exports: [LocationsService],
})
export class LocationsModule {}
