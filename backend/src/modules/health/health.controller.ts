import { Controller, Get } from '@nestjs/common';

import { Public } from '../../common/decorators/auth.decorators';
import { PrismaService } from '../../prisma/prisma.service';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  /** The app's server discovery pings this to pick a reachable base URL. */
  @Public()
  @Get()
  async check() {
    const started = Date.now();
    await this.prisma.$queryRaw`SELECT 1`;
    return { status: 'ok', db: 'ok', dbLatencyMs: Date.now() - started, time: new Date().toISOString() };
  }
}
