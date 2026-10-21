import sys, asyncio
from playwright.async_api import async_playwright
async def main(url, out):
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path="/usr/bin/google-chrome", args=["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"])
        pg = await b.new_page(viewport={"width": 1280, "height": 720})
        errs = []
        pg.on("console", lambda m: errs.append(m.text) if m.type == "error" else None)
        pg.on("pageerror", lambda e: errs.append(str(e)))
        await pg.goto(url); await pg.wait_for_timeout(9000)
        await pg.mouse.click(640, 360); await pg.wait_for_timeout(1500)
        await pg.screenshot(path=out); print("errors:", errs[:5])
        await b.close()
asyncio.run(main(sys.argv[1], sys.argv[2]))
