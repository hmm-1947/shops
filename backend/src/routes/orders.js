import { Router } from 'express';
import { z } from 'zod';
import { db, tx } from '../db.js';
import { HttpError, parse, pid } from '../errors.js';
import { requireCustomer } from '../firebase.js';
import { discountFor, finalPrice } from '../pricing.js';
import { activeCharges, applyCharges, getWarehouse, deliveryFor } from '../delivery.js';

const FREE_DELIVERY_AT = 14900;
const DELIVERY_FEE = 2500;

const schema = z.object({
  items: z.array(z.object({ variant_id: z.number().int().positive(), qty: z.number().int().min(1).max(20) })).min(1).max(50),
  payment_method: z.enum(['upi', 'card', 'net', 'wallet', 'cod']),
  city: z.string().trim().max(60).default(''),
  phone: z.string().trim().max(20).default(''),
  location: z.object({ lat: z.number().min(-90).max(90), lng: z.number().min(-180).max(180) }).nullish(),
  address: z.object({
    label: z.string().trim().max(30).default('Home'),
    name: z.string().trim().max(80).default(''),
    lines: z.array(z.string().trim().max(120)).min(1).max(6),
  }),
});

const LINE = `SELECT v.id AS variant_id, v.name AS variant_name, v.price, v.discount AS vd, p.id AS product_id, p.name AS product_name,
    b.name AS brand, b.discount AS bd, c.discount AS cd,
    (SELECT path FROM product_images WHERE product_id = p.id ORDER BY position, id LIMIT 1) AS image
  FROM variants v JOIN products p ON p.id = v.product_id
  JOIN subcategories s ON s.id = p.subcategory_id JOIN categories c ON c.id = s.category_id
  LEFT JOIN brands b ON b.id = p.brand_id
  WHERE v.id = ? AND p.status = 'active' AND p.enabled = 1 AND s.enabled = 1 AND c.enabled = 1 AND (p.brand_id IS NULL OR b.enabled = 1)`;

const r = Router();
r.use(requireCustomer);

r.post('/', async (req, res) => {
  const b = parse(schema, req.body);
  const merged = new Map();
  for (const i of b.items) merged.set(i.variant_id, Math.min(20, (merged.get(i.variant_id) ?? 0) + i.qty));
  const lines = [];
  for (const [variantId, qty] of merged) {
    const row = await db.prepare(LINE).get(variantId);
    if (!row) throw new HttpError(400, 'An item in your cart is no longer available');
    lines.push({ ...row, qty, ...finalPrice(row.price, discountFor(row.vd, row.cd, row.bd)) });
  }
  const subtotal = lines.reduce((a, l) => a + l.price * l.qty, 0);
  const fee = subtotal >= FREE_DELIVERY_AT ? 0 : DELIVERY_FEE;
  const charged = applyCharges(await activeCharges(), subtotal);
  const total = subtotal + fee + charged.total;
  const loc = b.location ?? null;
  const delivery = deliveryFor(await getWarehouse(), loc?.lat, loc?.lng);
  const id = await tx(async (c) => {

    const orderId = (
      await c
        .prepare(
          `INSERT INTO orders(uid, customer_name, customer_email, phone, city, address, payment_method, subtotal, delivery_fee, charges_total, charges, total, latitude, longitude, distance_km, delivery_mode)
           VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        )
        .run(
          req.customer.uid,
          b.address.name || req.customer.name,
          req.customer.email,
          b.phone,
          b.city,
          JSON.stringify(b.address),
          b.payment_method,
          subtotal,
          fee,
          charged.total,
          JSON.stringify(charged.lines),
          total,
          loc?.lat ?? null,
          loc?.lng ?? null,
          delivery.distance_km,
          delivery.delivery_mode,
        )
    ).lastInsertRowid;
    for (const l of lines) {
      await c
        .prepare(
          `INSERT INTO order_items(order_id, product_id, variant_id, product_name, brand, variant_name, image, mrp, discount, price, qty)
           VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        )
        .run(orderId, l.product_id, l.variant_id, l.product_name, l.brand, l.variant_name, l.image, l.mrp, l.discount, l.price, l.qty);
    }
    return orderId;
  });
  res.status(201).json({ id, subtotal, delivery_fee: fee, charges: charged.lines, charges_total: charged.total, total, delivery_mode: delivery.delivery_mode, status: 'placed' });
});

r.get('/', async (req, res) => {
  const orders = await db
    .prepare('SELECT id, subtotal, delivery_fee, charges_total, total, status, payment_method, created_at FROM orders WHERE uid = ? ORDER BY id DESC LIMIT 100')
    .all(req.customer.uid);
  const items = orders.length
    ? await db
        .prepare('SELECT order_id, product_name, brand, variant_name, image, price, qty FROM order_items WHERE order_id IN (?) ORDER BY id')
        .all(orders.map((o) => o.id))
    : [];
  res.json(orders.map((o) => ({ ...o, items: items.filter((i) => i.order_id === o.id) })));

});

r.get('/:id', async (req, res) => {
  const o = await db.prepare('SELECT * FROM orders WHERE id = ? AND uid = ?').get(pid(req.params.id), req.customer.uid);
  if (!o) throw new HttpError(404, 'Not found');
  res.json({ ...o, address: JSON.parse(o.address), charges: JSON.parse(o.charges), items: await db.prepare('SELECT * FROM order_items WHERE order_id = ? ORDER BY id').all(o.id) });
});

export default r;
