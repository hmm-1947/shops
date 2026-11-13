import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const root = fileURLToPath(new URL('..', import.meta.url));

try {
  process.loadEnvFile(join(root, '.env'));
} catch {}

const jwtSecret = process.env.JWT_SECRET ?? '';
if (jwtSecret.length < 32) throw new Error('JWT_SECRET must be at least 32 characters. Run: npm run setup');

export const config = {
  port: Number(process.env.PORT ?? 4000),
  prod: process.env.NODE_ENV === 'production',
  jwtSecret,
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID ?? '',
  mysql: {
    host: process.env.MYSQL_HOST ?? '127.0.0.1',
    port: Number(process.env.MYSQL_PORT ?? 3306),
    user: process.env.MYSQL_USER ?? 'wematch',
    password: process.env.MYSQL_PASSWORD ?? '',
    database: process.env.MYSQL_DATABASE ?? 'wematch',
  },
  sqliteFile: process.env.DB_FILE ?? join(root, 'data', 'wematch.db'),
  uploadDir: join(root, 'uploads'),
  adminDir: join(root, 'admin'),
};
