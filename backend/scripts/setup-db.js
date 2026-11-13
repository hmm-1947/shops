import mysql from 'mysql2/promise';
import { randomBytes } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { config } from '../src/config.js';
import { schema } from '../src/schema.js';

const envFile = new URL('../.env', import.meta.url);
const { host, port, database, user } = config.mysql;
const adminUser = process.env.MYSQL_ADMIN_USER ?? 'root';
const adminPassword = process.env.MYSQL_ADMIN_PASSWORD ?? '';
const ident = (s) => {
  if (!/^[A-Za-z0-9_]+$/.test(s)) throw new Error('Invalid MySQL name: ' + s);
  return s;
};

const admin = await mysql.createConnection({ host, port, user: adminUser, password: adminPassword, multipleStatements: false });
await admin.query('CREATE DATABASE IF NOT EXISTS ?? CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci', [ident(database)]);

let password = config.mysql.password;
let generated = false;
if (!password) {
  password = randomBytes(18).toString('base64url');
  generated = true;
}
await admin.query('CREATE USER IF NOT EXISTS ?@? IDENTIFIED BY ?', [ident(user), 'localhost', password]);
await admin.query('CREATE USER IF NOT EXISTS ?@? IDENTIFIED BY ?', [ident(user), '127.0.0.1', password]);
if (generated) {
  await admin.query('ALTER USER ?@? IDENTIFIED BY ?', [user, 'localhost', password]);
  await admin.query('ALTER USER ?@? IDENTIFIED BY ?', [user, '127.0.0.1', password]);
}
await admin.query('GRANT ALL PRIVILEGES ON ??.* TO ?@?', [database, user, 'localhost']);
await admin.query('GRANT ALL PRIVILEGES ON ??.* TO ?@?', [database, user, '127.0.0.1']);
await admin.end();

if (generated) {
  let env = readFileSync(envFile, 'utf8').replace(/^MYSQL_[A-Z_]+=.*\r?\n?/gm, '');
  if (!env.endsWith('\n')) env += '\n';
  env += `MYSQL_HOST=${host}\nMYSQL_PORT=${port}\nMYSQL_USER=${user}\nMYSQL_PASSWORD=${password}\nMYSQL_DATABASE=${database}\n`;
  writeFileSync(envFile, env);
  console.log('MySQL credentials written to backend/.env');
}

const app = await mysql.createConnection({ host, port, user, password, database });
for (const stmt of schema) await app.query(stmt);
await app.end();
console.log(`Database "${database}" ready with ${schema.length} tables`);
