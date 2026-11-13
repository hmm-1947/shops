import { Router } from 'express';
import { z } from 'zod';
import { db } from '../../db.js';
import { HttpError, parse, pid } from '../../errors.js';

const STATUSES = ['placed', 'confirmed', 'packed', 'out_for_delivery', 'delivered', 'cancelled'];
const r = Router();

r.get('/', async (req, res) => {
  const status = STATUSES.includes(req.query.status) ? req.query.status : null;
  const page = Math.max(1, Number.parseInt(req.query.page, 10) || 1);
  const limit = 25;
  const where = status ? 'WHERE status = ?' : '';
  const args = status ? [status] : [];
  const total = (await db.prepare(`SELECT COUNT(*) AS n FROM orders ${where}`).get(...args)).n;
  const items = await db
    .prepare(
      `SELECT o.id, o.customer_name, o.customer_email, o.phone, o.city, o.payment_method, o.total, o.status, o.created_at,
        (SELECT COALESCE(SUM(qty), 0) FROM order_items WHERE order_id = o.id) AS item_count
       FROM orders o ${where} ORDER BY o.id DESC LIMIT ? OFFSET ?`,
    )
    .all(...args, limit, (page - 1) * limit);
  const counts = Object.fromEntries((await db.prepare('SELECT status, COUNT(*) AS n FROM orders GROUP BY status').all()).map((x) => [x.status, x.n]));
  res.json({ items, total, limit, counts });
});

r.get('/:id', async (req, res) => {
  const o = await db.prepare('SELECT * FROM orders WHERE id = ?').get(pid(req.params.id));
  if (!o) throw new HttpError(404, 'Not found');
  res.json({ ...o, address: JSON.parse(o.address), items: await db.prepare('SELECT * FROM order_items WHERE order_id = ? ORDER BY id').all(o.id) });
});

r.patch('/:id/status', async (req, res) => {
  const { status } = parse(z.object({ status: z.enum(STATUSES) }), req.body);
  const id = pid(req.params.id);
  if (!(await db.prepare('UPDATE orders SET status = ? WHERE id = ?').run(status, id)).changes) throw new HttpError(404, 'Not found');
  res.json({ ok: true });
});

export default r;
