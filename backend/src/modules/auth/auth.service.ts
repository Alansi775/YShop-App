import { createHash, randomBytes } from 'node:crypto';

import { ConflictException, ForbiddenException, Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';

import type { User } from '../../../generated/prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { AppleAuthDto, ChangePasswordDto, LoginDto, RegisterDto } from './dto/auth.dto';
import { ExternalIdentity, verifyApple, verifyGoogle } from './identity-providers';
import { hashPassword, verifyPassword } from './passwords';

export interface ClientInfo {
  userAgent?: string;
  ip?: string;
}

export interface AuthResult {
  accessToken: string;
  refreshToken: string;
  user: PublicUser;
}

export type PublicUser = ReturnType<typeof toPublicUser>;

export function toPublicUser(u: User) {
  return {
    id: u.id,
    email: u.email,
    emailVerified: u.emailVerified,
    firstName: u.firstName,
    lastName: u.lastName,
    phone: u.phone,
    avatarUrl: u.avatarUrl,
    roles: u.roles,
    hasPassword: !!u.passwordHash,
    createdAt: u.createdAt,
  };
}

const sha256 = (s: string) => createHash('sha256').update(s).digest('hex');

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  // ── E-mail + password ────────────────────────────────────────────────────

  async register(dto: RegisterDto, client: ClientInfo): Promise<AuthResult> {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException({ code: 'EMAIL_TAKEN', message: 'An account with this e-mail already exists.' });
    }
    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        passwordHash: await hashPassword(dto.password),
        firstName: dto.firstName,
        lastName: dto.lastName,
        phone: dto.phone,
      },
    });
    return this.issue(user, client);
  }

  async login(dto: LoginDto, client: ClientInfo): Promise<AuthResult> {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    // Same message and similar cost for "no such user" and "wrong password".
    const check = user?.passwordHash
      ? await verifyPassword(user.passwordHash, dto.password)
      : (await hashPassword(dto.password), { ok: false, needsRehash: false });
    if (!user || !check.ok || user.deletedAt) {
      throw new UnauthorizedException({ code: 'BAD_CREDENTIALS', message: 'E-mail or password is incorrect.' });
    }
    this.assertActive(user);
    if (check.needsRehash) {
      await this.prisma.user.update({ where: { id: user.id }, data: { passwordHash: await hashPassword(dto.password) } });
    }
    return this.issue(user, client);
  }

  async changePassword(userId: string, dto: ChangePasswordDto): Promise<void> {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    if (user.passwordHash) {
      const { ok } = await verifyPassword(user.passwordHash, dto.currentPassword);
      if (!ok) throw new UnauthorizedException({ code: 'BAD_CREDENTIALS', message: 'Current password is incorrect.' });
    }
    await this.prisma.$transaction([
      this.prisma.user.update({ where: { id: userId }, data: { passwordHash: await hashPassword(dto.newPassword) } }),
      // Every other device signs in again.
      this.prisma.session.updateMany({ where: { userId, revokedAt: null }, data: { revokedAt: new Date() } }),
    ]);
  }

  // ── Apple / Google ───────────────────────────────────────────────────────

  async apple(dto: AppleAuthDto, client: ClientInfo): Promise<AuthResult> {
    let identity: ExternalIdentity;
    try {
      identity = await verifyApple(dto.identityToken, this.config.getOrThrow<string[]>('apple.clientIds'));
    } catch (e) {
      this.logger.warn(`Apple token rejected: ${(e as Error).message}`);
      throw new UnauthorizedException({ code: 'APPLE_INVALID', message: 'Could not sign in with Apple. Try again.' });
    }
    return this.signInExternal('appleSub', { ...identity, firstName: dto.firstName, lastName: dto.lastName }, client);
  }

  async google(idToken: string, client: ClientInfo): Promise<AuthResult> {
    let identity: ExternalIdentity;
    try {
      identity = await verifyGoogle(idToken, this.config.getOrThrow<string[]>('google.clientIds'));
    } catch (e) {
      this.logger.warn(`Google token rejected: ${(e as Error).message}`);
      throw new UnauthorizedException({ code: 'GOOGLE_INVALID', message: 'Could not sign in with Google. Try again.' });
    }
    return this.signInExternal('googleSub', identity, client);
  }

  /**
   * One tap, no forms: the provider's id finds the account; failing that the
   * (provider-verified) e-mail finds and links it; failing that a new
   * customer account is opened.
   */
  private async signInExternal(
    key: 'appleSub' | 'googleSub',
    id: ExternalIdentity,
    client: ClientInfo,
  ): Promise<AuthResult> {
    let user =
      (await this.prisma.user.findUnique({ where: { [key]: id.sub } as { appleSub: string } })) ??
      (await this.prisma.user.findUnique({ where: { email: id.email } }));

    if (user) {
      user = await this.prisma.user.update({
        where: { id: user.id },
        data: {
          [key]: id.sub,
          emailVerified: true,
          firstName: user.firstName ?? id.firstName,
          lastName: user.lastName ?? id.lastName,
        },
      });
    } else {
      user = await this.prisma.user.create({
        data: { email: id.email, emailVerified: true, [key]: id.sub, firstName: id.firstName, lastName: id.lastName },
      });
    }
    this.assertActive(user);
    return this.issue(user, client);
  }

  // ── Sessions ─────────────────────────────────────────────────────────────

  async refresh(token: string, client: ClientInfo): Promise<AuthResult> {
    const session = await this.prisma.session.findUnique({ where: { tokenHash: sha256(token) }, include: { user: true } });
    if (!session || session.expiresAt < new Date()) {
      throw new UnauthorizedException({ code: 'SESSION_EXPIRED', message: 'Please sign in again.' });
    }
    if (session.revokedAt) {
      // A rotated-away token came back: someone may hold a stolen copy.
      // End every session of this user.
      await this.prisma.session.updateMany({ where: { userId: session.userId, revokedAt: null }, data: { revokedAt: new Date() } });
      throw new UnauthorizedException({ code: 'SESSION_EXPIRED', message: 'Please sign in again.' });
    }
    this.assertActive(session.user);
    await this.prisma.session.update({ where: { id: session.id }, data: { revokedAt: new Date() } });
    return this.issue(session.user, client);
  }

  async logout(token: string): Promise<void> {
    await this.prisma.session.updateMany({ where: { tokenHash: sha256(token), revokedAt: null }, data: { revokedAt: new Date() } });
  }

  async me(userId: string): Promise<PublicUser> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.deletedAt) throw new UnauthorizedException({ code: 'SESSION_EXPIRED', message: 'Please sign in again.' });
    return toPublicUser(user);
  }

  private assertActive(user: User) {
    if (user.deletedAt) throw new UnauthorizedException({ code: 'BAD_CREDENTIALS', message: 'E-mail or password is incorrect.' });
    if (user.isBanned) throw new ForbiddenException({ code: 'ACCOUNT_BANNED', message: 'This account has been suspended.' });
  }

  private async issue(user: User, client: ClientInfo): Promise<AuthResult> {
    const refreshToken = randomBytes(48).toString('base64url');
    const days = this.config.getOrThrow<number>('jwt.refreshTtlDays');
    await this.prisma.session.create({
      data: {
        userId: user.id,
        tokenHash: sha256(refreshToken),
        userAgent: client.userAgent?.slice(0, 255),
        ip: client.ip,
        expiresAt: new Date(Date.now() + days * 86_400_000),
      },
    });
    const accessToken = await this.jwt.signAsync({ sub: user.id, roles: user.roles });
    return { accessToken, refreshToken, user: toPublicUser(user) };
  }
}
