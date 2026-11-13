import sharp from 'sharp';
import { randomUUID } from 'node:crypto';
import { join } from 'node:path';
import { mkdirSync } from 'node:fs';
import { db } from '../src/db.js';
import { config } from '../src/config.js';

if (db.prepare('SELECT COUNT(*) AS n FROM categories').get().n > 0 && !process.argv.includes('--force')) {
  console.log('Catalog is not empty. Nothing seeded. Use --force to add demo data anyway.');
  process.exit(0);
}

mkdirSync(config.uploadDir, { recursive: true });

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

async function art(label, w, h, c1, c2, fg = '#ffffff', size = 0) {
  const fs = size || Math.round(Math.min(w, h) / 9);
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}">
    <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${c2}"/></linearGradient></defs>
    <rect width="${w}" height="${h}" fill="url(#g)"/>
    <circle cx="${w * 0.5}" cy="${h * 0.45}" r="${Math.min(w, h) * 0.22}" fill="${fg}" fill-opacity="0.18"/>
    <text x="50%" y="${h * 0.52}" font-family="Arial, sans-serif" font-size="${fs}" font-weight="700" fill="${fg}" text-anchor="middle">${esc(label)}</text>
  </svg>`;
  const name = `${randomUUID()}.webp`;
  await sharp(Buffer.from(svg)).webp({ quality: 80 }).toFile(join(config.uploadDir, name));
  return `/uploads/${name}`;
}

const palette = [
  ['#3a2f1a', '#1b160c'],
  ['#2c2c33', '#141418'],
  ['#3d2230', '#1a0e15'],
  ['#1f3a3a', '#0d1a1a'],
  ['#3b3320', '#1a160b'],
  ['#2a2540', '#12101d'],
];
const pick = (i) => palette[i % palette.length];

const taxonomy = {
  Cosmetics: ['Makeup', 'Skincare', 'Hair Care', 'Nail Care', 'Beauty Tools', 'Masks & Peels', 'Eye Make-Up', 'Body Care', 'Sun Care'],
  Jewellery: ['Necklaces', 'Earrings', 'Rings', 'Bangles', 'Chains', 'Pendants', 'Sets', 'Mangalsutra', 'Nose Pins'],
  Footwear: ['Sneakers', 'Sandals', 'Heels', 'Flats', 'Boots', 'Sports Shoes'],
};

const brands = ['Lakme', 'Maybelline', 'Swiss Beauty', "L'Oreal", 'Nike', 'Titan'];

const products = [
  ['Matte Lipstick', 'Makeup', 'Lakme', 399, 38],
  ['9 To 5 Primer + Matte Foundation', 'Makeup', 'Lakme', 349, 20],
  ['Face Cream', 'Skincare', 'Maybelline', 499, 20],
  ['Perfume', 'Body Care', null, 1999, 25],
  ['Premium Perfume', 'Body Care', null, 2499, 28],
  ['Kajal Pencil', 'Eye Make-Up', 'Swiss Beauty', 249, 10],
  ['Nail Polish Set', 'Nail Care', "L'Oreal", 599, 15],
  ['Sunscreen SPF 50', 'Sun Care', "L'Oreal", 699, 12],
  ["Men's Sneakers", 'Sneakers', 'Nike', 2999, 50],
  ['Women Sandals', 'Sandals', null, 1299, 38],
  ['Block Heels', 'Heels', null, 1799, 30],
  ['Gold Earrings', 'Earrings', 'Titan', 2499, 40],
  ['Necklace', 'Necklaces', 'Titan', 2999, 33],
  ['Silver Ring', 'Rings', null, 1499, 20],
  ['Gold Bangles', 'Bangles', 'Titan', 4999, 15],
  ['Fancy Chain', 'Chains', null, 1999, 18],
];

const ids = { cat: {}, sub: {}, brand: {}, product: {} };

let ci = 0;
for (const [cat, subs] of Object.entries(taxonomy)) {
  const [c1, c2] = pick(ci);
  const img = await art(cat, 400, 400, c1, c2, '#E9B93F');
  ids.cat[cat] = Number(db.prepare('INSERT INTO categories(name, image, discount) VALUES(?, ?, 0)').run(cat, img).lastInsertRowid);
  for (const [j, s] of subs.entries()) {
    const [a, b] = pick(j + ci);
    const simg = await art(s, 300, 300, a, b, '#f3e6c4');
    ids.sub[s] = Number(db.prepare('INSERT INTO subcategories(category_id, name, image) VALUES(?, ?, ?)').run(ids.cat[cat], s, simg).lastInsertRowid);
  }
  ci++;
}

for (const [i, b] of brands.entries()) {
  const img = await art(b, 300, 300, ...pick(i), '#ffffff', 40);
  ids.brand[b] = Number(db.prepare('INSERT INTO brands(name, image, discount) VALUES(?, ?, 0)').run(b, img).lastInsertRowid);
}

for (const [i, [name, sub, brand, mrp, disc]] of products.entries()) {
  const pr = db
    .prepare('INSERT INTO products(name, subcategory_id, brand_id, description, specifications, status) VALUES(?, ?, ?, ?, ?, ?)')
    .run(
      name,
      ids.sub[sub],
      brand ? ids.brand[brand] : null,
      `${name} - demo product for UI checks. Genuine product, easy returns.`,
      JSON.stringify([['Type', sub], ['Country of origin', 'India'], ['Shelf life', '24 months']].map(([key, value]) => ({ key, value }))),
      'active',
    );
  const pid = Number(pr.lastInsertRowid);
  ids.product[name] = pid;
  for (let k = 0; k < 3; k++) {
    const img = await art(name, 800, 800, ...pick(i + k), '#f3e6c4', 52);
    db.prepare('INSERT INTO product_images(product_id, path, position) VALUES(?, ?, ?)').run(pid, img, k);
  }
  db.prepare('INSERT INTO variants(product_id, name, price, discount, is_default) VALUES(?, ?, ?, ?, 1)').run(pid, 'Default', mrp * 100, disc);
  if (sub === 'Makeup' || sub === 'Skincare') {
    db.prepare('INSERT INTO variants(product_id, name, price, discount, is_default) VALUES(?, ?, ?, ?, 0)').run(pid, 'Large', Math.round(mrp * 1.5) * 100, disc);
  }
}

const banners = [];
for (const [i, t] of ['Match Your Style', 'Flat 25% OFF', 'New Arrivals', 'Festive Edit'].entries()) {
  banners.push(await art(t, 1000, 500, ...pick(i), '#E9B93F', 64));
}
const car = Number(db.prepare('INSERT INTO carousels(name) VALUES(?)').run('Home banner').lastInsertRowid);
banners.forEach((img, i) => db.prepare('INSERT INTO carousel_images(carousel_id, image, position) VALUES(?, ?, ?)').run(car, img, i));

const section = (name, display, columns, after, type, mapId, pos) =>
  Number(
    db
      .prepare('INSERT INTO item_classes(name, display, columns, view_all_after, map_type, map_id, position) VALUES(?, ?, ?, ?, ?, ?, ?)')
      .run(name, display, columns, after, type, mapId, pos).lastInsertRowid,
  );

const picks = (cls, names) =>
  names.forEach((n, i) => db.prepare('INSERT INTO item_class_products(item_class_id, product_id, position) VALUES(?, ?, ?)').run(cls, ids.product[n], i));

section('Banner', 'scroll', 2, 6, 'carousel', car, 1);
picks(section('Trending Products', 'scroll', 4, 6, 'products', null, 2), ["Men's Sneakers", 'Premium Perfume', 'Block Heels', 'Necklace', 'Gold Earrings']);
picks(section('Buy Again', 'list', 4, 4, 'products', null, 3), ['Matte Lipstick', 'Face Cream', 'Perfume', "Men's Sneakers"]);
picks(section('Recommended for You', 'list', 4, 4, 'products', null, 4), ['Face Cream', 'Matte Lipstick', "Men's Sneakers", 'Perfume']);
picks(section('Trending Now', 'list', 4, 4, 'products', null, 5), ['Gold Earrings', 'Necklace', 'Women Sandals', 'Silver Ring']);

console.log('Demo catalog seeded:', Object.keys(ids.cat).join(', '));
