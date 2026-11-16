import { Router } from 'express';
import { z } from 'zod';
import { db } from '../../db.js';
import { HttpError, parse, pid } from '../../errors.js';
import { oneImage, imageAndBanner, saveImage, removeImage } from '../../upload.js';

const bool = z.preprocess((v) => v === true || v === 'true' || v === '1', z.boolean());

export function taxonomy({ table, parent, discount, banner, listSql }) {
  const upload = banner ? imageAndBanner : oneImage;

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

  r.post('/', upload, async (req, res) => {
    const body = parse(schema, req.body);
    if (!req.file) throw new HttpError(400, 'image: required');
    const saved = [];
    try {
      const image = await saveImage(req.file.buffer);
      saved.push(image);
      const all = [...cols, 'image'];
      const vals = [...values(body), image];
      if (banner) {
        const b = req.bannerFile ? await saveImage(req.bannerFile.buffer) : null;
        if (b) saved.push(b);
        all.push('banner');
        vals.push(b);
      }
      const info = await db.prepare(`INSERT INTO ${table}(${all.join(',')}) VALUES(${all.map(() => '?').join(',')})`).run(...vals);
      res.status(201).json({ id: info.lastInsertRowid });
    } catch (e) {
      await Promise.all(saved.map(removeImage));
      throw e;
    }
  });

  r.put('/:id', upload, async (req, res) => {
    const id = pid(req.params.id);
    const old = await db.prepare(`SELECT image${banner ? ', banner' : ''} FROM ${table} WHERE id = ?`).get(id);
    if (!old) throw new HttpError(404, 'Not found');
    const body = parse(schema, req.body);
    const fresh = [];
    const stale = [];
    try {
      let image = old.image;
      if (req.file) {
        image = await saveImage(req.file.buffer);
        fresh.push(image);
        stale.push(old.image);
      }
      const all = [...cols, 'image'];
      const vals = [...values(body), image];
      if (banner) {
        let b = old.banner;
        if (req.bannerFile) {
          b = await saveImage(req.bannerFile.buffer);
          fresh.push(b);
          stale.push(old.banner);
        } else if (req.body.remove_banner === 'true') {
          b = null;
          stale.push(old.banner);
        }
        all.push('banner');
        vals.push(b);
      }
      await db.prepare(`UPDATE ${table} SET ${all.map((c) => c + ' = ?').join(',')} WHERE id = ?`).run(...vals, id);
    } catch (e) {
      await Promise.all(fresh.map(removeImage));
      throw e;
    }
    await Promise.all(stale.map(removeImage));
    res.json({ ok: true });
  });

  return r;
}
