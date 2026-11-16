import { Router } from 'express';
import { z } from 'zod';
import { db } from '../../db.js';
import { HttpError, parse, pid } from '../../errors.js';

const r = Router();
const schema = z
  .object({
    name: z.string().trim().min(1).max(80),
    value: z.number().min(0).max(1000000),
    type: z.enum(['fixed', 'percent']),
    enabled: z.boolean().default(true),
  })
  .refine((c) => c.type !== 'percent' || c.value <= 100, { message: 'percentage cannot exceed 100', path: ['value'] });

r.get('/', async (req, res) => {
  const rows = await db.prepare('SELECT id, name, value, type, enabled FROM charges ORDER BY id').all();
  res.json(rows.map((c) => ({ ...c, enabled: !!c.enabled })));
});

r.post('/', async (req, res) => {
  const b = parse(schema, req.body);
  const info = await db.prepare('INSERT INTO charges(name, value, type, enabled) VALUES(?, ?, ?, ?)').run(b.name, b.value, b.type, +b.enabled);
  res.status(201).json({ id: info.lastInsertRowid });
});

r.put('/:id', async (req, res) => {
  const id = pid(req.params.id);
  const b = parse(schema, req.body);
  const info = await db.prepare('UPDATE charges SET name = ?, value = ?, type = ?, enabled = ? WHERE id = ?').run(b.name, b.value, b.type, +b.enabled, id);
  if (!info.changes && !(await db.prepare('SELECT 1 FROM charges WHERE id = ?').get(id))) throw new HttpError(404, 'Not found');
  res.json({ ok: true });
});

r.delete('/:id', async (req, res) => {
  if (!(await db.prepare('DELETE FROM charges WHERE id = ?').run(pid(req.params.id))).changes) throw new HttpError(404, 'Not found');
  res.json({ ok: true });
});

export default r;
