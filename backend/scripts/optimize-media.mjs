/**
 * Runs ON the server that holds the uploads (the iMac). Additive only:
 * writes optimized copies under <uploads>/v2/ and never touches originals.
 *
 *   node optimize-media.mjs /path/to/uploads
 *
 * For every image: v2/<dir>/<name>.jpg (≤1600 px) + v2/<dir>/thumb/<name>.jpg (≤480 px),
 * progressive mozjpeg, EXIF orientation applied. Skips files already done.
 */
import { existsSync, mkdirSync, readdirSync, statSync } from 'node:fs';
import { join, relative, dirname, basename } from 'node:path';
import sharp from 'sharp';

const root = process.argv[2];
if (!root || !existsSync(root)) throw new Error('usage: node optimize-media.mjs <uploads dir>');
sharp.concurrency(2);

const walk = (d) => readdirSync(d).flatMap((f) => {
  const p = join(d, f);
  if (f === 'v2') return [];
  return statSync(p).isDirectory() ? walk(p) : /\.(jpe?g|png|webp|heic)$/i.test(f) ? [p] : [];
});

let before = 0, after = 0, done = 0, skipped = 0;
for (const src of walk(root)) {
  const rel = relative(root, src);
  const name = basename(rel).replace(/\.[a-z0-9]+$/i, '.jpg');
  const full = join(root, 'v2', dirname(rel), name);
  const thumb = join(root, 'v2', dirname(rel), 'thumb', name);
  if (existsSync(full) && existsSync(thumb)) { skipped++; continue; }
  mkdirSync(dirname(thumb), { recursive: true });
  try {
    await sharp(src).rotate().resize({ width: 1600, height: 1600, fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 82, progressive: true, mozjpeg: true }).toFile(full);
    await sharp(src).rotate().resize({ width: 480, height: 480, fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 78, progressive: true, mozjpeg: true }).toFile(thumb);
    before += statSync(src).size; after += statSync(full).size; done++;
    process.stdout.write(`\r${done} optimized`);
  } catch (e) {
    console.warn(`\n! ${rel}: ${e.message}`);
  }
}
const mb = (b) => (b / 1048576).toFixed(1);
console.log(`\n${done} optimized, ${skipped} already done — ${mb(before)} MB → ${mb(after)} MB`);
