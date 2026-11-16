import { Body, Controller, Get, HttpCode, Post, Req } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';

import type { AuthUser } from '../../common/decorators/auth.decorators';
import { CurrentUser, Public } from '../../common/decorators/auth.decorators';
import { AuthService, ClientInfo } from './auth.service';
import { AppleAuthDto, ChangePasswordDto, GoogleAuthDto, LoginDto, RefreshDto, RegisterDto } from './dto/auth.dto';

const client = (req: Request): ClientInfo => ({ userAgent: req.headers['user-agent'], ip: req.ip });

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Public() @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('register')
  register(@Body() dto: RegisterDto, @Req() req: Request) {
    return this.auth.register(dto, client(req));
  }

  @Public() @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('login') @HttpCode(200)
  login(@Body() dto: LoginDto, @Req() req: Request) {
    return this.auth.login(dto, client(req));
  }

  @Public() @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @Post('apple') @HttpCode(200)
  apple(@Body() dto: AppleAuthDto, @Req() req: Request) {
    return this.auth.apple(dto, client(req));
  }

  @Public() @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @Post('google') @HttpCode(200)
  google(@Body() dto: GoogleAuthDto, @Req() req: Request) {
    return this.auth.google(dto.idToken, client(req));
  }

  @Public()
  @Post('refresh') @HttpCode(200)
  refresh(@Body() dto: RefreshDto, @Req() req: Request) {
    return this.auth.refresh(dto.refreshToken, client(req));
  }

  @Public()
  @Post('logout') @HttpCode(204)
  async logout(@Body() dto: RefreshDto) {
    await this.auth.logout(dto.refreshToken);
  }

  @ApiBearerAuth()
  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return this.auth.me(user.id);
  }

  @ApiBearerAuth()
  @Post('change-password') @HttpCode(204)
  async changePassword(@CurrentUser() user: AuthUser, @Body() dto: ChangePasswordDto) {
    await this.auth.changePassword(user.id, dto);
  }
}
