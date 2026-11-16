/**
 * One-shot copy of the old MySQL database (and its uploads) into PostgreSQL.
 *
 *   LEGACY_MYSQL_URL=mysql://root@localhost:3306/yshop_legacy \
 *   npx tsx scripts/migrate-legacy.ts [--reset]
 *
 * - Every login table of the old system (users, stores, delivery_requests,
 *   yshopadmins) becomes one `User` with roles. Same e-mail = same person.
 * - Integer ids of stores / products / orders are kept, so links never break.
 * - Images stay on the media server; run scripts/optimize-media.mjs there first.
 * - Idempotent with --reset (wipes the PostgreSQL side first). Read-only on MySQL.
 */
import 'dotenv/config';

import { PrismaPg } from '@prisma/adapter-pg';
import mysql from 'mysql2/promise';

import { PrismaClient, Role } from '../generated/prisma/client';

const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }) });
type Row = Record<string, any>;

const lower = (s?: string | null) => (s ?? '').trim().toLowerCase();
const upper = <T extends string>(s: string | null | undefined, fallback: T): T => ((s ?? '').trim().toUpperCase() || fallback) as T;
const bool = (v: unknown) => v === 1 || v === true || v === '1';
const json = (v: unknown) => (typeof v === 'string' ? safe(() => JSON.parse(v)) : v);
function safe<T>(f: () => T): T | null {
  try {
    return f();
  } catch {
    return null;
  }
}
function splitName(full?: string | null) {
  const parts = (full ?? '').trim().split(/\s+/).filter(Boolean);
  return { firstName: parts[0] ?? null, lastName: parts.slice(1).join(' ') || null };
}

// ── Images ────────────────────────────────────────────────────────────────
// Images never move. `scripts/optimize-media.mjs` runs on the media server and
// writes optimized copies under uploads/v2/; here we only point at them.
// Paths stay relative ("/uploads/…"); the API prefixes MEDIA_BASE_URL.

