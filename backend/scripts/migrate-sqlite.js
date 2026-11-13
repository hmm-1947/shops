import { DatabaseSync } from 'node:sqlite';
import { existsSync } from 'node:fs';
import { pool } from '../src/db.js';
import { config } from '../src/config.js';

if (!existsSync(config.sqliteFile)) {
  console.log('No SQLite file at', config.sqliteFile);
  process.exit(0);
}

const lite = new DatabaseSync(config.sqliteFile, { readOnly: true });
const tables = [
  'admins',
  'categories',
  'subcategories',
  'brands',
  'products',
  'product_images',
  'variants',
  'carousels',
  'carousel_images',
  'item_classes',
  'item_class_products',
  'orders',
  'order_items',
];

const conn = await pool.getConnection();
try {
  await conn.query('SET FOREIGN_KEY_CHECKS = 0');
  for (const t of tables) {
    const rows = lite.prepare('SELECT * FROM ' + t).all();
    if (!rows.length) continue;
    const [{ n }] = (await conn.query('SELECT COUNT(*) AS n FROM ' + t))[0];
    if (n > 0) {
      console.log(t + ': skipped (MySQL table already has rows)');
      continue;
    }
    const cols = Object.keys(rows[0]);
    const sql = 'INSERT INTO ' + t + ' (' + cols.map((c) => '\`' + c + '\`').join(',') + ') VALUES ?';
    await conn.query(sql, [rows.map((r) => cols.map((c) => r[c]))]);
    console.log(t + ': copied ' + rows.length);
  }
  await conn.query('SET FOREIGN_KEY_CHECKS = 1');
} finally {
  conn.release();
}
await pool.end();
