// Plays the web build in headless Chromium as a landscape iPhone (932x430, touch) and checks:
//   1. the canvas fills the window   2. no page errors   3. a tap on PLAY starts a run and
//   sound really comes out (every AudioContext destination is tapped into an AnalyserNode)
//   4. a joystick drag moves the player (the view changes)
// Screenshots go to $SHOTS (default: build/webtest-*.png).
const PW = process.env.PLAYWRIGHT_MODULE || '/opt/node22/lib/node_modules/playwright/index.mjs';
const { chromium } = await import(PW);
const url = process.argv[2] || 'http://localhost:8791/index.html';
const shots = process.env.SHOTS || new URL('../../build/', import.meta.url).pathname;
const W = 932, H = 430;
const browser = await chromium.launch({
	proxy: !url.includes('localhost') && process.env.HTTPS_PROXY ? { server: process.env.HTTPS_PROXY } : undefined,
	args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--autoplay-policy=no-user-gesture-required'],
});
const ctx = await browser.newContext({ ignoreHTTPSErrors: true, viewport: { width: W, height: H }, deviceScaleFactor: 1, isMobile: true, hasTouch: true });
await ctx.addInitScript(() => {
	window.__taps = [];
	const orig = AudioNode.prototype.connect;
	AudioNode.prototype.connect = function (dest, ...rest) {
		const r = orig.call(this, dest, ...rest);
		if (dest instanceof AudioDestinationNode) {
			const c = dest.context;
			if (!c.__an) { c.__an = c.createAnalyser(); c.__an.fftSize = 2048; window.__taps.push(c.__an); }
			orig.call(this, c.__an);
		}
		return r;
	};
	window.__peak = () => {
		let m = 0;
		for (const an of window.__taps) {
			const b = new Float32Array(an.fftSize);
			an.getFloatTimeDomainData(b);
			for (const v of b) m = Math.max(m, Math.abs(v));
		}
		return m;
	};
});
const page = await ctx.newPage();
const errors = [];
page.on('pageerror', (e) => errors.push(e.message));
page.on('console', (m) => { if (m.type() === 'error') errors.push('console: ' + m.text()); });
const cdp = await ctx.newCDPSession(page);
const touch = (type, pts) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: pts });
const tap = async (x, y, id) => { await touch('touchStart', [{ x, y, id }]); await page.waitForTimeout(90); await touch('touchEnd', []); };
let failed = 0;
const check = (ok, msg) => { console.log(`  ${ok ? 'ok  ' : 'FAIL'}  ${msg}`); if (!ok) failed++; };

await page.goto(url);
await page.waitForFunction(() => !document.getElementById('status'), null, { timeout: 90000 });
await page.waitForTimeout(3000);
const box = await page.locator('canvas').boundingBox();
check(box && box.x === 0 && box.y === 0 && box.width === W && box.height === H, `canvas fills the window (${JSON.stringify(box)})`);
await page.screenshot({ path: shots + 'webtest-title.png' });
// PLAY sits 54 px above the bottom of the (about 215 px tall) virtual view: ~79% down
await tap(W * 0.5, H * 0.79, 1234567);
await page.waitForTimeout(400);
await page.keyboard.press("Enter");
let peak = 0;
for (let i = 0; i < 30; i++) {
	await page.waitForTimeout(100);
	peak = Math.max(peak, await page.evaluate(() => window.__peak()));
}
check(peak > 0.005, `sound comes out (peak ${peak.toFixed(3)})`);
// drag the joystick: hold on the left and move right/up for 4 s
const before = await page.screenshot();
await touch('touchStart', [{ x: W * 0.25, y: H * 0.7, id: 77 }]);
for (let i = 0; i < 40; i++) {
	await touch('touchMove', [{ x: W * 0.25 + Math.min(60, i * 4), y: H * 0.7 - Math.min(30, i * 2), id: 77 }]);
	await page.waitForTimeout(100);
}
await touch('touchEnd', []);
await page.waitForTimeout(500);
const after = await page.screenshot({ path: shots + 'webtest-run.png' });
check(Buffer.compare(before, after) !== 0, 'the joystick moves the world');
const state = await page.evaluate(() => (window.duckAudioState ? window.duckAudioState() : 'none'));
console.log('  audio: ' + state + '   build: ' + (await page.evaluate(() => window.duckBuild)));
check(errors.length === 0, `no page errors ${errors.length ? JSON.stringify(errors.slice(0, 3)) : ''}`);
await browser.close();
console.log(failed ? `WEBTEST: ${failed} FAILED` : 'WEBTEST: PASS');
process.exit(failed ? 1 : 0);
