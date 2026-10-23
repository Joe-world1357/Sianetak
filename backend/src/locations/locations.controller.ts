import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Public } from '../auth/decorators/public.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { ApiError } from '../common/errors/api-error';
import { User, UserRole } from '../users/user.entity';
import { AddressInputDto } from './dto/address.dto';
import { LocationsService } from './locations.service';

const notFound = () => new ApiError(HttpStatus.NOT_FOUND, 'ADDRESS_NOT_FOUND', 'Address not found');

@Controller('service-areas')
@Public()
export class ServiceAreasController {
  constructor(private readonly locations: LocationsService) {}

  @Get()
  async list() {
    return { items: await this.locations.listAreas() };
  }
}

/** Saved addresses belong to customers (FR-AUTH-04). */
@Controller('me/addresses')
@Roles(UserRole.Customer)
export class AddressesController {
  constructor(private readonly locations: LocationsService) {}

  @Get()
  async list(@CurrentUser() user: User) {
    return { items: await this.locations.listAddresses(user.id) };
  }

  @Post()
  create(@CurrentUser() user: User, @Body() dto: AddressInputDto) {
    return this.locations.createAddress(user.id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ exceptionFactory: notFound })) id: string,
  ) {
    await this.locations.deleteAddress(user.id, id);
  }
}
