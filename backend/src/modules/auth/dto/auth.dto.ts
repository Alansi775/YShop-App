import { Transform } from 'class-transformer';
import { IsEmail, IsOptional, IsString, Length, MaxLength, MinLength } from 'class-validator';

const trimLower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim().toLowerCase() : value);
const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

export class RegisterDto {
  @Transform(trimLower) @IsEmail({}, { message: 'Enter a valid e-mail address.' })
  email: string;

  @IsString() @MinLength(8, { message: 'Password must be at least 8 characters.' }) @MaxLength(128)
  password: string;

  @Transform(trim) @IsString() @Length(1, 60)
  firstName: string;

  @Transform(trim) @IsString() @Length(1, 60)
  lastName: string;

  @IsOptional() @Transform(trim) @IsString() @MaxLength(20)
  phone?: string;
}

export class LoginDto {
  @Transform(trimLower) @IsEmail({}, { message: 'Enter a valid e-mail address.' })
  email: string;

  @IsString() @MinLength(1)
  password: string;
}

export class AppleAuthDto {
  @IsString()
  identityToken: string;

  /** Apple sends the name only on the very first sign-in — the app forwards it. */
  @IsOptional() @Transform(trim) @IsString() @MaxLength(60)
  firstName?: string;

  @IsOptional() @Transform(trim) @IsString() @MaxLength(60)
  lastName?: string;
}

export class GoogleAuthDto {
  @IsString()
  idToken: string;
}

export class RefreshDto {
  @IsString()
  refreshToken: string;
}

export class ChangePasswordDto {
  @IsString()
  currentPassword: string;

  @IsString() @MinLength(8, { message: 'Password must be at least 8 characters.' }) @MaxLength(128)
  newPassword: string;
}
