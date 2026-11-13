import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { config } from './config.js';

mkdirSync(dirname(config.dbFile), { recursive: true });

export const db = new DatabaseSync(config.dbFile);
db.exec('PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON;');

db.exec(`
CREATE TABLE IF NOT EXISTS admins (
  id INTEGER PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  failed_attempts INTEGER NOT NULL DEFAULT 0,
  locked_until INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS categories (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE COLLATE NOCASE,
  image TEXT NOT NULL,
  discount REAL NOT NULL DEFAULT 0 CHECK (discount BETWEEN 0 AND 100),
  enabled INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS subcategories (
  id INTEGER PRIMARY KEY,
  category_id INTEGER NOT NULL REFERENCES categories(id),
  name TEXT NOT NULL COLLATE NOCASE,
  image TEXT NOT NULL,
  enabled INTEGER NOT NULL DEFAULT 1,
  UNIQUE (category_id, name)
);
CREATE TABLE IF NOT EXISTS brands (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE COLLATE NOCASE,
  image TEXT NOT NULL,
  discount REAL NOT NULL DEFAULT 0 CHECK (discount BETWEEN 0 AND 100),
  enabled INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS products (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  subcategory_id INTEGER NOT NULL REFERENCES subcategories(id),
  brand_id INTEGER REFERENCES brands(id),
  description TEXT NOT NULL DEFAULT '',
  specifications TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active')),
  enabled INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL DEFAULT (unixepoch())
);
CREATE INDEX IF NOT EXISTS idx_products_sub ON products(subcategory_id);
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand_id);
CREATE TABLE IF NOT EXISTS product_images (
  id INTEGER PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  path TEXT NOT NULL,
  position INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS variants (
  id INTEGER PRIMARY KEY,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  price INTEGER NOT NULL CHECK (price > 0),
  discount REAL NOT NULL DEFAULT 0 CHECK (discount BETWEEN 0 AND 100),
  is_default INTEGER NOT NULL DEFAULT 0
);
CREATE UNIQUE INDEX IF NOT EXISTS one_default_variant ON variants(product_id) WHERE is_default = 1;
CREATE TABLE IF NOT EXISTS carousels (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE COLLATE NOCASE,
  enabled INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS carousel_images (
  id INTEGER PRIMARY KEY,
  carousel_id INTEGER NOT NULL REFERENCES carousels(id) ON DELETE CASCADE,
  image TEXT NOT NULL,
  position INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS item_classes (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  display TEXT NOT NULL CHECK (display IN ('scroll', 'list')),
  columns INTEGER NOT NULL DEFAULT 2 CHECK (columns IN (2, 4)),
  view_all_after INTEGER NOT NULL DEFAULT 6 CHECK (view_all_after >= 1),
  map_type TEXT NOT NULL CHECK (map_type IN ('products', 'category', 'subcategory', 'brand', 'carousel')),
  map_id INTEGER,
  position INTEGER NOT NULL,
  enabled INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS item_class_products (
  item_class_id INTEGER NOT NULL REFERENCES item_classes(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  position INTEGER NOT NULL,
  PRIMARY KEY (item_class_id, product_id)
);
CREATE TABLE IF NOT EXISTS orders (
  id INTEGER PRIMARY KEY,
  uid TEXT NOT NULL,
  customer_name TEXT NOT NULL DEFAULT '',
  customer_email TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  city TEXT NOT NULL DEFAULT '',
  address TEXT NOT NULL,
  payment_method TEXT NOT NULL CHECK (payment_method IN ('upi', 'card', 'net', 'wallet', 'cod')),
  subtotal INTEGER NOT NULL,
  delivery_fee INTEGER NOT NULL,
  total INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'placed' CHECK (status IN ('placed', 'confirmed', 'packed', 'out_for_delivery', 'delivered', 'cancelled')),
  created_at INTEGER NOT NULL DEFAULT (unixepoch())
);
CREATE INDEX IF NOT EXISTS idx_orders_uid ON orders(uid);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status, created_at);
CREATE TABLE IF NOT EXISTS order_items (
  id INTEGER PRIMARY KEY,
  order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL,
  variant_id INTEGER NOT NULL,
  product_name TEXT NOT NULL,
  brand TEXT,
  variant_name TEXT NOT NULL,
  image TEXT,
  mrp INTEGER NOT NULL,
  discount REAL NOT NULL,
  price INTEGER NOT NULL,
  qty INTEGER NOT NULL CHECK (qty > 0)
);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
`);

export function tx(fn) {
  db.exec('BEGIN IMMEDIATE');
  try {
    const r = fn();
    db.exec('COMMIT');
    return r;
  } catch (e) {
    db.exec('ROLLBACK');
    throw e;
  }
}
