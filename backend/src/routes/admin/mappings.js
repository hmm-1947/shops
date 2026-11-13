import { Router } from 'express';
import { db } from '../../db.js';
import { HttpError } from '../../errors.js';
import { mapProduct } from './products.js';

const r = Router();

r.get('/', async (req, res) => {
  res.json({
    categories: await db
      .prepare(
        `SELECT c.id, c.name, COUNT(p.id) AS count FROM categories c LEFT JOIN subcategories s ON s.category_id = c.id
         LEFT JOIN products p ON p.subcategory_id = s.id GROUP BY c.id, c.name ORDER BY c.name`,
      )
      .all(),
    subcategories: await db
      .prepare(
        `SELECT s.id, s.name, c.name AS category, COUNT(p.id) AS count FROM subcategories s JOIN categories c ON c.id = s.category_id
         LEFT JOIN products p ON p.subcategory_id = s.id GROUP BY s.id, s.name, c.name ORDER BY c.name, s.name`,
      )
      .all(),
    brands: await db
      .prepare('SELECT b.id, b.name, COUNT(p.id) AS count FROM brands b LEFT JOIN products p ON p.brand_id = b.id GROUP BY b.id, b.name ORDER BY b.name')
      .all(),
  });
});

const columns = { category: 's.category_id', subcategory: 'p.subcategory_id', brand: 'p.brand_id' };

r.get('/products', async (req, res) => {
  const col = columns[req.query.type];
  const id = Number(req.query.id);
  if (!col || !Number.isInteger(id) || id < 1) throw new HttpError(400, 'type and id required');
  res.json(
    await db
      .prepare(
        `SELECT p.id, p.name, p.status, p.subcategory_id, p.brand_id FROM products p
         JOIN subcategories s ON s.id = p.subcategory_id WHERE ${col} = ? ORDER BY p.name`,
      )
      .all(id),
  );
});

r.patch('/products/:id', mapProduct);

export default r;
