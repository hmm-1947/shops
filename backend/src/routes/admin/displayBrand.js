import { Router } from 'express';
import { z } from 'zod';
import { db } from '../../db.js';
import { HttpError, parse } from '../../errors.js';

const KEY = 'display_brand_id';
const r = Router();
const schema = z.object({ brand_id: z.number().int().positive().nullable() });

async function current() {
  const row = await db.prepare('SELECT v FROM settings WHERE k = ?').get(KEY);
  const id = row ? Number.parseInt(row.v, 10) : null;
  return { brand_id: Number.isInteger(id) ? id : null };
}

r.get('/', async (req, res) => res.json(await current()));

r.put('/', async (req, res) => {
  const { brand_id } = parse(schema, req.body);
  if (brand_id === null) {
    await db.prepare('DELETE FROM settings WHERE k = ?').run(KEY);
    return res.json({ brand_id: null });
  }
  if (!(await db.prepare('SELECT 1 FROM brands WHERE id = ?').get(brand_id))) throw new HttpError(404, 'Brand not found');
  await db.prepare('INSERT INTO settings(k, v) VALUES(?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)').run(KEY, String(brand_id));
  res.json({ brand_id });
});

export default r;
