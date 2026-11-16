import sharp from 'sharp';
import { db, tx } from '../src/db.js';
import { saveImage } from '../src/upload.js';

const SOURCES = ['beauty', 'skin-care', 'fragrances', 'womens-jewellery', 'womens-shoes', 'mens-shoes'];
const UA = { 'User-Agent': 'WeMatchSeed/1.0' };

const subs = new Map((await db.prepare('SELECT id, name FROM subcategories').all()).map((s) => [s.name, s.id]));
const pick = (title, tags, source) => {
  const t = `${title} ${tags.join(' ')}`.toLowerCase();
  const has = (...w) => w.some((x) => t.includes(x));
  if (source === 'beauty') return has('mascara', 'eyeshadow', 'eye', 'kajal', 'liner') ? 'Eye Make-Up' : has('nail') ? 'Nail Care' : 'Makeup';
  if (source === 'skin-care') return has('sun', 'spf') ? 'Sun Care' : has('mask', 'peel') ? 'Masks & Peels' : has('body', 'lotion') ? 'Body Care' : 'Skincare';
  if (source === 'fragrances') return 'Body Care';
  if (source === 'womens-jewellery') {
    if (has('earring')) return 'Earrings';
    if (has('necklace')) return 'Necklaces';
    if (has('bracelet', 'bangle')) return 'Bangles';
    if (has('ring')) return 'Rings';
    if (has('chain')) return 'Chains';
    if (has('pendant')) return 'Pendants';
    return 'Sets';
  }
  if (source === 'womens-shoes') return has('sandal') ? 'Sandals' : has('flat') ? 'Flats' : has('boot') ? 'Boots' : has('sneaker') ? 'Sneakers' : 'Heels';
  return has('sport', 'run') ? 'Sports Shoes' : has('boot') ? 'Boots' : 'Sneakers';
};

const rupeePaise = (usd) => Math.max(99, Math.round((usd * 85) / 10) * 10 - 1) * 100;
const titleCase = (s) => s.replace(/\b\w/g, (c) => c.toUpperCase());

async function fetchImage(url) {
  const r = await fetch(url, { headers: UA });
  if (!r.ok) throw new Error(`${r.status} ${url}`);
  return sharp(Buffer.from(await r.arrayBuffer())).flatten({ background: '#ffffff' }).png().toBuffer();
}

const brandIds = new Map((await db.prepare('SELECT id, name FROM brands').all()).map((b) => [b.name.toLowerCase(), b.id]));
let added = 0;
let skipped = 0;

for (const source of SOURCES) {
  const res = await fetch(`https://dummyjson.com/products/category/${source}?limit=30`, { headers: UA });
  const { products } = await res.json();
  for (const p of products) {
    const name = p.title.slice(0, 200);
    if (await db.prepare('SELECT 1 FROM products WHERE name = ?').get(name)) {
      skipped++;
      continue;
    }
    const subId = subs.get(pick(p.title, p.tags ?? [], source));
    if (!subId) continue;
    let buffers;
    try {
      buffers = await Promise.all(p.images.slice(0, 3).map(fetchImage));
    } catch (e) {
      console.log('skip (image failed):', name, e.message);
      continue;
    }
    const paths = [];
    for (const b of buffers) paths.push(await saveImage(b));

    let brandId = null;
    if (p.brand) {
      const key = p.brand.toLowerCase();
      brandId = brandIds.get(key) ?? null;
      if (!brandId) {
        const logo = await saveImage(buffers[0]);
        brandId = (await db.prepare('INSERT INTO brands(name, image) VALUES(?, ?)').run(p.brand.slice(0, 80), logo)).lastInsertRowid;
        brandIds.set(key, brandId);
      }
    }

    const mrp = rupeePaise(p.price);
    const disc = Math.min(60, Math.round(p.discountPercentage ?? 10));
    const isShoe = source.endsWith('shoes');
    const variants = isShoe
      ? ['UK 6', 'UK 7', 'UK 8', 'UK 9'].map((n, i) => [n, mrp, i === 0])
      : [['Default', mrp, true], ['Large', Math.round((mrp * 1.5) / 100) * 100, false]];
    const specs = [
      p.brand && { key: 'Brand', value: p.brand },
      { key: 'Category', value: titleCase(source.replace('-', ' ')) },
      p.weight && { key: 'Weight', value: `${p.weight} g` },
      p.warrantyInformation && { key: 'Warranty', value: p.warrantyInformation },
      p.returnPolicy && { key: 'Returns', value: p.returnPolicy },
    ].filter(Boolean);

    await tx(async (c) => {
      const pid = (
        await c
          .prepare("INSERT INTO products(name, subcategory_id, brand_id, description, specifications, status, enabled) VALUES(?, ?, ?, ?, ?, 'active', 1)")
          .run(name, subId, brandId, p.description ?? '', JSON.stringify(specs))
      ).lastInsertRowid;
      let pos = 0;
      for (const path of paths) await c.prepare('INSERT INTO product_images(product_id, path, position) VALUES(?, ?, ?)').run(pid, path, ++pos);
      for (const [vn, price, def] of variants) await c.prepare('INSERT INTO variants(product_id, name, price, discount, is_default) VALUES(?, ?, ?, ?, ?)').run(pid, vn, price, disc, +def);
    });
    added++;
    console.log('added:', name);
  }
}
console.log(`Done. Added ${added} products, skipped ${skipped} existing.`);
process.exit(0);
