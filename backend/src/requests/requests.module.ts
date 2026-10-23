import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LocationsModule } from '../locations/locations.module';
import { MediaModule } from '../media/media.module';
import { ServiceRequest, ServiceRequestEvent, ServiceRequestPhoto } from './request.entities';
import { RequestOptionsController, RequestsController } from './requests.controller';
import { RequestsService } from './requests.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([ServiceRequest, ServiceRequestPhoto, ServiceRequestEvent]),
    LocationsModule,
    MediaModule,
  ],
  // Options first, so `/requests/options` is not captured by `/requests/:id`.
  controllers: [RequestOptionsController, RequestsController],
  providers: [RequestsService],
})
export class RequestsModule {}
