"""Rosewood hand-authored map kit. Each map is drawn on a char canvas and written to maps/<id>.txt (JSON)."""
import json, random, os
SOLID = set("TPR#WCblkoqwxYVAZLGHKUI")
TYPE = {"inn": (7, 5), "store": (6, 4), "chapel": (5, 6), "hall": (7, 5), "smithy": (5, 4), "home": (5, 4), "mill": (5, 5)}
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "maps")
WALKISH = ",=^e+_mDi"

class M:
    def __init__(s, mid, w, h, fill="."):
        s.id, s.w, s.h = mid, w, h
        s.g = [[fill] * w for _ in range(h)]
        s.hub = (w // 2, h // 2)
        s.bld, s.signs, s.npcs, s.chests, s.camps, s.notes = {}, [], [], [], [], []
        s.boss = None
        s.rng = random.Random(mid)
        s.prot = set()
    def ok(s, x, y): return 0 <= x < s.w and 0 <= y < s.h
    def get(s, x, y): return s.g[y][x] if s.ok(x, y) else "#"
    def set(s, x, y, c):
        if s.ok(x, y): s.g[y][x] = c
    def rect(s, x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w): s.set(xx, yy, c)
    def frame(s, x, y, w, h, c):
        for xx in range(x, x + w): s.set(xx, y, c); s.set(xx, y + h - 1, c)
        for yy in range(y, y + h): s.set(x, yy, c); s.set(x + w - 1, yy, c)
    def disc(s, cx, cy, rx, ry=None, c="W", jag=0.0, only=None):
        ry = rx if ry is None else ry
        for y in range(int(cy - ry - 1), int(cy + ry + 2)):
            for x in range(int(cx - rx - 1), int(cx + rx + 2)):
                d = ((x - cx) / max(rx, .5)) ** 2 + ((y - cy) / max(ry, .5)) ** 2
                if d <= 1 + (s.rng.uniform(-jag, jag) if jag else 0) and s.ok(x, y) and (only is None or s.g[y][x] in only): s.set(x, y, c)
    def border(s, c, t=2, noise=0.45, c2=None):
        for y in range(s.h):
            for x in range(s.w):
                d = min(x, y, s.w - 1 - x, s.h - 1 - y)
                if d < t or (d == t and s.rng.random() < noise): s.g[y][x] = c if not c2 or s.rng.random() < .7 else c2
    def path(s, pts, wd=2, c=",", yfirst=False):
        """Axis-routed path through pts (x first, then y). Water->bridge, cliff->stairs."""
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            cells = []
            if yfirst:
                sy = 1 if by >= ay else -1
                cells += [(ax, y) for y in range(ay, by + sy, sy)]
                sx = 1 if bx >= ax else -1
                cells += [(x, by) for x in range(ax, bx + sx, sx)]
            else:
                sx = 1 if bx >= ax else -1
                cells += [(x, ay) for x in range(ax, bx + sx, sx)]
                sy = 1 if by >= ay else -1
                cells += [(bx, y) for y in range(ay, by + sy, sy)]
            for (x, y) in cells:
                for i in range(wd):
                    for j in range(wd): s.paint(x + i, y + j, c)
    def paint(s, x, y, c):
        if not s.ok(x, y): return
        o = s.g[y][x]
        if o == "e": return
        if c == ",":
            if o == "W": c = "="
            elif o == "C": c = "^"
            elif o in "=^Dm+_i": c = o
        s.g[y][x] = c; s.prot.add((x, y))
    def exit(s, side, at, depth=4, c=","):
        if side == "W": cells = [(0, at), (0, at + 1)]; inw = (1, 0)
        if side == "E": cells = [(s.w - 1, at), (s.w - 1, at + 1)]; inw = (-1, 0)
        if side == "N": cells = [(at, 0), (at + 1, 0)]; inw = (0, 1)
        if side == "S": cells = [(at, s.h - 1), (at + 1, s.h - 1)]; inw = (0, -1)
        for (x, y) in cells:
            s.g[y][x] = "e"; s.prot.add((x, y))
            for k in range(1, depth + 1): s.paint(x + inw[0] * k, y + inw[1] * k, c)
        x, y = cells[0]
        return (x + inw[0] * depth, y + inw[1] * depth)
    def building(s, bid, typ, x, y, door_len=2):
        w, h = TYPE[typ]
        s.rect(x - 1, y - 1, w + 2, h + 1, ".")
        for yy in range(y - 1, y + h + 1):
            for xx in range(x - 1, x + w + 1): s.prot.add((xx, yy))
        s.bld[bid] = [x, y, w, h]
        dx = x + w // 2
        for k in range(0, door_len + 1): s.paint(dx, y + h + k, ",")
        return (dx, y + h)
    def scatter(s, c, dens, on=".", margin=1, area=None):
        x0, y0, x1, y1 = area or (0, 0, s.w, s.h)
        for y in range(max(0, y0), min(s.h, y1)):
            for x in range(max(0, x0), min(s.w, x1)):
                if s.g[y][x] not in on or (x, y) in s.prot: continue
                if margin and any(s.get(x + i, y + j) in WALKISH for i in range(-margin, margin + 1) for j in range(-margin, margin + 1)): continue
                if s.rng.random() < dens: s.g[y][x] = c
    def put(s, kind, x, y, *a):
        if s.g[y][x] in SOLID or s.g[y][x] in "e": s.set(x, y, ".")
        s.prot.add((x, y))
        if kind == "sign": s.signs.append([x, y, a[0]])
        elif kind == "npc": s.npcs.append([x, y] + list(a))
        elif kind == "chest": s.chests.append([x, y, a[0]])
        elif kind == "camp": s.camps.append([x, y])
        elif kind == "boss": s.boss = [x, y]
    def walk(s, gates_open):
        sol = set(SOLID)
        if gates_open: sol.discard("G")
        block = set()
        for (x, y, w, h) in s.bld.values():
            for yy in range(y, y + h):
                for xx in range(x, x + w): block.add((xx, yy))
        for lst in (s.signs, s.npcs, s.chests, s.camps): block |= {(o[0], o[1]) for o in lst}
        if s.boss: block.add(tuple(s.boss))
        seen = {s.hub}; q = [s.hub]
        while q:
            x, y = q.pop()
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (x + dx, y + dy)
                if n in seen or not s.ok(*n) or n in block or s.g[n[1]][n[0]] in sol: continue
                seen.add(n); q.append(n)
        return seen
    def adj(s, seen, x, y): return any((x + dx, y + dy) in seen for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    def validate(s, links):
        bad = []
        if s.get(*s.hub) in SOLID: bad.append("hub solid")
        closed = s.walk(False); opn = s.walk(True)
        sides = set()
        for y in range(s.h):
            for x in range(s.w):
                ch = s.g[y][x]
                if ch == "e":
                    side = "W" if x == 0 else "E" if x == s.w - 1 else "N" if y == 0 else "S"
                    sides.add(side)
                    if (x, y) not in closed: bad.append("exit%s@%d,%d" % (side, x, y))
                if ch == "L" and not s.adj(closed, x, y): bad.append("lever@%d,%d" % (x, y))
        if sides != set(links): bad.append("sides %s vs %s" % (sorted(sides), sorted(links)))
        for lst, n in ((s.signs, "sign"), (s.npcs, "npc"), (s.chests, "chest"), (s.camps, "camp")):
            for o in lst:
                if not s.adj(opn, o[0], o[1]): bad.append("%s@%d,%d" % (n, o[0], o[1]))
        if s.boss and not s.adj(opn, *s.boss): bad.append("boss")
        for bid, (x, y, w, h) in s.bld.items():
            if not s.adj(opn, x + w // 2, y + h - 1): bad.append("door " + bid)
        return bad
    def save(s, links):
        bad = s.validate(links)
        j = {"rows": ["".join(r) for r in s.g], "hub": list(s.hub), "buildings": s.bld, "signs": s.signs, "npcs": s.npcs,
             "chests": s.chests, "camps": s.camps, "notes": s.notes}
        if s.boss: j["boss"] = s.boss
        os.makedirs(OUT, exist_ok=True)
        with open(os.path.join(OUT, s.id + ".txt"), "w") as f: json.dump(j, f)
        print("%-22s %dx%d %s" % (s.id, s.w, s.h, "OK" if not bad else "BAD " + " ".join(bad)))
        return bad
