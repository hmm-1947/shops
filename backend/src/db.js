import mysql from 'mysql2/promise';
import { config } from './config.js';
import { schema, columnMigrations } from './schema.js';

export const pool = mysql.createPool({
  ...config.mysql,
  waitForConnections: true,
  connectionLimit: 10,
  charset: 'utf8mb4',
  decimalNumbers: true,
  dateStrings: true,
});

const wrap = (conn) => ({
  prepare: (sql) => ({
    all: async (...p) => (await conn.query(sql, p))[0],
    get: async (...p) => (await conn.query(sql, p))[0][0],
    run: async (...p) => {
      const [r] = await conn.query(sql, p);
      return { lastInsertRowid: r.insertId, changes: r.affectedRows };
    },
  }),
});

export const db = wrap(pool);

export async function tx(fn) {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const result = await fn(wrap(conn));
    await conn.commit();
    return result;
  } catch (e) {
    await conn.rollback().catch(() => {});
    throw e;
  } finally {
    conn.release();
  }
}

export async function ensureSchema() {
  for (const stmt of schema) await pool.query(stmt);
  for (const [table, column, ddl] of columnMigrations) {
    const [rows] = await pool.query('SELECT 1 FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = ? AND column_name = ?', [table, column]);
    if (!rows.length) await pool.query(`ALTER TABLE \`${table}\` ADD COLUMN \`${column}\` ${ddl}`);
  }

}

ensureSchema().catch((e) => {
  console.error("MySQL is not reachable or not set up (" + e.message + "). Run: npm run db:setup");
  process.exit(1);
});
