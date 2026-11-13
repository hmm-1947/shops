import { db } from './db.js';
import { discountFor, finalPrice } from './pricing.js';

const FROM = `FROM products p
  JOIN subcategories s ON s.id = p.subcategory_id
  JOIN categories c ON c.id = s.category_id
  LEFT JOIN brands b ON b.id = p.brand_id
  JOIN variants v ON v.product_id = p.id AND v.is_default = 1`;

const LIVE = "p.status = 'active' AND p.enabled = 1 AND s.enabled = 1 AND c.enabled = 1 AND (p.brand_id IS NULL OR b.enabled = 1)";

const COLS = `p.id, p.name, b.name AS brand, b.discount AS bd, c.discount AS cd,
  v.id AS vid, v.name AS vname, v.price, v.discount AS vd,
  (SELECT path FROM product_images WHERE product_id = p.id ORDER BY position, id LIMIT 1) AS image`;

const card = (r) => ({
  id: r.id,
  name: r.name,
  brand: r.brand,
  image: r.image,
  variant: { id: r.vid, name: r.vname, ...finalPrice(r.price, discountFor(r.vd, r.cd, r.bd)) },
});

export async function listProducts({ join = '', where = '1 = 1', params = [], order = 'p.id DESC', limit = 20, offset = 0 }) {
  const total = (await db.prepare(`SELECT COUNT(*) AS n ${FROM} ${join} WHERE ${LIVE} AND ${where}`).get(...params)).n;
  const rows = await db.prepare(`SELECT ${COLS} ${FROM} ${join} WHERE ${LIVE} AND ${where} ORDER BY ${order} LIMIT ? OFFSET ?`).all(...params, limit, offset);
  return { items: rows.map(card), total };
}

export async function productDetail(id) {
  const p = await db
    .prepare(
      `SELECT p.id, p.name, p.description, p.specifications, b.name AS brand, b.discount AS bd,
        c.id AS category_id, c.name AS category, c.discount AS cd, s.id AS subcategory_id, s.name AS subcategory
       FROM products p
       JOIN subcategories s ON s.id = p.subcategory_id
       JOIN categories c ON c.id = s.category_id
       LEFT JOIN brands b ON b.id = p.brand_id
       WHERE p.id = ? AND ${LIVE}`,
    )
    .get(id);
  if (!p) return null;
  const { bd, cd, specifications, ...rest } = p;
  return {
    ...rest,
    specifications: JSON.parse(specifications),
    images: (await db.prepare('SELECT path FROM product_images WHERE product_id = ? ORDER BY position, id').all(id)).map((i) => i.path),
    variants: (await db.prepare('SELECT id, name, price, discount, is_default FROM variants WHERE product_id = ? ORDER BY is_default DESC, id').all(id))
      .map((v) => ({ id: v.id, name: v.name, is_default: !!v.is_default, ...finalPrice(v.price, discountFor(v.discount, cd, bd)) })),
  };
}

export const classQuery = (ic) =>
  ({
    products: { join: 'JOIN item_class_products icp ON icp.product_id = p.id AND icp.item_class_id = ?', params: [ic.id], order: 'icp.position' },
    category: { where: 'c.id = ?', params: [ic.map_id] },
    subcategory: { where: 's.id = ?', params: [ic.map_id] },
    brand: { where: 'p.brand_id = ?', params: [ic.map_id] },
  })[ic.map_type];
