import { Router } from 'express';
import { z } from 'zod';
import { db, tx } from '../../db.js';
import { HttpError, parse, pid } from '../../errors.js';
import { manyImages, saveImage, removeImage } from '../../upload.js';

const r = Router();
const money = z.number().int().positive().max(100000000);
const percent = z.number().min(0).max(100);

const createSchema = z.object({
  name: z.string().trim().min(1).max(200),
  subcategory_id: z.number().int().positive(),
  brand_id: z.number().int().positive().nullable(),
});

const detailsSchema = createSchema
  .extend({
    enabled: z.boolean(),
    description: z.string().trim().max(5000),
    specifications: z.array(z.object({ key: z.string().trim().min(1).max(80), value: z.string().trim().min(1).max(500) })).max(50),
    variants: z
      .array(
        z.object({
          id: z.number().int().positive().optional(),
          name: z.string().trim().min(1).max(80),
          price: money,
          discount: percent,
          is_default: z.boolean(),
        }),
      )
      .min(1)
      .max(30),
  })
  .refine((v) => v.variants.filter((x) => x.is_default).length === 1, { message: 'Mark exactly one variant as default', path: ['variants'] });

const mappingSchema = z.object({ subcategory_id: z.number().int().positive(), brand_id: z.number().int().positive().nullable() });

const images = (id) => db.prepare('SELECT id, path FROM product_images WHERE product_id = ? ORDER BY position, id').all(id);
const exists = async (id) => {
  if (!(await db.prepare('SELECT 1 FROM products WHERE id = ?').get(id))) throw new HttpError(404, 'Not found');
};

r.get('/', async (req, res) => {
  const q = String(req.query.q ?? '').trim().replace(/[\\%_]/g, (c) => '\\' + c);
  const status = ['draft', 'active'].includes(req.query.status) ? req.query.status : null;
  const limit = Math.min(Math.max(parseInt(req.query.limit) || 20, 1), 50);
  const page = Math.max(parseInt(req.query.page) || 1, 1);
  const where = 'p.name LIKE ? AND (? IS NULL OR p.status = ?)';
  const params = [`%${q}%`, status, status];
  const total = (await db.prepare(`SELECT COUNT(*) n FROM products p WHERE ${where}`).get(...params)).n;
  const items = await db
    .prepare(
      `SELECT p.id, p.name, p.status, p.enabled, s.name AS subcategory, c.name AS category, b.name AS brand,
        (SELECT path FROM product_images WHERE product_id = p.id ORDER BY position, id LIMIT 1) AS image
       FROM products p JOIN subcategories s ON s.id = p.subcategory_id JOIN categories c ON c.id = s.category_id
       LEFT JOIN brands b ON b.id = p.brand_id WHERE ${where} ORDER BY p.id DESC LIMIT ? OFFSET ?`,
    )
    .all(...params, limit, (page - 1) * limit);
  res.json({ items, total });
});

r.post('/', async (req, res) => {
  const b = parse(createSchema, req.body);
  const info = await db.prepare('INSERT INTO products(name, subcategory_id, brand_id) VALUES(?, ?, ?)').run(b.name, b.subcategory_id, b.brand_id);
  res.status(201).json({ id: info.lastInsertRowid });
});

r.get('/:id', async (req, res) => {
  const id = pid(req.params.id);
  const p = await db
    .prepare(
      `SELECT p.*, c.name AS category FROM products p JOIN subcategories s ON s.id = p.subcategory_id
       JOIN categories c ON c.id = s.category_id WHERE p.id = ?`,
    )
    .get(id);
  if (!p) throw new HttpError(404, 'Not found');
  const variants = await db.prepare('SELECT id, name, price, discount, is_default FROM variants WHERE product_id = ? ORDER BY id').all(id);
  res.json({
    ...p,
    enabled: !!p.enabled,
    specifications: JSON.parse(p.specifications),
    images: await images(id),
    variants: variants.map((v) => ({ ...v, is_default: !!v.is_default })),
  });
});

r.put('/:id', async (req, res) => {
  const id = pid(req.params.id);
  await exists(id);
  const b = parse(detailsSchema, req.body);
  if (!(await images(id)).length) throw new HttpError(400, 'Add at least one product image');
  await tx(async (c) => {
    await c
      .prepare("UPDATE products SET name = ?, subcategory_id = ?, brand_id = ?, enabled = ?, description = ?, specifications = ?, status = 'active' WHERE id = ?")
      .run(b.name, b.subcategory_id, b.brand_id, +b.enabled, b.description, JSON.stringify(b.specifications), id);

    const current = (await c.prepare('SELECT id FROM variants WHERE product_id = ?').all(id)).map((v) => v.id);
    const keep = b.variants.filter((v) => v.id).map((v) => v.id);
    if (keep.some((k) => !current.includes(k))) throw new HttpError(400, 'Unknown variant');
    for (const gone of current.filter((x) => !keep.includes(x))) await c.prepare('DELETE FROM variants WHERE id = ?').run(gone);

    await c.prepare('UPDATE variants SET is_default = 0 WHERE product_id = ?').run(id);
    for (const v of b.variants) {
      if (v.id) await c.prepare('UPDATE variants SET name = ?, price = ?, discount = ?, is_default = ? WHERE id = ? AND product_id = ?').run(v.name, v.price, v.discount, +v.is_default, v.id, id);
      else await c.prepare('INSERT INTO variants(product_id, name, price, discount, is_default) VALUES(?, ?, ?, ?, ?)').run(id, v.name, v.price, v.discount, +v.is_default);
    }
  });
  res.json({ ok: true });
});

r.delete('/:id', async (req, res) => {
  const id = pid(req.params.id);
  await exists(id);
  const files = await images(id);
  await db.prepare('DELETE FROM products WHERE id = ?').run(id);
  await Promise.all(files.map((f) => removeImage(f.path)));
  res.json({ ok: true });
});

r.post('/:id/images', manyImages, async (req, res) => {
  const id = pid(req.params.id);
  await exists(id);
  if (!req.files?.length) throw new HttpError(400, 'images: required');
  const saved = [];
  try {
    for (const f of req.files) saved.push(await saveImage(f.buffer));
  } catch (e) {
    await Promise.all(saved.map(removeImage));
    throw e;
  }
  let pos = (await db.prepare('SELECT COALESCE(MAX(position), 0) AS m FROM product_images WHERE product_id = ?').get(id)).m;
  for (const path of saved) await db.prepare('INSERT INTO product_images(product_id, path, position) VALUES(?, ?, ?)').run(id, path, ++pos);
  res.status(201).json({ images: await images(id) });
});

r.delete('/:id/images/:imageId', async (req, res) => {
  const id = pid(req.params.id);
  const imageId = pid(req.params.imageId);
  const img = await db.prepare('SELECT path FROM product_images WHERE id = ? AND product_id = ?').get(imageId, id);
  if (!img) throw new HttpError(404, 'Not found');
  const p = await db.prepare('SELECT status FROM products WHERE id = ?').get(id);
  if (p.status === 'active' && (await images(id)).length <= 1) throw new HttpError(400, 'A live product needs at least one image');
  await db.prepare('DELETE FROM product_images WHERE id = ?').run(imageId);
  await removeImage(img.path);
  res.json({ images: await images(id) });
});

export const mapProduct = async (req, res) => {
  const id = pid(req.params.id);
  await exists(id);
  const b = parse(mappingSchema, req.body);
  await db.prepare('UPDATE products SET subcategory_id = ?, brand_id = ? WHERE id = ?').run(b.subcategory_id, b.brand_id, id);
  res.json({ ok: true });
};

export default r;
