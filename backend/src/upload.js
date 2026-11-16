import multer from 'multer';
import sharp from 'sharp';
import { randomUUID } from 'node:crypto';
import { mkdirSync } from 'node:fs';
import { unlink } from 'node:fs/promises';
import { join, basename } from 'node:path';
import { config } from './config.js';
import { HttpError } from './errors.js';

mkdirSync(config.uploadDir, { recursive: true });

const mem = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 8 * 1024 * 1024, files: 10, fields: 30, parts: 50 },
  fileFilter: (req, file, cb) =>
    /^image\/(jpeg|png|webp|gif|avif)$/.test(file.mimetype) ? cb(null, true) : cb(new HttpError(400, 'Only JPEG, PNG, WebP, GIF or AVIF images are allowed')),
});

export const oneImage = mem.single('image');
export const manyImages = mem.array('images', 10);
const imageAndBannerFields = mem.fields([
  { name: 'image', maxCount: 1 },
  { name: 'banner', maxCount: 1 },
]);

export const imageAndBanner = (req, res, next) =>
  imageAndBannerFields(req, res, (err) => {
    if (err) return next(err);
    req.file = req.files?.image?.[0];
    req.bannerFile = req.files?.banner?.[0];
    next();
  });

export async function saveImage(buffer) {
  const name = `${randomUUID()}.webp`;
  try {
    await sharp(buffer, { limitInputPixels: 40e6 })
      .rotate()
      .resize({ width: 1600, height: 1600, fit: 'inside', withoutEnlargement: true })
      .webp({ quality: 82 })
      .toFile(join(config.uploadDir, name));
  } catch {
    throw new HttpError(400, 'Invalid image file');
  }
  return `/uploads/${name}`;
}

export const removeImage = (path) =>
  path?.startsWith('/uploads/') ? unlink(join(config.uploadDir, basename(path))).catch(() => {}) : undefined;
