import { Router } from 'express';
import { z } from 'zod';
import { db } from '../../db.js';
import { parse } from '../../errors.js';
import { getWarehouse } from '../../delivery.js';

const r = Router();
const schema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  label: z.string().trim().max(120).default(''),
});

r.get('/', async (req, res) => res.json(await getWarehouse()));

r.put('/', async (req, res) => {
  const b = parse(schema, req.body);
  for (const [k, v] of [['warehouse_lat', String(b.lat)], ['warehouse_lng', String(b.lng)], ['warehouse_label', b.label]]) {
    await db.prepare('INSERT INTO settings(k, v) VALUES(?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)').run(k, v);
  }
  res.json(await getWarehouse());
});

export default r;
