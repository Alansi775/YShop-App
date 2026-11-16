import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

import type { Role } from '../../../../generated/prisma/client';
import type { AuthUser } from '../../../common/decorators/auth.decorators';

interface AccessPayload {
  sub: string;
  roles: Role[];
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: config.getOrThrow<string>('jwt.accessSecret'),
    });
  }

  validate(payload: AccessPayload): AuthUser {
    if (!payload?.sub) throw new UnauthorizedException();
    return { id: payload.sub, roles: payload.roles ?? [] };
  }
}
