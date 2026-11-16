import { Injectable, NotFoundException } from '@nestjs/common';

import type { Prisma } from '../../../generated/prisma/client';
import { mediaUrl } from '../../common/media/media';
import { PrismaService } from '../../prisma/prisma.service';
import { ProductQueryDto, StoreQueryDto } from './catalog.dto';

/** Only what a shopper may see: approved, active, and in an approved, active store. */
const VISIBLE_STORE: Prisma.StoreWhereInput = { status: 'APPROVED', isActive: true };
const VISIBLE_PRODUCT: Prisma.ProductWhereInput = { status: 'APPROVED', isActive: true, store: VISIBLE_STORE };

const productSelect = {
  id: true, name: true, description: true, price: true, currency: true, stock: true,
  imageUrl: true, thumbUrl: true, images: true, storeId: true, categoryId: true, createdAt: true,
} satisfies Prisma.ProductSelect;

type ProductRow = Prisma.ProductGetPayload<{ select: typeof productSelect }>;

export function toProduct(p: ProductRow) {
  return {
    id: p.id,
    name: p.name,
    description: p.description,
    price: Number(p.price),
    currency: p.currency,
    inStock: p.stock > 0,
    stock: p.stock,
    imageUrl: mediaUrl(p.imageUrl),
    thumbUrl: mediaUrl(p.thumbUrl ?? p.imageUrl),
    images: p.images.map(mediaUrl),
    storeId: p.storeId,
    categoryId: p.categoryId,
    createdAt: p.createdAt,
  };
}

@Injectable()
export class CatalogService {
  constructor(private readonly prisma: PrismaService) {}

  /** Home screen chips: every store type that has at least one visible store. */
  async storeTypes() {
    const rows = await this.prisma.store.groupBy({ by: ['storeType'], where: VISIBLE_STORE, _count: true, orderBy: { storeType: 'asc' } });
    return rows.map((r) => ({ type: r.storeType, storeCount: r._count }));
  }

  async stores(q: StoreQueryDto) {
    const stores = await this.prisma.store.findMany({
      where: {
        ...VISIBLE_STORE,
        ...(q.type && { storeType: { equals: q.type, mode: 'insensitive' } }),
        ...(q.search && {
          OR: [
            { name: { contains: q.search, mode: 'insensitive' } },
            { description: { contains: q.search, mode: 'insensitive' } },
          ],
        }),
      },
      orderBy: [{ name: 'asc' }],
      include: { _count: { select: { products: { where: { status: 'APPROVED', isActive: true } } } } },
    });
    return stores.map((s) => ({
      id: s.id,
      name: s.name,
      description: s.description,
      type: s.storeType,
      iconUrl: mediaUrl(s.iconUrl),
      coverUrl: mediaUrl(s.coverUrl),
      address: s.address,
      latitude: s.latitude == null ? null : Number(s.latitude),
      longitude: s.longitude == null ? null : Number(s.longitude),
      productCount: s._count.products,
    }));
  }

  /** One request for the whole store page: store, its categories and their products. */
  async store(id: number) {
    const s = await this.prisma.store.findFirst({
      where: { id, ...VISIBLE_STORE },
      include: {
        categories: { orderBy: { displayOrder: 'asc' }, include: { category: true } },
        products: { where: { status: 'APPROVED', isActive: true }, select: productSelect, orderBy: { createdAt: 'desc' } },
      },
    });
    if (!s) throw new NotFoundException({ code: 'STORE_NOT_FOUND', message: 'This store is not available.' });

    const products = s.products.map(toProduct);
    const categories = s.categories
      .map(({ category: c }) => ({
        id: c.id,
        name: c.displayName ?? c.name,
        icon: c.icon,
        productIds: products.filter((p) => p.categoryId === c.id).map((p) => p.id),
      }))
      .filter((c) => c.productIds.length > 0);

    return {
      id: s.id,
      name: s.name,
      description: s.description,
      type: s.storeType,
      phone: s.phone,
      address: s.address,
      latitude: s.latitude == null ? null : Number(s.latitude),
      longitude: s.longitude == null ? null : Number(s.longitude),
      iconUrl: mediaUrl(s.iconUrl),
      coverUrl: mediaUrl(s.coverUrl),
      categories,
      products,
    };
  }

  async products(q: ProductQueryDto) {
    const rows = await this.prisma.product.findMany({
      where: {
        ...VISIBLE_PRODUCT,
        ...(q.storeId && { storeId: q.storeId }),
        ...(q.categoryId && { categoryId: q.categoryId }),
        ...(q.search && {
          OR: [
            { name: { contains: q.search, mode: 'insensitive' } },
            { description: { contains: q.search, mode: 'insensitive' } },
            { store: { name: { contains: q.search, mode: 'insensitive' } } },
          ],
        }),
      },
      select: productSelect,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: q.limit + 1,
      ...(q.cursor && { cursor: { id: q.cursor }, skip: 1 }),
    });
    const page = rows.slice(0, q.limit);
    return { items: page.map(toProduct), nextCursor: rows.length > q.limit ? page[page.length - 1].id : null };
  }

  async product(id: number) {
    const p = await this.prisma.product.findFirst({
      where: { id, ...VISIBLE_PRODUCT },
      select: { ...productSelect, store: { select: { id: true, name: true, iconUrl: true, storeType: true } } },
    });
    if (!p) throw new NotFoundException({ code: 'PRODUCT_NOT_FOUND', message: 'This product is not available.' });
    return {
      ...toProduct(p),
      store: { id: p.store.id, name: p.store.name, type: p.store.storeType, iconUrl: mediaUrl(p.store.iconUrl) },
    };
  }
}
