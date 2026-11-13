import { Router } from 'express';
import { db } from '../db.js';
import { classQuery, listProducts, productDetail } from '../catalog.js';
import { HttpError, pid } from '../errors.js';

const r = Router();
const posInt = (v) => (Number.isInteger(Number(v)) && Number(v) > 0 ? Number(v) : null);
const paging = (q) => {
  const limit = Math.min(posInt(q.limit) ?? 20, 50);
  return { limit, offset: ((posInt(q.page) ?? 1) - 1) * limit };
};

r.get('/categories', (req, res) => {
  const subs = db
    .prepare(
      `SELECT s.id, s.category_id, s.name, s.image,
        (SELECT COUNT(*) FROM products p WHERE p.subcategory_id = s.id AND p.status = 'active') AS product_count
       FROM subcategories s WHERE s.enabled = 1 ORDER BY s.name`,
    )
    .all();
  res.json(
    db
      .prepare('SELECT id, name, image FROM categories WHERE enabled = 1 ORDER BY name')
      .all()
      .map((c) => {
        const own = subs.filter((s) => s.category_id === c.id).map(({ category_id, ...s }) => s);
        return { ...c, product_count: own.reduce((a, s) => a + s.product_count, 0), subcategories: own };
      }),
  );
});

r.get('/products', (req, res) => {
  const where = [];
  const params = [];
  const q = String(req.query.q ?? '').trim().slice(0, 100);
  if (q) {
    where.push("p.name LIKE ? ESCAPE '\\'");
    params.push(`%${q.replace(/[\\%_]/g, (c) => '\\' + c)}%`);
  }
  for (const [key, col] of [['category_id', 'c.id'], ['subcategory_id', 's.id'], ['brand_id', 'p.brand_id']]) {
    if (req.query[key] !== undefined) {
      where.push(`${col} = ?`);
      params.push(posInt(req.query[key]) ?? 0);
    }
  }
  res.json(listProducts({ where: where.join(' AND ') || '1 = 1', params, ...paging(req.query) }));
});

r.get('/products/:id', (req, res) => {
  const p = productDetail(pid(req.params.id));
  if (!p) throw new HttpError(404, 'Not found');
  res.json(p);
});

r.get('/home', (req, res) => {
  const rows = db.prepare('SELECT * FROM item_classes WHERE enabled = 1 ORDER BY position').all();
  const sections = rows
    .map((ic) => {
      const base = { id: ic.id, name: ic.name, display: ic.display, columns: ic.columns, view_all_after: ic.view_all_after };
      if (ic.map_type === 'carousel') {
        const items = db
          .prepare('SELECT ci.image FROM carousel_images ci JOIN carousels c ON c.id = ci.carousel_id WHERE c.id = ? AND c.enabled = 1 ORDER BY ci.position, ci.id')
          .all(ic.map_id);
        return { ...base, type: 'carousel', items, has_more: false };
      }
      const { items, total } = listProducts({ ...classQuery(ic), limit: ic.display === 'list' ? ic.view_all_after : 20 });
      return { ...base, type: 'products', items, has_more: total > items.length };
    })
    .filter((s) => s.items.length);
  res.json({ sections });
});

r.get('/item-classes/:id/products', (req, res) => {
  const ic = db.prepare('SELECT * FROM item_classes WHERE id = ? AND enabled = 1').get(pid(req.params.id));
  if (!ic || ic.map_type === 'carousel') throw new HttpError(404, 'Not found');
  res.json({ name: ic.name, columns: ic.columns, ...listProducts({ ...classQuery(ic), ...paging(req.query) }) });
});

export default r;
