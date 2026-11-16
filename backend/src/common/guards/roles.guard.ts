import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

import type { Role } from '../../../generated/prisma/client';
import { AuthUser, ROLES } from '../decorators/auth.decorators';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(ctx: ExecutionContext): boolean {
    const needed = this.reflector.getAllAndOverride<Role[]>(ROLES, [ctx.getHandler(), ctx.getClass()]);
    if (!needed?.length) return true;
    const user: AuthUser | undefined = ctx.switchToHttp().getRequest().user;
    if (user?.roles.some((r) => needed.includes(r) || r === 'SUPERADMIN')) return true;
    throw new ForbiddenException('You do not have access to this.');
  }
}
