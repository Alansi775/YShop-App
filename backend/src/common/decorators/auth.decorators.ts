import { createParamDecorator, ExecutionContext, SetMetadata } from '@nestjs/common';

import type { Role } from '../../../generated/prisma/client';

export interface AuthUser {
  id: string;
  roles: Role[];
}

export const IS_PUBLIC = 'isPublic';
/** Opens a route to signed-out callers (everything else needs a token). */
export const Public = () => SetMetadata(IS_PUBLIC, true);

export const ROLES = 'roles';
/** Limits a route to callers holding at least one of these roles. */
export const Roles = (...roles: Role[]) => SetMetadata(ROLES, roles);

export const CurrentUser = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): AuthUser => ctx.switchToHttp().getRequest().user,
);
