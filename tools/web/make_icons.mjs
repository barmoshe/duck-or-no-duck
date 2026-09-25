// Renders tools/web/icon.svg to the PNG icons the game and the web page use.
//   node tools/web/make_icons.mjs
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const here = dirname(fileURLToPath(import.meta.url));
const svg = readFileSync(join(here, 'icon.svg'), 'utf8');
const out = join(here, '..', '..', 'game', 'assets', 'icon');
const browser = await chromium.launch();
for (const size of [1024, 512, 180]) {
	const page = await browser.newPage({ viewport: { width: size, height: size } });
	await page.setContent(`<html><body style="margin:0;background:transparent">${svg.replace('<svg ', `<svg width="${size}" height="${size}" `)}</body></html>`);
	await page.screenshot({ path: join(out, size === 1024 ? 'icon.png' : `icon_${size}.png`), omitBackground: true });
	await page.close();
}
await browser.close();
console.log('icons written to', out);
