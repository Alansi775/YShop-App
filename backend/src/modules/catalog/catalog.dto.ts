import { Transform, Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class StoreQueryDto {
  /** "Food", "Clothes", … (case-insensitive) */
  @IsOptional() @IsString() @MaxLength(50)
  type?: string;

  @IsOptional() @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)) @IsString() @MaxLength(100)
  search?: string;
}

export class ProductQueryDto {
  @IsOptional() @Type(() => Number) @IsInt()
  storeId?: number;

  @IsOptional() @Type(() => Number) @IsInt()
  categoryId?: number;

  @IsOptional() @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value)) @IsString() @MaxLength(100)
  search?: string;

  /** id of the last product of the previous page */
  @IsOptional() @Type(() => Number) @IsInt()
  cursor?: number;

  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100)
  limit: number = 40;
}
