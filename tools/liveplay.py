"""Plays the tactical prototype live in headless Chrome with real mouse/keyboard input (reads window.rwT for state)."""
import sys, asyncio, json
from playwright.async_api import async_playwright
URL = sys.argv[1]; OUT = sys.argv[2]
async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path="/usr/bin/google-chrome", args=["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"])
        pg = await b.new_page(viewport={"width": 1280, "height": 720})
        errs = []
        pg.on("console", lambda m: errs.append(m.text) if m.type == "error" else None)
        await pg.goto(URL); await pg.wait_for_timeout(9000)
        box = await pg.locator("canvas").bounding_box()
        sc = min(box["width"] / 640, box["height"] / 360); ox = box["x"] + (box["width"] - 640 * sc) / 2; oy = box["y"] + (box["height"] - 360 * sc) / 2
        async def click(x, y): await pg.mouse.click(ox + x * sc, oy + y * sc); await pg.wait_for_timeout(250)
        async def st():
            s = await pg.evaluate("JSON.stringify(window.rwT || null)"); return json.loads(s) if s else None
        async def cell_click(s, c): await click(s["org"][0] + c[0] * s["ts"] + 12, s["org"][1] + c[1] * s["ts"] + 12)
        async def button(s, prefix):
            for bt in s["buttons"]:
                if bt["text"].startswith(prefix) and not bt.get("disabled"): await click(bt["x"], bt["y"]); return True
            return False
        used_keys = False; shots = 0; turns = 0
        for step in range(900):
            await pg.wait_for_timeout(300)
            s = await st()
            if not s: continue
            if s.get("over"):
                print("RESULT:", s.get("result"), "msg:", s.get("msg"))
                await pg.screenshot(path=OUT + "-result.png")
                await button(s, "Continue"); await pg.wait_for_timeout(1500)
                await pg.screenshot(path=OUT + "-after.png"); break
            if s["mode"] not in ("menu", "move", "target"): continue
            act = next((u for u in s["units"] if u["active"]), None)
            if not act or act["side"] != "p": continue
            foes = [u for u in s["units"] if u["side"] == "e" and u["hp"] > 0]
            allies = [u for u in s["units"] if u["side"] == "p" and u["hp"] > 0]
            occupied = {(u["x"], u["y"]) for u in s["units"] if u["hp"] > 0}
            d = lambda a, b: abs(a[0] - b[0]) + abs(a[1] - b[1])
            if s["mode"] == "menu":
                if shots == 0: await pg.screenshot(path=OUT + "-menu.png"); shots = 1
                hurt = [u for u in allies if u["hp"] < u["maxhp"] * 0.55]
                if "Move and act" in s["msg"] and act["cls"] == "Cleric" and hurt and act["mp"] >= 5:
                    await button(s, "Skills"); await pg.wait_for_timeout(300); s = await st(); await button(s, "Mend")
                elif "Move and act" in s["msg"] or ("Move or end" in s["msg"] and False):
                    turns += 1
                    if not used_keys:
                        await pg.keyboard.press("Enter")       # focused "Move" button
                    else:
                        await button(s, "Move")
                elif "Act or end" in s["msg"]:
                    if act["cls"] == "Cleric" and hurt and act["mp"] >= 5:
                        await button(s, "Skills"); await pg.wait_for_timeout(300); s = await st(); await button(s, "Mend")
                    else: await button(s, "Attack")
                    await pg.wait_for_timeout(1200); s = await st()
                    if s and s["mode"] == "menu" and "Attack" not in s["msg"]: await button(s, "End turn")
                else:
                    await button(s, "End turn")
            elif s["mode"] == "move":
                cells = [tuple(c) for c in s["cells"]]
                me = (act["x"], act["y"])
                def score(c):
                    if not foes: return 0
                    nd = min(d(c, (f["x"], f["y"])) for f in foes)
                    return abs(nd - act["range"]) if act["range"] > 1 else nd
                if act["cls"] == "Cleric" and allies:   # healer stays behind the front
                    score = lambda c: abs(min(d(c, (f["x"], f["y"])) for f in foes) - 3) if foes else 0
                best = min(cells, key=score) if cells else me
                if best == me or score(best) >= score(me):
                    await pg.keyboard.press("Escape"); await pg.wait_for_timeout(400); s = await st()
                    if s and s["mode"] == "menu": await button(s, "Attack")
                    continue
                if not used_keys:
                    used_keys = True
                    dx, dy = best[0] - me[0], best[1] - me[1]
                    for _ in range(abs(dx)): await pg.keyboard.press("ArrowRight" if dx > 0 else "ArrowLeft"); await pg.wait_for_timeout(60)
                    for _ in range(abs(dy)): await pg.keyboard.press("ArrowDown" if dy > 0 else "ArrowUp"); await pg.wait_for_timeout(60)
                    await pg.wait_for_timeout(300); await pg.screenshot(path=OUT + "-move.png")
                    await pg.keyboard.press("Enter")
                else:
                    await cell_click(s, best)
                await pg.wait_for_timeout(900)
            elif s["mode"] == "target":
                cells = [tuple(c) for c in s["cells"]]
                if act["cls"] == "Cleric" and "Mend" in s["msg"]:
                    tg = min([u for u in allies if (u["x"], u["y"]) in cells], key=lambda u: u["hp"] / u["maxhp"], default=None)
                else:
                    tg = min([f for f in foes if (f["x"], f["y"]) in cells], key=lambda f: f["hp"], default=None)
                if tg: await cell_click(s, (tg["x"], tg["y"]))
                else: await pg.keyboard.press("Escape")
                await pg.wait_for_timeout(900)
        print("steps", step, "turns", turns, "errors:", errs[:5])
        await b.close()
asyncio.run(main())
