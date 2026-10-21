import sys, os, math; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mapkit import M
from world import place, links

def drowned_shallows():
    m = M("drowned_shallows", 56, 34, "W")
    m.rect(0, 0, 56, 6, "."); m.border("T", 1, .5)
    for x in range(56): m.rect(x, 6, 1, 2 + (x // 5) % 2, "S")
    # tidal flats: sandbars that weave between drowned rooftops
    for (cx, cy, rx, ry) in [(20, 13, 6, 3), (12, 22, 6, 3), (30, 24, 7, 3), (42, 18, 6, 4), (46, 28, 4, 2)]:
        m.disc(cx, cy, rx, ry, "S", jag=.3)
    n = m.exit("N", 20, depth=3); e = m.exit("E", 18, depth=3, c="S")
    m.path([n, (20, 12), (12, 12), (12, 22)], c="S"); m.path([(12, 23), (30, 23), (30, 19), (42, 19)], c="S"); m.path([(42, 19), e], c="S")
    m.path([(43, 21), (43, 27), (46, 27)], wd=1, c="S")
    # drowned rooftops and chimneys under the water
    for (x, y, w) in [(26, 10, 4), (36, 9, 3), (5, 15, 3), (20, 29, 4), (36, 29, 3), (50, 10, 3)]:
        m.rect(x, y, w, 2, "U"); m.set(x + 1, y - 1, "I")
        m.notes.append([x, y, "A rooftop under the tide. A weathervane still turns in the current."])
    m.scatter("p", .1, on="S", margin=0)
    m.hub = (20, 12)
    place(m, "drowned_shallows", [(22, 9), (13, 25), (17, 13), (47, 27), (31, 22)])
    return m.save(links("drowned_shallows"))

def oryth_ruins():
    m = M("oryth_ruins", 52, 32, "W")
    w = m.exit("W", 15, depth=2, c="+"); e = m.exit("E", 15, depth=2, c="+")
    pts = [(1, 15), (12, 15), (12, 10), (26, 10), (26, 18), (40, 18), (40, 15), (51, 15)]
    m.path(pts, wd=3, c="+")
    # statues line the causeway; some have toppled into the sea
    for (a, b) in zip(pts, pts[1:]):
        if a[1] == b[1]:
            for x in range(min(a[0], b[0]) + 2, max(a[0], b[0]) - 1, 4):
                for y in (a[1] - 1, a[1] + 3):
                    if m.get(x, y) == "W": m.set(x, y, "A")
    m.notes.append([17, 9, "A drowned statue, her hands open as if offering something."])
    for (x, y) in [(31, 19), (32, 19), (32, 20)]: m.set(x, y, "=")
    m.rect(17, 3, 7, 5, "+"); m.path([(19, 8), (19, 10)], wd=1, c="+")           # shrine platform
    m.rect(32, 24, 7, 5, "+"); m.path([(34, 21), (34, 24)], wd=1, c="+")          # watcher's platform
    m.set(17, 3, "I"); m.set(23, 3, "I"); m.set(32, 28, "I"); m.set(38, 28, "I")
    m.hub = (14, 12)
    place(m, "oryth_ruins", [(10, 14), (20, 4), (37, 26), (34, 27)])
    return m.save(links("oryth_ruins"))

def sunken_oryth():
    m = M("sunken_oryth", 48, 36, "Z")
    w = m.exit("W", 17, depth=4, c="+")
    m.rect(4, 13, 9, 10, "+")                                      # entry hall
    m.path([(12, 17), (34, 17)], wd=3, c="+")                      # the long gallery
    for x in range(14, 34, 4): m.set(x, 16, "I"); m.set(x, 20, "I")
    for x in (18, 19, 26, 27): m.rect(x, 17, 1, 3, "W")           # flooded sections
    m.path([(18, 18), (27, 18)], wd=1)                             # planks over the flood
    m.rect(14, 4, 12, 7, "+"); m.disc(19, 7, 3, 1.5, "W"); m.path([(20, 11), (20, 16)], wd=2, c="+")   # north wing: bath
    m.set(24, 5, "L"); m.notes.append([24, 5, "A sluice wheel, crusted with barnacles."]) if False else None
    m.rect(14, 24, 12, 8, "+"); m.disc(20, 28, 4, 2, "W"); m.path([(16, 20), (16, 24)], wd=2, c="+")  # south wing: drowned library
    for x in range(15, 25, 3): m.set(x, 24, "k")
    m.rect(36, 8, 9, 20, "+"); m.set(35, 17, "G"); m.set(35, 18, "G"); m.set(35, 19, "G")             # throne hall
    m.rect(37, 9, 7, 3, "W"); m.rect(37, 24, 7, 3, "W"); m.rect(39, 12, 3, 2, "+")
    m.put("boss", 40, 12); m.set(37, 13, "I"); m.set(43, 13, "I")
    m.hub = (8, 18)
    place(m, "sunken_oryth", [(10, 14), (15, 5), (40, 26)] if False else [(10, 14), (15, 5), (24, 30)])
    m.put("sign", 33, 16, "The throne gate is sealed by water-pressure. A sluice wheel in the north bath might drain it.")
    return m.save(links("sunken_oryth"))

def frostfang_pass():
    m = M("frostfang_pass", 50, 38)
    m.border("R", 3, .5, "P")
    # gorge walls: the pass narrows to a single-file gap between cliffs
    m.rect(3, 3, 14, 20, "C"); m.rect(24, 3, 23, 12, "C"); m.rect(30, 22, 17, 13, "C")
    m.rect(4, 4, 12, 18, "P"); m.rect(25, 4, 21, 10, "P"); m.rect(31, 23, 15, 11, "P")
    s = m.exit("S", 10, depth=3); e = m.exit("E", 18, depth=3)
    m.path([s, (10, 30), (20, 30), (20, 18), e])
    m.disc(22, 25, 3, 2, "i"); m.disc(36, 18, 4, 1.4, "i")      # wind-polished ice
    for (x, y) in [(18, 22), (23, 13), (27, 17)]: m.set(x, y, "R")
    m.scatter("P", .1); m.scatter("R", .06)
    m.hub = (20, 26)
    place(m, "frostfang_pass", [(12, 32), (22, 21), (27, 20), (8, 27), (17, 27)])
    return m.save(links("frostfang_pass"))

def pale_reach():
    m = M("pale_reach", 60, 38)
    m.border("P", 2, .5, "R")
    m.disc(30, 20, 20, 11, "S", jag=.08); m.disc(30, 20, 18, 9.5, "i", jag=.05)    # frozen lake with a snowy shore
    for (x, y) in [(22, 16), (38, 24), (27, 26), (40, 15)]: m.disc(x, y, 1.6, 1, "W")   # dark holes in the ice
    m.disc(30, 19, 3, 2, ".")                                    # island at the center
    w = m.exit("W", 20); e = m.exit("E", 20); n = m.exit("N", 30, depth=4)
    m.path([w, (60, 20)] if False else [w, (58, 20)], c="i"); m.path([(n[0], n[1]), (30, 18)], c="i")
    for (x, y) in [(5, 19), (5, 22), (54, 19), (54, 22)]: m.set(x, y, "l")
    m.rect(14, 4, 4, 3, "Z"); m.set(15, 6, "."); m.notes.append([14, 4, "An ice-fisher's hut, abandoned mid-meal."])
    m.scatter("P", .07); m.scatter("R", .04)
    m.hub = (12, 20)
    for y in range(m.h):
        for x in range(m.w):
            if m.g[y][x] == "," : m.g[y][x] = "i" if m.get(x, y) == "," and 12 <= x <= 48 else ","
    place(m, "pale_reach", [(9, 18), (16, 7), (31, 17), (32, 19)])
    return m.save(links("pale_reach"))

def frosthold():
    m = M("frosthold", 44, 32)
    m.border("P", 2, .5)
    m.frame(4, 3, 36, 26, "Z"); m.frame(5, 4, 34, 24, "Z")             # town wall
    s = m.exit("S", 21, depth=6)
    m.path([s, (21, 16)]); m.path([(10, 16), (34, 16)])
    m.building("inn", "inn", 8, 7, door_len=4)
    m.building("store", "store", 30, 9, door_len=2)
    m.building("hall", "hall", 18, 6, door_len=4)
    m.disc(21, 21, 2, 1, "+"); m.set(16, 21, "l"); m.set(26, 21, "l")
    for (x, y) in [(8, 22), (9, 22), (33, 22), (34, 23)]: m.set(x, y, "k")
    m.scatter("P", .04, area=(6, 5, 38, 27)); m.scatter("p", .05, area=(6, 5, 38, 27))
    m.hub = (22, 18)
    place(m, "frosthold", [(24, 19)])
    m.put("camp", 20, 21)
    return m.save(links("frosthold"))

def veil_wastes():
    m = M("veil_wastes", 54, 36)
    m.border("R", 2, .5, "U")
    # fissures: long dark cliffs crossing the waste, each with a single crossing
    for (y0, amp) in [(10, 2), (25, 2)]:
        for x in range(2, 52):
            y = y0 + round(amp * math.sin(x * .35)); m.set(x, y, "C"); m.set(x, y + 1, "C")
    w = m.exit("W", 17); e = m.exit("E", 17)
    m.path([w, (14, 17), (14, 6), (30, 6), (30, 17), (40, 17), (40, 29), (46, 29), (46, 17), e], wd=2)
    for (x, y) in [(20, 20), (26, 14), (36, 23), (8, 28), (24, 30)]: m.set(x, y, "I"); m.notes.append([x, y, "A pillar of solid fog. It hums your name."])
    m.scatter("U", .06); m.scatter("R", .05)
    m.hub = (14, 12)
    place(m, "veil_wastes", [(16, 15), (22, 7), (12, 4), (44, 30), (38, 15)])
    return m.save(links("veil_wastes"))

def veilspire():
    m = M("veilspire", 44, 40, "R")
    cx, cy = 22, 20
    m.rect(cx - 16, cy - 16, 33, 33, "+")
    for d in (16, 12, 8, 4): m.frame(cx - d, cy - d, 2 * d + 1, 2 * d + 1, "Z")
    w = m.exit("W", cy, depth=6, c="+")
    m.rect(cx - 16, cy, 1, 2, "+")                       # outer gate (west)
    m.rect(cx + 12, cy, 1, 2, "+")                       # ring 2 door (east)
    m.rect(cx - 8, cy, 1, 2, "+")                        # ring 3 door (west)
    m.rect(cx + 4, cy, 1, 2, "G")                        # heart gate (east), sealed
    for (a, b) in [(-14, -14), (14, -14), (-14, 14), (14, 14), (-10, -10), (10, 10), (-6, 6), (6, -6)]: m.set(cx + a, cy + b, "I")
    m.set(cx, cy - 6, "L"); m.notes.append([cx, cy - 7, "Bells, somewhere above. The spiral climbs on."]) if False else None
    m.put("boss", cx, cy); m.set(cx - 2, cy - 2, "A"); m.set(cx + 2, cy - 2, "A")
    m.hub = (cx - 14, cy)
    place(m, "veilspire", [(cx - 14, cy - 2), (cx + 14, cy + 14), (cx - 6, cy - 6)] if False else [(cx - 14, cy - 2), (cx + 14, cy - 13), (cx - 6, cy + 5)])
    return m.save(links("veilspire"))

if __name__ == "__main__":
    for f in [drowned_shallows, oryth_ruins, sunken_oryth, frostfang_pass, pale_reach, frosthold, veil_wastes, veilspire]: f()
