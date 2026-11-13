import { Router } from 'express';
import { z } from 'zod';
import { db } from '../../db.js';
import { HttpError, parse, pid } from '../../errors.js';
import { oneImage, saveImage, removeImage } from '../../upload.js';

const bool = z.preprocess((v) => v === true || v === 'true' || v === '1', z.boolean());

export function taxonomy({ table, parent, discount, listSql }) {
  const r = Router();
  const shape = {
    name: z.string().trim().min(1).max(80),
    enabled: bool,
    ...(parent && { [parent]: z.coerce.number().int().positive() }),
    ...(discount && { discount: z.coerce.number().min(0).max(100) }),
  };
  const schema = z.object(shape);
  const cols = Object.keys(shape);
  const values = (body) => cols.map((c) => (c === 'enabled' ? +body.enabled : body[c]));

  r.get('/', async (req, res) => res.json(await db.prepare(listSql).all()));

  r.post('/', oneImage, async (req, res) => {
    const body = parse(schema, req.body);
    if (!req.file) throw new HttpError(400, 'image: required');
    const image = await saveImage(req.file.buffer);
    const all = [...cols, 'image'];
    try {
      const info = await db
        .prepare(`INSERT INTO ${table}(${all.join(',')}) VALUES(${all.map(() => '?').join(',')})`)
        .run(...values(body), image);
      res.status(201).json({ id: info.lastInsertRowid });
    } catch (e) {
      await removeImage(image);
      throw e;
    }
  });

  r.put('/:id', oneImage, async (req, res) => {
    const id = pid(req.params.id);
    const old = await db.prepare(`SELECT image FROM ${table} WHERE id = ?`).get(id);
    if (!old) throw new HttpError(404, 'Not found');
    const body = parse(schema, req.body);
    const image = req.file ? await saveImage(req.file.buffer) : old.image;
    try {
      await db.prepare(`UPDATE ${table} SET ${[...cols, 'image'].map((c) => c + ' = ?').join(',')} WHERE id = ?`).run(...values(body), image, id);
    } catch (e) {
      if (req.file) await removeImage(image);
      throw e;
    }
    if (req.file) await removeImage(old.image);
    res.json({ ok: true });
  });

  return r;
}