function convertImage(url: string | null | undefined) {
  if (!url) return { full: null, thumb: null };
  const rel = url.replace(/^https?:\/\/[^/]+/, '').replace(/^\/?uploads\//, '');
  const parts = rel.split('/');
  const name = parts.pop()!.replace(/\.[a-z0-9]+$/i, '.jpg');
  const dir = parts.join('/');
  return { full: `/uploads/v2/${dir}/${name}`, thumb: `/uploads/v2/${dir}/thumb/${name}` };
}

async function main() {
  const url = process.env.LEGACY_MYSQL_URL;
  if (!url) throw new Error('Set LEGACY_MYSQL_URL');
  const my = await mysql.createConnection({ uri: url, dateStrings: false, decimalNumbers: false });
  const q = async (sql: string) => (await my.query(sql))[0] as Row[];

  if (process.argv.includes('--reset')) {
    console.log('Resetting PostgreSQL data…');
    await prisma.$executeRawUnsafe(`
      TRUNCATE "AiMessage","TasteProfile","UserInteraction","ProductEmbedding","Complaint","ReturnRequest",
               "OrderItem","Order","PosTable","CartItem","Product","StoreCategory","Category","Store",
               "DriverProfile","Address","EmailCode","Device","Session","User" RESTART IDENTITY CASCADE`);
  }

  // ── People ──────────────────────────────────────────────────────────────
  // email → user id; the first table that claims an e-mail wins the id,
  // later ones add their role to it. legacyId → user id resolves FKs.
  const byEmail = new Map<string, string>();
  const idMap = new Map<string, string>();

  async function upsertPerson(p: {
    legacyId: string; email: string; role: Role; passwordHash?: string | null; emailVerified?: boolean;
    firstName?: string | null; lastName?: string | null; phone?: string | null; nationalId?: string | null;
    isBanned?: boolean; createdAt?: Date;
  }) {
    const email = lower(p.email) || `${p.legacyId}@legacy.yshop.local`;
    const existing = byEmail.get(email);
    if (existing) {
      const u = await prisma.user.findUniqueOrThrow({ where: { id: existing } });
      await prisma.user.update({
        where: { id: existing },
        data: {
          roles: Array.from(new Set([...u.roles, p.role])),
          passwordHash: u.passwordHash ?? p.passwordHash ?? null,
          phone: u.phone ?? p.phone ?? null,
          nationalId: u.nationalId ?? p.nationalId ?? null,
        },
      });
      idMap.set(p.legacyId, existing);
      return existing;
    }
    const u = await prisma.user.create({
      data: {
        id: p.legacyId, email, roles: [p.role], passwordHash: p.passwordHash ?? null,
        emailVerified: p.emailVerified ?? false, firstName: p.firstName ?? null, lastName: p.lastName ?? null,
        phone: p.phone ?? null, nationalId: p.nationalId ?? null, isBanned: p.isBanned ?? false,
        createdAt: p.createdAt ?? new Date(),
      },
    });
    byEmail.set(email, u.id);
    idMap.set(p.legacyId, u.id);
    return u.id;
  }

  const users = await q('SELECT * FROM users');
  for (const u of users) {
    const fallback = splitName(u.display_name);
    const id = await upsertPerson({
      legacyId: u.uid, email: u.email, role: 'CUSTOMER', passwordHash: u.password_hash,
      emailVerified: bool(u.email_verified), firstName: u.name ?? fallback.firstName,
      lastName: u.surname ?? fallback.lastName, phone: u.phone, nationalId: u.national_id, createdAt: u.created_at,
    });
    if (u.address && u.latitude != null && u.longitude != null) {
      await prisma.address.create({
        data: {
          userId: id, label: 'Home', line: u.address, building: u.building_info, apartment: u.apartment_number,
          instructions: u.delivery_instructions, latitude: u.latitude, longitude: u.longitude, isDefault: true,
        },
      });
    }
    if (u.apns_device_token) {
      await prisma.device.upsert({
        where: { apnsToken: u.apns_device_token },
        create: { userId: id, apnsToken: u.apns_device_token },
        update: { userId: id },
      });
    }
  }
  console.log(`✓ customers      ${users.length}`);

  const admins = await q('SELECT * FROM yshopadmins');
  for (const a of admins) {
    await upsertPerson({
      legacyId: `admin_${a.id}`, email: a.email, role: a.role === 'superadmin' ? 'SUPERADMIN' : 'ADMIN',
      passwordHash: a.password_hash, emailVerified: true, firstName: a.first_name, lastName: a.last_name,
      isBanned: bool(a.is_banned) || a.status !== 'active', createdAt: a.created_at,
    });
  }
  console.log(`✓ admins         ${admins.length}`);

  const drivers = await q('SELECT * FROM delivery_requests');
  for (const d of drivers) {
    const n = splitName(d.name);
    const id = await upsertPerson({
      legacyId: d.uid, email: d.email, role: 'DRIVER', passwordHash: d.password_hash,
      emailVerified: bool(d.email_verified), ...n, phone: d.phone, nationalId: d.national_id, createdAt: d.created_at,
    });
    await prisma.driverProfile.create({
      data: {
        userId: id, status: upper(d.status, 'PENDING'), isWorking: false, address: d.address,
        latitude: d.latitude, longitude: d.longitude, createdAt: d.created_at,
      },
    });
  }
  console.log(`✓ drivers        ${drivers.length}`);

  // ── Stores ──────────────────────────────────────────────────────────────
  // Old stores had their own login; that login becomes the owner's account.
  const stores = await q('SELECT * FROM stores ORDER BY id');
  for (const s of stores) {
    let ownerId: string | null = s.owner_uid ? (idMap.get(s.owner_uid) ?? null) : null;
    if (!ownerId && (s.email || s.uid)) {
      ownerId = await upsertPerson({
        legacyId: s.uid ?? `store_${s.id}`, email: s.email, role: 'STORE_OWNER', passwordHash: s.password_hash,
        emailVerified: bool(s.email_verified), firstName: s.name, phone: s.phone, createdAt: s.created_at,
      });
    } else if (ownerId) {
      const u = await prisma.user.findUniqueOrThrow({ where: { id: ownerId } });
      if (!u.roles.includes('STORE_OWNER')) {
        await prisma.user.update({ where: { id: ownerId }, data: { roles: [...u.roles, 'STORE_OWNER'] } });
      }
    }
    const icon = convertImage(s.icon_url);
    await prisma.store.create({
      data: {
        id: s.id, ownerId, name: s.name, description: s.description, phone: s.phone, email: lower(s.email) || null,
        address: s.address, latitude: s.latitude, longitude: s.longitude, iconUrl: icon.full,
        storeType: s.store_type ?? 'general', status: upper(s.status, 'PENDING'), isActive: bool(s.is_active),
        createdAt: s.created_at,
      },
    });
  }
  console.log(`✓ stores         ${stores.length}`);

  // ── Catalog ─────────────────────────────────────────────────────────────
  const categories = await q('SELECT * FROM categories ORDER BY id');
  for (const c of categories) {
    await prisma.category.create({
      data: {
        id: c.id, name: c.name, displayName: c.display_name, description: c.description, icon: c.icon,
        displayOrder: c.display_order ?? 0, createdAt: c.created_at,
      },
    });
  }
  // Old categories pointed at one store directly; links table adds more.
  const links = new Map<string, { storeId: number; categoryId: number; displayOrder: number }>();
  for (const c of categories) if (c.store_id) links.set(`${c.store_id}:${c.id}`, { storeId: c.store_id, categoryId: c.id, displayOrder: c.display_order ?? 0 });
  for (const l of await q('SELECT * FROM store_category_links')) links.set(`${l.store_id}:${l.category_id}`, { storeId: l.store_id, categoryId: l.category_id, displayOrder: l.display_order ?? 0 });
  const storeIds = new Set(stores.map((s) => s.id));
  await prisma.storeCategory.createMany({ data: [...links.values()].filter((l) => storeIds.has(l.storeId)) });
  console.log(`✓ categories     ${categories.length} (${links.size} store links)`);

  const products = await q('SELECT * FROM products ORDER BY id');
  const productInfo = new Map<number, { name: string; imageUrl: string | null }>();
  for (const p of products) {
    const img = convertImage(p.image_url);
    await prisma.product.create({
      data: {
        id: p.id, storeId: p.store_id, categoryId: p.category_id, name: p.name, description: p.description,
        price: p.price, currency: p.currency ?? 'USD', stock: p.stock ?? 0, imageUrl: img.full, thumbUrl: img.thumb,
        images: img.full ? [img.full] : [], isActive: bool(p.is_active), status: upper(p.status, 'PENDING'),
        createdAt: p.created_at,
      },
    });
    productInfo.set(p.id, { name: p.name, imageUrl: img.thumb });
  }
  console.log(`✓ products       ${products.length}`);

  const tables = await q('SELECT * FROM pos_tables ORDER BY id');
  for (const t of tables) {
    await prisma.posTable.create({
      data: {
        id: t.id, storeId: t.store_id, name: t.name, capacity: t.capacity, status: upper(t.status, 'AVAILABLE'),
        qrToken: t.qr_token, sortOrder: t.sort_order, createdAt: t.created_at,
      },
    });
  }
  console.log(`✓ pos tables     ${tables.length}`);

  // ── Orders ──────────────────────────────────────────────────────────────
  const statusMap: Record<string, string> = { return: 'RETURNED' };
  const userOrNull = (legacy?: string | null) => (legacy ? (idMap.get(legacy) ?? null) : null);
  const orders = await q('SELECT * FROM orders ORDER BY id');
  for (const o of orders) {
    const loc = json(o.driver_location) as { latitude?: number; longitude?: number } | null;
    await prisma.order.create({
      data: {
        id: o.id, userId: userOrNull(o.user_id), storeId: o.store_id, driverId: userOrNull(o.driver_id),
        status: (statusMap[o.status] ?? upper(o.status, 'PENDING')) as never, channel: upper(o.order_type, 'ONLINE'),
        totalPrice: o.total_price, currency: o.currency ?? 'USD', paymentMethod: o.payment_method,
        deliveryOption: o.delivery_option, shippingAddress: o.shipping_address,
        offeredDriverId: userOrNull(o.current_offer_driver_id), offerExpiresAt: o.offer_expires_at,
        skippedDriverIds: ((json(o.skipped_driver_ids) as string[] | null) ?? []).map((d) => idMap.get(d) ?? d),
        driverLatitude: loc?.latitude ?? null, driverLongitude: loc?.longitude ?? null,
        liveActivityToken: o.live_activity_push_token, tableId: o.table_id,
        kitchenStatus: o.kitchen_status ? upper(o.kitchen_status, 'PENDING') : null,
        kitchenUpdatedAt: o.kitchen_updated_at,
        localPaymentMethod: o.local_payment_method ? upper(o.local_payment_method, 'CASH') : null,
        localPaid: bool(o.local_paid), cashierNotes: o.cashier_notes, pickedUpAt: o.picked_up_at,
        deliveredAt: o.delivered_at, cancelledAt: o.status === 'cancelled' ? o.updated_at : null,
        createdAt: o.created_at, updatedAt: o.updated_at ?? o.created_at,
      },
    });
  }
  const items = await q('SELECT * FROM order_items ORDER BY id');
  for (const i of items) {
    const p = productInfo.get(i.product_id);
    await prisma.orderItem.create({
      data: {
        id: i.id, orderId: i.order_id, productId: p ? i.product_id : null, name: p?.name ?? `Product #${i.product_id}`,
        imageUrl: p?.imageUrl ?? null, quantity: i.quantity, unitPrice: i.price, notes: i.notes, createdAt: i.created_at,
      },
    });
  }
  console.log(`✓ orders         ${orders.length} (${items.length} items)`);

  // ── After-sales ─────────────────────────────────────────────────────────
  const returns = await q('SELECT * FROM returned_products ORDER BY id');
  for (const r of returns) {
    const photos: Record<string, string> = {};
    for (const side of ['top', 'bottom', 'right', 'left', 'front', 'back']) {
      const img = convertImage(r[`photo_${side}`]);
      if (img.full) photos[side] = img.full;
    }
    await prisma.returnRequest.create({
      data: {
        id: r.id, orderId: r.order_id, orderItemId: r.order_item_id, productId: r.product_id,
        userId: idMap.get(r.user_id) ?? r.user_id, storeId: r.store_id, driverId: userOrNull(r.driver_id),
        quantity: r.quantity ?? 1, reason: r.return_reason, photos, adminAccepted: bool(r.admin_accepted),
        storeReceived: bool(r.store_received), driverPickedUpAt: r.driver_picked_up_at, deliveredAt: r.delivered_at,
        createdAt: r.created_at,
      },
    });
  }
  const complaints = await q('SELECT * FROM order_complaints ORDER BY id');
  for (const c of complaints) {
    await prisma.complaint.create({
      data: {
        id: c.id, orderId: c.order_id, customerId: idMap.get(c.customer_id) ?? c.customer_id,
        driverId: userOrNull(c.driver_id), storeId: c.store_id, type: c.complaint_type, subType: c.sub_type,
        description: c.description, photos: (json(c.photos) as string[] | null) ?? [], status: c.status,
        adminNotes: c.admin_notes, resolutionType: c.resolution_type, responsibleParty: c.responsible_party,
        deadlineAt: c.deadline_at, createdAt: c.created_at,
      },
    });
  }
  console.log(`✓ returns        ${returns.length} · complaints ${complaints.length}`);

  // ── Personalisation ─────────────────────────────────────────────────────
  const productIds = new Set(products.map((p) => p.id));
  const interactions = (await q('SELECT * FROM user_interactions ORDER BY id')).filter(
    (i) => idMap.has(i.user_id) && productIds.has(i.product_id),
  );
  await prisma.userInteraction.createMany({
    data: interactions.map((i) => ({
      userId: idMap.get(i.user_id)!, productId: i.product_id, storeType: i.store_type,
      type: upper(i.event_type, 'VIEW'), query: i.query, createdAt: i.created_at,
    })),
  });
  console.log(`✓ interactions   ${interactions.length}`);

  // Integer ids were inserted explicitly: move every sequence past them.
  for (const t of ['Store', 'Category', 'Product', 'PosTable', 'Order', 'OrderItem', 'ReturnRequest', 'Complaint', 'CartItem', 'UserInteraction']) {
    await prisma.$executeRawUnsafe(
      `SELECT setval(pg_get_serial_sequence('"${t}"','id'), GREATEST((SELECT COALESCE(MAX(id),0) FROM "${t}"),1), (SELECT COUNT(*)>0 FROM "${t}"))`,
    );
  }

  console.log('\nDone.');
  await my.end();
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
