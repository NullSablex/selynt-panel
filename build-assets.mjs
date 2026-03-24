import { build } from "esbuild";
import fs from "node:fs";
import path from "node:path";

const manifest = JSON.parse(fs.readFileSync("assets.manifest.json", "utf8"));
const outDir = path.resolve(manifest.outDir ?? "images/assets");

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

async function buildList(list, type) {
  for (const item of list) {
    const src = path.resolve(item.src);
    const out = path.resolve(outDir, item.out);

    if (!fs.existsSync(src)) throw new Error(`[${type}] Não achei: ${item.src}`);

    ensureDir(out);

    const bannerText =
  `/*! Selynt Panel | (c) ${new Date().getFullYear()} NullSablex | AGPL-3.0-or-later */`;

    await build({
      entryPoints: [src],
      outfile: out,
      bundle: false,
      minify: true,
      sourcemap: false,
      legalComments: "none",
      banner: { js: bannerText, css: bannerText }
    });

    console.log(`[${type}] OK: ${item.src} -> ${path.relative(process.cwd(), out)}`);
  }
}

await buildList(manifest.css ?? [], "CSS");
await buildList(manifest.js ?? [], "JS");