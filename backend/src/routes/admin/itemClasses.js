import { Router } from 'express';
import { z } from 'zod';
import { db, tx } from '../../db.js';
import { HttpError, parse, pid } from '../../errors.js';

const r = Router();
const targets = { category: 'categories', subcategory: 'subcategories', brand: 'brands', carousel: 'carousels' };

const schema = z
  .object({
    name: z.string().trim().min(1).max(80),
    display: z.enum(['scroll', 'list']),
    columns: z.union([z.literal(2), z.literal(4)]),
    view_all_after: z.number().int().min(1).max(50),
    map_type: z.enum(['products', 'category', 'subcategory', 'brand', 'carousel']),
    map_id: z.number().int().positive().nullable(),
    product_ids: z.array(z.number().int().positive()).max(200),
    enabled: z.boolean(),
  })
  .superRefine((v, ctx) => {
    if (v.map_type === 'products' && !v.product_ids.length) ctx.addIssue({ code: 'custom', path: ['product_ids'], message: 'Select at least one product' });
    if (v.map_type !== 'products' && !v.map_id) ctx.addIssue({ code: 'custom', path: ['map_id'], message: 'Select a target' });
  });

const find = (id) => {
  const ic = db.prepare('SELECT * FROM item_classes WHERE id = ?').get(id);
  if (!ic) throw new HttpError(404, 'Not found');
  return ic;
};

r.get('/', (req, res) =>
  res.json(
    db
      .prepare(
        `SELECT ic.*, CASE ic.map_type
           WHEN 'category' THEN (SELECT name FROM categories WHERE id = ic.map_id)
           WHEN 'subcategory' THEN (SELECT name FROM subcategories WHERE id = ic.map_id)
           WHEN 'brand' THEN (SELECT name FROM brands WHERE id = ic.map_id)
           WHEN 'carousel' THEN (SELECT name FROM carousels WHERE id = ic.map_id)
           ELSE (SELECT COUNT(*) || ' products' FROM item_class_products WHERE item_class_id = ic.id) END AS map_label
         FROM item_classes ic ORDER BY ic.position`,
      )
      .all(),
  ),
);

r.post('/reorder', (req, res) => {
  const { ids } = parse(z.object({ ids: z.array(z.number().int().positive()) }), req.body);
  const all = db.prepare('SELECT id FROM item_classes').all().map((x) => x.id);
  if (ids.length !== all.length || new Set(ids).size !== ids.length || !ids.every((i) => all.includes(i))) throw new HttpError(400, 'ids must list every item class once');
  tx(() => ids.forEach((id, i) => db.prepare('UPDATE item_classes SET position = ? WHERE id = ?').run(i + 1, id)));
  res.json({ ok: true });
});

r.get('/:id', (req, res) => {
  const ic = find(pid(req.params.id));
  const products = db
    .prepare('SELECT p.id, p.name FROM item_class_products icp JOIN products p ON p.id = icp.product_id WHERE icp.item_class_id = ? ORDER BY icp.position')
    .all(ic.id);
  res.json({ ...ic, enabled: !!ic.enabled, products });
});

function save(id, b) {
  const manual = b.map_type === 'products';
  if (!manual && !db.prepare(`SELECT 1 FROM ${targets[b.map_type]} WHERE id = ?`).get(b.map_id)) throw new HttpError(400, 'map_id: not found');
  return tx(() => {
    const args = [b.name, b.display, b.columns, b.view_all_after, b.map_type, manual ? null : b.map_id, +b.enabled];
    if (id) {
      db.prepare('UPDATE item_classes SET name = ?, display = ?, columns = ?, view_all_after = ?, map_type = ?, map_id = ?, enabled = ? WHERE id = ?').run(...args, id);
    } else {
      const pos = db.prepare('SELECT COALESCE(MAX(position), 0) + 1 AS p FROM item_classes').get().p;
      id = db
        .prepare('INSERT INTO item_classes(name, display, columns, view_all_after, map_type, map_id, enabled, position) VALUES(?, ?, ?, ?, ?, ?, ?, ?)')
        .run(...args, pos).lastInsertRowid;
    }
    db.prepare('DELETE FROM item_class_products WHERE item_class_id = ?').run(id);
    if (manual) {
      [...new Set(b.product_ids)].forEach((pidx, i) => db.prepare('INSERT INTO item_class_products(item_class_id, product_id, position) VALUES(?, ?, ?)').run(id, pidx, i + 1));
    }
    return id;
  });
}

r.post('/', (req, res) => res.status(201).json({ id: save(null, parse(schema, req.body)) }));

r.put('/:id', (req, res) => {
  const ic = find(pid(req.params.id));
  save(ic.id, parse(schema, req.body));
  res.json({ ok: true });
});

r.delete('/:id', (req, res) => {
  db.prepare('DELETE FROM item_classes WHERE id = ?').run(find(pid(req.params.id)).id);
  res.json({ ok: true });
});

export default r;
