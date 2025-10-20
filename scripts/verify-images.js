#!/usr/bin/env node
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '..');
const CONTENT_DIR = path.join(ROOT, 'src', 'content');
const PUBLIC_DIR = path.join(ROOT, 'public');
const ASSETS_DIR = path.join(ROOT, 'src', 'assets');

const FRONT_KEYS = new Set(['heroImage', 'image', 'hero', 'img']);

async function walk(dir) {
  let files = [];
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const e of entries) {
    const res = path.join(dir, e.name);
    if (e.isDirectory()) files = files.concat(await walk(res));
    else files.push(res);
  }
  return files;
}

function extractFrontmatter(content) {
  if (!content.startsWith('---')) return null;
  const end = content.indexOf('\n---', 3);
  if (end === -1) return null;
  return content.slice(3, end + 1);
}

function parseFrontKeys(front) {
  const lines = front.split(/\r?\n/);
  const found = [];
  for (const line of lines) {
    const m = line.match(/^\s*([a-zA-Z0-9_]+):\s*(.+)$/);
    if (!m) continue;
    const key = m[1];
    let val = m[2].trim();
    // remove surrounding quotes
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    if (FRONT_KEYS.has(key) && val) found.push({ key, val });
  }
  return found;
}

async function fileExists(p) {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

async function main() {
  const report = [];
  try {
    const allFiles = await walk(CONTENT_DIR);
    const mdFiles = allFiles.filter((f) => f.endsWith('.md') || f.endsWith('.mdx'));

    for (const file of mdFiles) {
      const raw = await fs.readFile(file, 'utf8');
      const front = extractFrontmatter(raw);
      if (!front) continue;
      const keys = parseFrontKeys(front);
      for (const { key, val } of keys) {
        // skip remote URLs
        if (/^https?:\/\//.test(val)) continue;

        // normalize path
        const candidatePaths = [];
        if (val.startsWith('/')) {
          candidatePaths.push(path.join(PUBLIC_DIR, val.replace(/^\//, '')));
        } else {
          // try public and src/assets
          candidatePaths.push(path.join(PUBLIC_DIR, val));
          candidatePaths.push(path.join(ASSETS_DIR, val));
        }

        let found = false;
        for (const cp of candidatePaths) {
          if (await fileExists(cp)) {
            found = true;
            break;
          }
        }

        if (!found) {
          report.push({ file: path.relative(ROOT, file), key, val, tried: candidatePaths.map(p => path.relative(ROOT, p)) });
        }
      }
    }

    if (report.length > 0) {
      console.error('Missing frontmatter image files detected:');
      for (const r of report) {
        console.error(`- ${r.file}: ${r.key} -> ${r.val}\n  tried: ${r.tried.join(', ')}`);
      }
      process.exitCode = 2;
      return;
    }

    console.log('All frontmatter image references resolved.');
  } catch (err) {
    console.error('Error while verifying images:', err);
    process.exitCode = 3;
  }
}

main();
