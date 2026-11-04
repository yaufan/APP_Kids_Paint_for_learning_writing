// node render.js in.html out.png width height: one HTML page to a PNG (Playwright's Chromium).
const { chromium } = require('playwright');
(async () => {
  const [inp, out, w, h] = process.argv.slice(2);
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: +w, height: +h }, deviceScaleFactor: 2 });
  await page.goto('file://' + inp);
  await page.waitForTimeout(300);
  await page.screenshot({ path: out });
  await browser.close();
})();
