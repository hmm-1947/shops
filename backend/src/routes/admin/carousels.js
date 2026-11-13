import { Router } from 'express';
import { z } from 'zod';
import { db } from '../../db.js';
import { HttpError, parse, pid } from '../../errors.js';
import { manyImages, saveImage, removeImage } from '../../upload.js';

const r = Router();
const schema = z.object({ name: z.string().trim().min(1).max(80), enabled: z.boolean().default(true) });

const images = (id) => db.prepare('SELECT id, image FROM carousel_images WHERE carousel_id = ? ORDER BY position, id').all(id);
const find = async (id) => {
  const c = await db.prepare('SELECT id, name, enabled FROM carousels WHERE id = ?').get(id);
  if (!c) throw new HttpError(404, 'Not found');
  return c;
};

r.get('/', async (req, res) =>
  res.json(
    await db
      .prepare(
        `SELECT c.id, c.name, c.enabled, (SELECT COUNT(*) FROM carousel_images WHERE carousel_id = c.id) AS image_count
         FROM carousels c ORDER BY c.name`,
      )
      .all(),
  ),
);

r.post('/', async (req, res) => {
  const b = parse(schema, req.body);
  const info = await db.prepare('INSERT INTO carousels(name, enabled) VALUES(?, ?)').run(b.name, +b.enabled);
  res.status(201).json({ id: info.lastInsertRowid });
});

r.get('/:id', async (req, res) => {
  const c = await find(pid(req.params.id));
  res.json({ ...c, enabled: !!c.enabled, images: await images(c.id) });
});

r.put('/:id', async (req, res) => {
  const c = await find(pid(req.params.id));
  const b = parse(schema, req.body);
  await db.prepare('UPDATE carousels SET name = ?, enabled = ? WHERE id = ?').run(b.name, +b.enabled, c.id);
  res.json({ ok: true });
});

r.delete('/:id', async (req, res) => {
  const c = await find(pid(req.params.id));
  if (await db.prepare("SELECT 1 FROM item_classes WHERE map_type = 'carousel' AND map_id = ?").get(c.id)) {
    throw new HttpError(409, 'Carousel is used by a home page item class');
  }
  const files = await images(c.id);
  await db.prepare('DELETE FROM carousels WHERE id = ?').run(c.id);
  await Promise.all(files.map((f) => removeImage(f.image)));
  res.json({ ok: true });
});

r.post('/:id/images', manyImages, async (req, res) => {
  const c = await find(pid(req.params.id));
  if (!req.files?.length) throw new HttpError(400, 'images: required');
  const saved = [];
  try {
    for (const f of req.files) saved.push(await saveImage(f.buffer));
  } catch (e) {
    await Promise.all(saved.map(removeImage));
    throw e;
  }
  let pos = (await db.prepare('SELECT COALESCE(MAX(position), 0) AS m FROM carousel_images WHERE carousel_id = ?').get(c.id)).m;
  for (const image of saved) await db.prepare('INSERT INTO carousel_images(carousel_id, image, position) VALUES(?, ?, ?)').run(c.id, image, ++pos);
  res.status(201).json({ images: await images(c.id) });
});

r.delete('/:id/images/:imageId', async (req, res) => {
  const c = await find(pid(req.params.id));
  const imageId = pid(req.params.imageId);
  const img = await db.prepare('SELECT image FROM carousel_images WHERE id = ? AND carousel_id = ?').get(imageId, c.id);
  if (!img) throw new HttpError(404, 'Not found');
  await db.prepare('DELETE FROM carousel_images WHERE id = ?').run(imageId);
  await removeImage(img.image);
  res.json({ images: await images(c.id) });
});

export default r;
