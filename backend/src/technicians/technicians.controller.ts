import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  Query,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { Roles } from '../auth/decorators/roles.decorator';
import { ApiError } from '../common/errors/api-error';
import { User, UserRole } from '../users/user.entity';
import {
  ApproveApplicationDto,
  DecisionReasonDto,
  ListApplicationsDto,
  SubmitApplicationDto,
} from './dto/application.dto';
import { TechniciansService } from './technicians.service';

const notFound = () =>
  new ApiError(HttpStatus.NOT_FOUND, 'APPLICATION_NOT_FOUND', 'Application not found');
const idPipe = new ParseUUIDPipe({ exceptionFactory: notFound });

/** The signed-in user's own technician application (FR-AUTH-06). */
@Controller('technician/application')
@Roles(UserRole.Customer, UserRole.Technician)
export class TechnicianApplicationController {
  constructor(private readonly technicians: TechniciansService) {}

  @Get()
  get(@CurrentUser() user: User) {
    return this.technicians.getOwn(user);
  }

  /** Submit, or resubmit after rejection. Idempotent for an identical pending submission. */
  @Put()
  async submit(
    @CurrentUser() user: User,
    @Body() dto: SubmitApplicationDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { created, application } = await this.technicians.submit(user, dto);
    res.status(created ? HttpStatus.CREATED : HttpStatus.OK);
    return { application, requirements: this.technicians.requirements() };
  }
}

/** Reviewer queue and decisions (FR-ADM-03). Admin only, enforced server-side. */
@Controller('admin/technician-applications')
@Roles(UserRole.Admin)
export class AdminTechnicianApplicationsController {
  constructor(private readonly technicians: TechniciansService) {}

  @Get()
  list(@Query() query: ListApplicationsDto) {
    return this.technicians.listForReview(query.status, query.limit, query.offset);
  }

  @Get(':id')
  get(@Param('id', idPipe) id: string) {
    return this.technicians.getForReview(id);
  }

  @Post(':id/approve')
  @HttpCode(HttpStatus.OK)
  approve(
    @CurrentUser() admin: User,
    @Param('id', idPipe) id: string,
    @Body() dto: ApproveApplicationDto,
  ) {
    return this.technicians.review(admin, id, 'approve', dto.note ?? null);
  }

  @Post(':id/reject')
  @HttpCode(HttpStatus.OK)
  reject(
    @CurrentUser() admin: User,
    @Param('id', idPipe) id: string,
    @Body() dto: DecisionReasonDto,
  ) {
    return this.technicians.review(admin, id, 'reject', dto.reason);
  }

  @Post(':id/suspend')
  @HttpCode(HttpStatus.OK)
  suspend(
    @CurrentUser() admin: User,
    @Param('id', idPipe) id: string,
    @Body() dto: DecisionReasonDto,
  ) {
    return this.technicians.review(admin, id, 'suspend', dto.reason);
  }
}
