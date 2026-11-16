import { db } from './db.js';

export const IN_HOUSE_MAX_KM = 5;

export async function activeCharges(conn = db) {
  return conn.prepare('SELECT id, name, value, type FROM charges WHERE enabled = 1 ORDER BY id').all();
}

export function applyCharges(rows, subtotal) {
  const lines = rows.map((c) => ({
    id: c.id,
    name: c.name,
    type: c.type,
    value: c.value,
    amount: c.type === 'percent' ? Math.round((subtotal * c.value) / 100) : Math.round(c.value * 100),
  }));
  return { lines, total: lines.reduce((a, l) => a + l.amount, 0) };
}

export async function getWarehouse(conn = db) {
  const rows = await conn.prepare("SELECT k, v FROM settings WHERE k IN ('warehouse_lat', 'warehouse_lng', 'warehouse_label')").all();
  const m = Object.fromEntries(rows.map((r) => [r.k, r.v]));
  const lat = Number.parseFloat(m.warehouse_lat);
  const lng = Number.parseFloat(m.warehouse_lng);
  return { lat: Number.isFinite(lat) ? lat : null, lng: Number.isFinite(lng) ? lng : null, label: m.warehouse_label ?? '' };
}

export function distanceKm(aLat, aLng, bLat, bLng) {
  const rad = (d) => (d * Math.PI) / 180;
  const dLat = rad(bLat - aLat);
  const dLng = rad(bLng - aLng);
  const x = Math.sin(dLat / 2) ** 2 + Math.cos(rad(aLat)) * Math.cos(rad(bLat)) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x));
}

export function deliveryFor(warehouse, lat, lng) {
  if (lat == null || lng == null || warehouse.lat == null || warehouse.lng == null) return { distance_km: null, delivery_mode: null };
  const km = Math.round(distanceKm(warehouse.lat, warehouse.lng, lat, lng) * 100) / 100;
  return { distance_km: km, delivery_mode: km <= IN_HOUSE_MAX_KM ? 'in_house' : 'courier' };
}
