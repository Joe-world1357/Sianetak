import {
  Body,
  Controller,
  Get,
  Headers,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Public } from '../auth/decorators/public.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { ApiError } from '../common/errors/api-error';
import { User, UserRole } from '../users/user.entity';
import { CreateRequestDto } from './dto/create-request.dto';
import { ListRequestsDto } from './dto/list-requests.dto';
import { RequestsService } from './requests.service';

const notFound = () => new ApiError(HttpStatus.NOT_FOUND, 'REQUEST_NOT_FOUND', 'Request not found');

/** Request form configuration; public so the form can render before sign-in. */
@Controller('requests/options')
@Public()
export class RequestOptionsController {
  constructor(private readonly requests: RequestsService) {}

  @Get()
  options() {
    return this.requests.options();
  }
}

/** Customer service requests (FR-REQ-02–07, FR-REQ-10). Signing in is required (FR-AUTH-03). */
@Controller('requests')
@Roles(UserRole.Customer)
export class RequestsController {
  constructor(private readonly requests: RequestsService) {}

  @Post()
  async create(
    @CurrentUser() user: User,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Body() dto: CreateRequestDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { created, request } = await this.requests.create(user, idempotencyKey, dto);
    res.status(created ? HttpStatus.CREATED : HttpStatus.OK);
    if (!created) res.setHeader('Idempotent-Replayed', 'true');
    return request;
  }

  @Get()
  list(@CurrentUser() user: User, @Query() query: ListRequestsDto) {
    return this.requests.listForCustomer(user, query.limit, query.cursor);
  }

  @Get(':id')
  get(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ exceptionFactory: notFound })) id: string,
  ) {
    return this.requests.getForCustomer(user, id);
  }
}
